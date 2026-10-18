#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import AIPluginKit
import Foundation
import OSLog

/// The objects a session daemon needs before it can capture and serve events,
/// and the steps that bring them up and down, written once.
///
/// The runtime owns the spool, the database, the ingestion pipeline and the hook
/// installer. It does **not** sequence them: the daemon's controller calls the
/// steps in the order its own transport needs. That order is the one every
/// session daemon shares:
///
/// 1. ``openPhaseA()`` — spool and database opened in parallel, the schema
///    *not* migrated yet, the support directory created and the user's
///    tracking choice read.
/// 2. Start the listener, then ``startIngress()`` — the capture socket and the
///    hook registration. Capture is live from here, into the spool.
/// 3. ``migrate()`` — one attempt at the schema. A controller that wants to
///    survive a failing migration wraps it in its own retry (the retry belongs
///    to the process-lifecycle library, which this module does not import).
/// 4. ``startDrainer()`` — empties the spool into the migrated database.
/// 5. ``shutdown()`` — stops the pipeline; safe to call more than once.
///
/// Splitting the migration from the open is the point: the listener and the
/// spool can be up while a long migration runs, so a migration turns capture
/// from lossy into merely late.
public final class SessionDaemonRuntime: @unchecked Sendable {

    /// What a daemon supplies for turning raw deliveries into stored events.
    public struct Behavior: Sendable {
        /// Where live events are announced (SSE, XPC subscribers).
        public var sink: any SessionEventSink
        /// Decodes one hook-socket payload.
        public var decode: @Sendable (Data) throws -> ParsedEvent
        /// Called with the session id after `Stop` / `SessionEnd`.
        public var summarizeOnStop: (@Sendable (String) async -> Void)?
        /// Appended to the ingestor's backfill log lines.
        public var footprintSuffix: @Sendable () -> String

        public init(
            sink: any SessionEventSink,
            decode: @escaping @Sendable (Data) throws -> ParsedEvent,
            summarizeOnStop: (@Sendable (String) async -> Void)? = nil,
            footprintSuffix: @escaping @Sendable () -> String = { "" }
        ) {
            self.sink = sink
            self.decode = decode
            self.summarizeOnStop = summarizeOnStop
            self.footprintSuffix = footprintSuffix
        }
    }

    /// The daemon-only closures `SessionFeatureServices` needs on top of what
    /// the runtime owns.
    public struct ServiceWiring: Sendable {
        public var endpointIndex: [String]
        public var startupDurationMs: @Sendable () -> Int?
        public var memorySample: @Sendable () -> SessionFeatureServices.MemorySample?
        public var parseQuarantinedEvent: @Sendable (String) -> ParseResult
        public var buildHookEvent: @Sendable (_ event: String, _ payload: Data) -> ParsedEvent?
        public var runImport: @Sendable (ImportRequestDTO) throws -> ImportSummary

        public init(
            endpointIndex: [String],
            startupDurationMs: @escaping @Sendable () -> Int?,
            memorySample: @escaping @Sendable () -> SessionFeatureServices.MemorySample?,
            parseQuarantinedEvent: @escaping @Sendable (String) -> ParseResult,
            buildHookEvent: @escaping @Sendable (_ event: String, _ payload: Data) -> ParsedEvent?,
            runImport: @escaping @Sendable (ImportRequestDTO) throws -> ImportSummary
        ) {
            self.endpointIndex = endpointIndex
            self.startupDurationMs = startupDurationMs
            self.memorySample = memorySample
            self.parseQuarantinedEvent = parseQuarantinedEvent
            self.buildHookEvent = buildHookEvent
            self.runImport = runImport
        }
    }

    public let configuration: SessionDaemonConfiguration
    public let hookInstaller: ClaudeHookInstaller
    public let secretStore: any SecretStoring

    private let migrations: [DaemonMigration]
    private let postMigration: [@Sendable (DaemonDatabase) throws -> Void]
    private let statusLineIngest: DaemonDatabase.StatusLineIngest?
    private let sessionUpsertHook: DaemonDatabase.SessionUpsertHook?
    private let behavior: Behavior

    private struct Opened {
        var spool: IngestSpool
        var database: DaemonDatabase
        var pipeline: IngestionPipeline
        var hookDisabled: Bool
    }
    private let lock = NSLock()
    private var opened: Opened?
    private var isShutDown = false

