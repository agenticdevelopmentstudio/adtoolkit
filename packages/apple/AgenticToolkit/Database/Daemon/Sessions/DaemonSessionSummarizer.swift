#if canImport(AgenticToolkitCore)
import Foundation
import AgenticToolkitCore
import AIPluginKit
import OSLog

/// Generates AI summaries for sessions inside the daemon, so a running history of
/// what sessions are doing accrues even when the app isn't running.
///
/// Transport — the plugin/`PluginTransport` path and the zero-config `claude -p`
/// fallback — is delegated to `DaemonAIChat`. This type owns what is *specific* to
/// summaries: the title system prompt, shaping a session's events into a prompt,
/// cleaning the reply into a short title, and storing it on the session.
public struct DaemonSessionSummarizer: Sendable {

    /// Whether autonomous summaries are on when no `ai_summaries_enabled` row exists.
    /// Each daemon states its own default: one that always summarizes passes `true`,
    /// one that must not double LLM spend passes `false`.
    public let defaultEnabled: Bool
    /// How this daemon loads AI plugins: `.live`, plus any folders its configuration
    /// names (`SessionDaemonConfiguration.pluginSearchPaths`). Callers of the static
    /// entry points pass it as `runtime:`.
    public let pluginRuntime: PluginRuntime

    public init(defaultEnabled: Bool, pluginRuntime: PluginRuntime = .live) {
        self.defaultEnabled = defaultEnabled
        self.pluginRuntime = pluginRuntime
    }

    /// Transport seams, re-exported from `DaemonAIChat` so call sites and tests that
    /// name them through the summarizer keep working after the extraction.
    public typealias PluginRuntime = DaemonAIChat.PluginRuntime
    public typealias CLIRunner = DaemonAIChat.CLIRunner
    public static let liveCLIRunner = DaemonAIChat.liveCLIRunner

    /// The title instructions, read live from the settings table with `{maxWords}`
    /// resolved — the user edits them in Settings → AI Summaries.
    public static func systemPrompt(_ database: DaemonDatabase) -> String {
        SummaryPrefs.resolvedPrompt(database)
    }

    public enum SummarizeError: Error, LocalizedError {
        case sessionNotFound(String)
        case noEvents
        case claudeNotFound
        case providerError(String)
        case emptyReply
        case unusableReply

        public var errorDescription: String? {
            switch self {
            case .sessionNotFound(let id): return "Session not found: \(id)"
            case .noEvents: return "No events for this session"
            case .claudeNotFound: return "Claude CLI not found (install Claude Code or check PATH)"
            case .providerError(let msg): return msg
            case .emptyReply: return "Empty reply from the model"
            case .unusableReply: return "The model replied with no title text"
            }
        }

        /// Maps the generic transport error onto the summarizer's error surface so
        /// existing callers/tests keep matching on `SummarizeError`.
        init(_ chatError: DaemonAIChat.ChatError) {
            switch chatError {
            case .claudeNotFound: self = .claudeNotFound
            case .providerError(let msg): self = .providerError(msg)
            case .emptyReply: self = .emptyReply
            }
        }
    }

    /// Whether autonomous AI summaries are on. With no stored `ai_summaries_enabled`
    /// row the answer is `defaultEnabled`; a stored value always wins.
    public func isEnabled(_ database: DaemonDatabase) -> Bool {
        RawSetting.bool((try? database.setting(for: "ai_summaries_enabled")) ?? nil, default: defaultEnabled)
    }

    /// Directories scanned for `.aiplugin` bundles, re-exported from `DaemonAIChat`.
    public static func pluginSearchPaths() -> [URL] { DaemonAIChat.pluginSearchPaths() }

    // MARK: - Entry points

    /// Summarizes one session and stores the result. Returns the summary text.
    @discardableResult
    public static func summarizeAndStore(
        sessionId: String,
        database: DaemonDatabase,
        settings: SummaryPrefs.Snapshot? = nil,
        runtime: PluginRuntime = .live,
        cliRunner: CLIRunner = liveCLIRunner,
        secretStore: any SecretStoring = KeychainSecretStore()
    ) async throws -> String {
        let summary = try await summarize(
            sessionId: sessionId, database: database, settings: settings,
            runtime: runtime, cliRunner: cliRunner, secretStore: secretStore
        )
        // An empty title must never be *stored*: `summary = ''` is the sentinel for
        // "never summarized", so writing it would blank a session the model already
        // titled and re-queue it on every pass forever. `summarize` throws instead.
        database.updateSessionSummary(summary, sessionId: sessionId)
        // Session id stays public (useful for tracing); the summary can reflect the
        // user's project/work, so keep its content private in the unified log.
        logger.info("Stored AI summary for \(sessionId, privacy: .public): \(summary.prefix(80), privacy: .private)")
        return summary
    }

