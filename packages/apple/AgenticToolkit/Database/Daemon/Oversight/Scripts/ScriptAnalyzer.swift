#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation

/// The LLM judgment layer over a script's deterministic trigger. The predicate only
/// knows the numbers matched; the model decides whether *now* is a clean moment and
/// gives a one-line reason. Parameterized by the script's `LLMConfirmation` (system
/// prompt + affirmative keyword), so every script drives the same parser and the
/// same provider path (`DaemonAIChat` via the oversight reader).
public struct ScriptAnalyzer: Sendable {

    /// The model's call on one candidate session.
    public enum Verdict: Sendable, Equatable {
        /// Act now, with the model's one-line reason.
        case act(reason: String)
        /// Not a good moment — no finding this tick.
        case wait(reason: String)
        /// Model errored/unreachable or answered unparseably — the caller falls back
        /// to the deterministic rule so the watcher never goes dark.
        case unavailable
    }

    /// Injectable one-shot chat seam so tests supply a canned reply instead of hitting
    /// a real model. `sessionId` scopes the `ai_interactions` log row. Returns the raw
    /// reply text.
    public typealias Chat = @Sendable (
        _ systemPrompt: String, _ userPrompt: String, _ sessionId: String, _ database: DaemonDatabase
    ) async throws -> String

    public var chat: Chat

    /// The host supplies the model path: the analyzer owns the prompt and the parser,
    /// not the transport.
    public init(chat: @escaping Chat) {
        self.chat = chat
    }

    /// No model wired. Every ask fails, so a confirmed trigger degrades to its
    /// deterministic rule — the watcher never goes dark.
    public static let unavailable = ScriptAnalyzer(chat: { _, _, _, _ in
        throw ModelNotWired()
    })

    private struct ModelNotWired: Error {}

    public static let maxRecentEvents = 20
    public static let maxEventDetailChars = 100

    /// Ask the model about one candidate. A transport failure or an unparseable reply
    /// becomes `.unavailable`, which the observer treats as "use the rule", so a
    /// slow/broken model degrades gracefully rather than erroring the tick. The one
    /// exception is a guard refusal: `AIGuardError` rethrows (typed) so the observer
    /// can stop consulting the model for the rest of the tick — every remaining
    /// candidate would hit the same wall, and each futile attempt writes another
    /// refusal row to the insert-pruned `ai_interactions` log.
    public func verdict(
        for session: LiveSessionSnapshot,
        confirmation: LLMConfirmation,
        database: DaemonDatabase
    ) async throws(AIGuardError) -> Verdict {
        let prompt = Self.buildPrompt(session: session, database: database)
        let raw: String
        do {
            raw = try await chat(confirmation.systemPrompt, prompt, session.sessionId, database)
        } catch let error as AIGuardError {
            throw error
        } catch {
            return .unavailable
        }
        return Self.parse(raw, actKeyword: confirmation.actKeyword)
    }

    /// Parse the model's verdict line. Robust to leading whitespace/quotes and a missing
    /// reason; an answer that is neither the act keyword nor WAIT is `.unavailable`
    /// (don't guess).
    private static let verdictTrimSet = CharacterSet(charactersIn: " \t\"*-•").union(.whitespacesAndNewlines)

    public static func parse(_ raw: String, actKeyword: String) -> Verdict {
        let firstLine = raw.split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init) ?? raw
        let line = firstLine.trimmingCharacters(in: verdictTrimSet)
        let upper = line.uppercased()
        let reason: String = {
            guard let colon = line.firstIndex(of: ":") else { return "" }
            return String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }()
        // WAIT is the reserved negative, checked first; an empty keyword must never
        // match. `hasPrefix("")` is always true, so a blank actKeyword would otherwise
        // turn every reply — including an explicit WAIT — into an act, silently
        // inverting the safety confirmation. (save-time validation also rejects it.)
        if upper.hasPrefix("WAIT") {
            return .wait(reason: reason.isEmpty ? "not a good moment yet" : reason)
        }
        let keyword = actKeyword.uppercased()
        if !keyword.isEmpty, upper.hasPrefix(keyword) {
            return .act(reason: reason.isEmpty ? "the model judged now a good moment" : reason)
        }
        return .unavailable
    }

    /// The prompt the model reasons over: how full the context is, the project/branch,
    /// and recent activity (so it can tell mid-task from a clean pause). Only data the
    /// daemon already holds — no extra capture.
    public static func buildPrompt(session: LiveSessionSnapshot, database: DaemonDatabase) -> String {
        var lines: [String] = []
        let project = URL(fileURLWithPath: session.cwd).lastPathComponent
        lines.append("Context window: \(session.contextUsedPct)% used")
        lines.append("Project: \(project.isEmpty ? session.cwd : project)")
        if !session.gitBranch.isEmpty { lines.append("Branch: \(session.gitBranch)") }
        let events = (try? database.fetchRecentEvents(sessionId: session.sessionId, limit: maxRecentEvents)) ?? []
        if !events.isEmpty {
            lines.append("")
            lines.append("Recent activity (most recent last):")
            // fetchRecentEvents returns newest-first; reverse so the prompt reads oldest -> newest.
            for event in events.reversed() {
                let detail = event.detail.isEmpty ? "" : " — \(event.detail.prefix(maxEventDetailChars))"
                lines.append("- [\(event.eventType)]\(detail)")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// A short label for the model that produced a verdict, for the finding's `model`
    /// field. Cheap (no descriptor load): the configured model, else the plugin id,
    /// else the zero-config CLI. Resolves through the **oversight** reader so the
    /// label names the provider oversight actually uses.
    public static func modelLabel(_ database: DaemonDatabase) -> String {
        let settings = database.oversightAIProviderSettings
        guard let config = DaemonProviderResolver.selectedConfiguration(settings) else { return "claude-cli" }
        let model = DaemonProviderResolver.model(config: config.id, settings)
        return model.isEmpty ? config.pluginIdentifier : model
    }
}
#endif