    /// - Parameters:
    ///   - migrations: the schema, numbered `1…n` contiguously.
    ///   - postMigration: ensure steps run after every migration pass.
    ///   - hookInstaller: defaults to one driven by `configuration.hook`.
    public init(
        configuration: SessionDaemonConfiguration,
        migrations: [DaemonMigration] = SessionSchema.migrations,
        postMigration: [@Sendable (DaemonDatabase) throws -> Void] = SessionSchema.postMigration,
        statusLineIngest: DaemonDatabase.StatusLineIngest? = nil,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook? = nil,
        behavior: Behavior,
        secretStore: any SecretStoring,
        hookInstaller: ClaudeHookInstaller? = nil
    ) {
        self.configuration = configuration
        self.migrations = migrations
        self.postMigration = postMigration
        self.statusLineIngest = statusLineIngest
        self.sessionUpsertHook = sessionUpsertHook
        self.behavior = behavior
        self.secretStore = secretStore
        self.hookInstaller = hookInstaller ?? ClaudeHookInstaller(configuration: configuration.hook)
    }

    // MARK: - Opened objects

    private func requireOpened(_ what: String) -> Opened {
        lock.lock()
        defer { lock.unlock() }
        guard let opened else {
            preconditionFailure("SessionDaemonRuntime.\(what) read before openPhaseA()")
        }
        return opened
    }

    /// Valid after ``openPhaseA()``.
    public var database: DaemonDatabase { requireOpened("database").database }
    /// Valid after ``openPhaseA()``.
    public var spool: IngestSpool { requireOpened("spool").spool }
    /// Valid after ``openPhaseA()``.
    public var pipeline: IngestionPipeline { requireOpened("pipeline").pipeline }
    /// Whether the user had turned tracking off when the runtime opened.
    public var hookDisabled: Bool { requireOpened("hookDisabled").hookDisabled }

    /// The conversations feed over the runtime's database.
    public var conversations: ConversationStore { ConversationStore(database: database) }

    /// The preferences service over the runtime's database. Valid after ``openPhaseA()``.
    public var preferences: PreferencesService {
        PreferencesService(
            database: database, secretStore: secretStore, hookInstaller: hookInstaller,
            summariesDefaultEnabled: configuration.summariesDefaultEnabled
        )
    }

    /// Everything the shared HTTP routes read. Valid after ``openPhaseA()``.
    public func services(_ wiring: ServiceWiring, startTime: Date) -> SessionFeatureServices {
        let opened = requireOpened("services")
        return SessionFeatureServices(
            database: opened.database,
            conversations: ConversationStore(database: opened.database),
            quarantine: opened.pipeline.quarantine,
            spool: opened.spool,
            preferences: preferences,
            secretStore: secretStore,
            hookInstaller: hookInstaller,
            daemonName: configuration.hook.name,
            daemonVersion: configuration.daemonVersion,
            startTime: startTime,
            endpointIndex: wiring.endpointIndex,
            startupDurationMs: wiring.startupDurationMs,
            memorySample: wiring.memorySample,
            parseQuarantinedEvent: wiring.parseQuarantinedEvent,
            retryIngest: opened.pipeline.retryIngest,
            buildHookEvent: wiring.buildHookEvent,
            captureHook: opened.pipeline.capture,
            runImport: wiring.runImport
        )
    }

    // MARK: - Steps