    /// - Parameter settings: the pass's knobs, read once by the caller. `nil` reads a
    ///   fresh snapshot — right for a one-off (a "summarize now" request),
    ///   wrong inside a loop, where every session must see the same numbers.
    public static func summarize(
        sessionId: String,
        database: DaemonDatabase,
        settings: SummaryPrefs.Snapshot? = nil,
        runtime: PluginRuntime = .live,
        cliRunner: CLIRunner = liveCLIRunner,
        secretStore: any SecretStoring = KeychainSecretStore()
    ) async throws -> String {
        guard let session = try database.fetchSession(sessionId: sessionId, includeEventCount: false) else {
            throw SummarizeError.sessionNotFound(sessionId)
        }
        let events = try database.fetchRecentEvents(sessionId: sessionId, limit: 500)
        guard !events.isEmpty else { throw SummarizeError.noEvents }

        let settings = settings ?? SummaryPrefs.snapshot(database)
        let prompt = buildPrompt(
            session: session, events: events,
            maxEvents: settings.activityLines, detailChars: settings.detailChars
        )
        do {
            let reply = try await DaemonAIChat.complete(
                feature: .summarize, sessionId: sessionId,
                systemPrompt: settings.systemPrompt, userPrompt: prompt,
                maxTokens: settings.maxTokens,
                cliModel: "haiku", timeout: settings.timeout, database: database,
                runtime: runtime, cliRunner: cliRunner, secretStore: secretStore
            )
            let summary = cleanSummary(reply, maxWords: settings.maxWords)
            // A reply made entirely of decoration ("---", "###", "• • •") cleans down
            // to nothing. That is a failed summarization, not a title.
            guard !summary.isEmpty else { throw SummarizeError.unusableReply }
            return summary
        } catch let error as DaemonAIChat.ChatError {
            throw SummarizeError(error)
        }
    }

    /// A session title is a short phrase. `claude -p` occasionally ignores the brevity
    /// instruction and returns a paragraph (or echoes the conversation), so hard-cap it
    /// to the first line and the configured word count — a row title, never an essay.
    /// The cap is enforced here as well as asked for in the prompt, because small local
    /// models routinely overrun it.
    public static func cleanSummary(_ raw: String, maxWords: Int = SummaryDefaults.maxWords) -> String {
        let firstLine = raw
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first.map(String.init) ?? raw
        let trimmed = firstLine
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\"*#-•").union(.whitespacesAndNewlines))
        let words = trimmed.split(separator: " ")
        let capped = words.count > maxWords ? words.prefix(maxWords).joined(separator: " ") : trimmed
        // Belt-and-braces character cap for a reply that is one enormous "word" (a
        // pasted path, a wall of punctuation). Shared with `clearOverlongSummaries`,
        // whose threshold must not sit below what this produces.
        return String(capped.prefix(SummaryDefaults.characterCap(maxWords: maxWords)))
    }

    // MARK: - Prompt

    public static func buildPrompt(
        session: SessionDTO,
        events: [SessionEventDTO],
        maxEvents: Int = SummaryDefaults.activityLines,
        detailChars: Int = SummaryDefaults.detailChars
    ) -> String {
        var lines: [String] = []
        let project = URL(fileURLWithPath: session.cwd).lastPathComponent
        lines.append("Project: \(project.isEmpty ? session.cwd : project)")
        if !session.gitBranch.isEmpty { lines.append("Branch: \(session.gitBranch)") }
        lines.append("")
        lines.append("Activity (most recent last):")
        // `events` arrive newest-first (fetchRecentEvents ORDER BY id DESC); take the
        // newest `maxEvents` and reverse so the prompt reads oldest -> newest.
        for event in events.prefix(maxEvents).reversed() {
            let detail = event.detail.isEmpty ? "" : " — \(event.detail.prefix(detailChars))"
            lines.append("- [\(event.eventType)]\(detail)")
        }
        return lines.joined(separator: "\n")
    }
}

extension DaemonSessionSummarizer: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
