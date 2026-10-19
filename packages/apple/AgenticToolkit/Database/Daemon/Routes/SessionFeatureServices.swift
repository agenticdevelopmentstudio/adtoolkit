#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation

/// Everything the shared session-feature routes need from the daemon that mounts
/// them: the stores and services they call, the daemon's identity, and closures for
/// the few things only a daemon can do (read its own process footprint, capture a
/// hook delivery, start an import).
///
/// Every member is explicit. A value that differs per daemon (its name, its version,
/// the endpoint list it advertises) has no default here, so a daemon cannot mount
/// the routes by accident with another daemon's answer.
public struct SessionFeatureServices: Sendable {

    /// A reading of the process's memory, in whole megabytes.
    public struct MemorySample: Sendable, Equatable {
        public let footprintMB: Int
        public let peakMB: Int

        public init(footprintMB: Int, peakMB: Int) {
            self.footprintMB = footprintMB
            self.peakMB = peakMB
        }
    }

    // MARK: - Stores and services

    public let database: DaemonDatabase
    /// The Conversations feed and its parsed-line cache.
    public let conversations: ConversationStore
    /// Backs the ingestion-error routes.
    public let quarantine: QuarantineService
    /// Backs `GET /ingestion/spool`. Nil when this daemon ingests straight to the
    /// database; the route then answers 503 rather than reporting an empty spool.
    public let spool: IngestSpool?
    /// Owns the preference-write business logic (AI config, secrets, tracking,
    /// oversight, summaries).
    public let preferences: PreferencesService
    /// Where plugin secrets resolve for a summarize run.
    public let secretStore: any SecretStoring
    public let hookInstaller: ClaudeHookInstaller

    // MARK: - Identity

    /// The name the endpoint index reports.
    public let daemonName: String
    public let daemonVersion: String
    public let startTime: Date
    /// The lines of the endpoint index, each like `"GET /health"`, in the order
    /// the daemon advertises them. This daemon's own routes may be included.
    public let endpointIndex: [String]

    // MARK: - Daemon-only behaviour

    /// Milliseconds from process start to ready, or nil until startup completes.
    public let startupDurationMs: @Sendable () -> Int?
    /// The process's current memory reading, or nil when the kernel declines it.
    public let memorySample: @Sendable () -> MemorySample?
    /// Reads one quarantined event file back into an event, for the retry.
    public let parseQuarantinedEvent: @Sendable (String) -> ParseResult
    /// Ingests one event straight into the database, bypassing the spool: what a
    /// quarantine retry feeds.
    public let retryIngest: @Sendable (ParsedEvent) throws -> Void
    /// Turns a `POST /hook/:event` delivery into an event, or nil when it is
    /// well-formed but intentionally not ingested (headless, or untrackable).
    public let buildHookEvent: @Sendable (_ event: String, _ payload: Data) -> ParsedEvent?
    /// Captures a hook delivery. This must not depend on the main database being
    /// migrated, because the hook route stays up while it migrates.
    public let captureHook: @Sendable (ParsedEvent) throws -> Void
    /// Runs a JSONL backfill as asked over HTTP, against the daemon's own database.
    public let runImport: @Sendable (ImportRequestDTO) throws -> ImportSummary
    /// How the summarize route loads AI plugins. Defaults to `.live` (the default
    /// folders only); `SessionDaemonRuntime.services` passes the daemon's own.
    public let pluginRuntime: DaemonAIChat.PluginRuntime

    public init(
        database: DaemonDatabase,
        conversations: ConversationStore,
        quarantine: QuarantineService,
        spool: IngestSpool?,
        preferences: PreferencesService,
        secretStore: any SecretStoring,
        hookInstaller: ClaudeHookInstaller,
        daemonName: String,
        daemonVersion: String,
        startTime: Date,
        endpointIndex: [String],
        startupDurationMs: @escaping @Sendable () -> Int?,
        memorySample: @escaping @Sendable () -> MemorySample?,
        parseQuarantinedEvent: @escaping @Sendable (String) -> ParseResult,
        retryIngest: @escaping @Sendable (ParsedEvent) throws -> Void,
        buildHookEvent: @escaping @Sendable (_ event: String, _ payload: Data) -> ParsedEvent?,
        captureHook: @escaping @Sendable (ParsedEvent) throws -> Void,
        runImport: @escaping @Sendable (ImportRequestDTO) throws -> ImportSummary,
        pluginRuntime: DaemonAIChat.PluginRuntime = .live
    ) {
        self.database = database
        self.conversations = conversations
        self.quarantine = quarantine
        self.spool = spool
        self.preferences = preferences
        self.secretStore = secretStore
        self.hookInstaller = hookInstaller
        self.daemonName = daemonName
        self.daemonVersion = daemonVersion
        self.startTime = startTime
        self.endpointIndex = endpointIndex
        self.startupDurationMs = startupDurationMs
        self.memorySample = memorySample
        self.parseQuarantinedEvent = parseQuarantinedEvent
        self.retryIngest = retryIngest
        self.buildHookEvent = buildHookEvent
        self.captureHook = captureHook
        self.runImport = runImport
        self.pluginRuntime = pluginRuntime
    }
}
#endif