    /// Phase A: opens the spool and the database in parallel (the schema is NOT
    /// migrated), creates the support directory and reads the tracking choice,
    /// then assembles the capture path. Nothing here needs the main schema,
    /// which is what lets the listener come up before the migration.
    ///
    /// Throws when the spool or the database cannot be opened: without the
    /// spool there is nowhere to put a delivery, and without the pool there is
    /// no database at all. Neither is a migration failure.
    public func openPhaseA() async throws {
        let configuration = configuration
        let installer = hookInstaller
        let migrations = migrations
        let postMigration = postMigration
        let statusLineIngest = statusLineIngest
        let sessionUpsertHook = sessionUpsertHook

        try FileManager.default.createDirectory(
            at: configuration.supportDirectory, withIntermediateDirectories: true
        )
        async let spoolTask: IngestSpool = Self.openSpool(path: configuration.spoolPath)
        async let dbTask: DaemonDatabase = Self.openDatabase(
            configuration: configuration, migrations: migrations, postMigration: postMigration,
            statusLineIngest: statusLineIngest, sessionUpsertHook: sessionUpsertHook
        )
        async let hookDisabledTask: Bool = Self.checkHookDisabled(installer: installer)

        let spool = try await spoolTask
        let database = try await dbTask
        let hookDisabled = await hookDisabledTask

        let pipeline = IngestionPipeline(
            paths: .init(
                dropDirectory: configuration.dropDirectory,
                errorsDirectory: configuration.errorsDirectory,
                socketPath: configuration.socketPath
            ),
            spool: spool,
            database: database,
            sink: behavior.sink,
            queueLabel: { "\(configuration.subsystem).\($0)" },
            decode: behavior.decode,
            summarizeOnStop: behavior.summarizeOnStop,
            footprintSuffix: behavior.footprintSuffix
        )
        lock.withLock {
            opened = Opened(spool: spool, database: database, pipeline: pipeline, hookDisabled: hookDisabled)
        }
    }

    /// Phase B: binds the capture socket and reconciles the hook registration
    /// with the user's tracking choice, in parallel. Neither failure is fatal:
    /// every registration is the capture-script `command` hook, which writes a
    /// drop file whether or not the daemon is up, so capture stays intact and
    /// the drop directory is ingested once a later start binds.
    public func startIngress() async {
        let opened = requireOpened("startIngress")
        let installer = hookInstaller
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do { try opened.pipeline.startAcceptingCaptures() } catch {
                    Self.logger.error(
                        "Ingest socket failed to start: \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
            group.addTask {
                Self.applyHookState(installer: installer, disabled: opened.hookDisabled)
            }
        }
    }

    /// Phase B½: one attempt at the migration; idempotent once it has succeeded.
    public func migrate() throws {
        try database.migrateNow()
    }

    /// Starts emptying the spool into the migrated database.
    public func startDrainer() async {
        pipeline.startDraining()
    }

    /// Stops the ingestion pipeline: a batch already in flight finishes against
    /// the database, and anything still spooled drains on the next launch.
    /// Idempotent. The hook registration is deliberately left in place — see
    /// the daemon's own uninstall path.
    public func shutdown() async {
        let pipeline: IngestionPipeline? = lock.withLock {
            let current = isShutDown ? nil : opened?.pipeline
            isShutDown = true
            return current
        }
        await pipeline?.stop()
    }

    // MARK: - Sendable helpers (called from child tasks)

    private static func openSpool(path: String) throws -> IngestSpool {
        try IngestSpool(path: path)
    }

    /// Opens the pool only; the migration is ``migrate()``'s.
    private static func openDatabase(
        configuration: SessionDaemonConfiguration,
        migrations: [DaemonMigration],
        postMigration: [@Sendable (DaemonDatabase) throws -> Void],
        statusLineIngest: DaemonDatabase.StatusLineIngest?,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook?
    ) throws -> DaemonDatabase {
        try DaemonDatabase(
            path: configuration.databasePath,
            accountResolver: AccountResolver(claudeJSONPath: configuration.claudeJSONPath),
            deferMigrations: true,
            migrations: migrations,
            postMigration: postMigration,
            statusLineIngest: statusLineIngest,
            sessionUpsertHook: sessionUpsertHook
        )
    }

    private static func checkHookDisabled(installer: ClaudeHookInstaller) -> Bool {
        installer.isTrackingDisabled()
    }

    /// Reconciles `settings.json` with the user's tracking choice: uninstall
    /// when disabled, otherwise install (or upgrade to) the bundled hooks.
    private static func applyHookState(installer: ClaudeHookInstaller, disabled: Bool) {
        if disabled {
            let removed = installer.uninstallHooks()
            let msg = removed ? "removed leftover" : "no hooks to remove"
            logger.info("Tracking disabled by user; \(msg, privacy: .public)")
        } else {
            switch installer.installHooks() {
            case .installed:        logger.info("Hooks installed")
            case .alreadyInstalled: logger.info("Hooks already present")
            case .failed(let msg):  logger.warning("Hook install failed: \(msg, privacy: .public)")
            }
        }
    }
}

extension SessionDaemonRuntime: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
