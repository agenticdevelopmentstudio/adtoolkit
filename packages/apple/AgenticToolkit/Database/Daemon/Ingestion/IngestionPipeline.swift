#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import OSLog

/// The capture-to-database path of a session daemon, composed once: quarantine,
/// ingestor, spool drain, the `capture` closure both live capture paths feed, and
/// the hook socket.
///
/// Nothing here touches the main database until ``startDraining()``, which is the
/// requirement: all of it can exist, and ``startAcceptingCaptures()`` can be
/// running, before the database is migrated. A capture then goes into the spool
/// (a lock and an INSERT, with no main-DB schema, lock or transaction involved),
/// and the drain empties the spool into the database once it is ready.
///
/// The spool is opened by the caller and passed in, because opening it is one of
/// the awaits a daemon traces at startup.
public final class IngestionPipeline: @unchecked Sendable {

    /// Where the pipeline reads and writes on disk.
    public struct Paths: Sendable {
        /// Where hook drop files land; also the fallback when the spool refuses a write.
        public var dropDirectory: URL
        /// Where quarantined events are moved; each gets a `.meta.json` sidecar.
        public var errorsDirectory: URL
        /// The Unix socket a hook script connects to.
        public var socketPath: String

        public init(dropDirectory: URL, errorsDirectory: URL, socketPath: String) {
            self.dropDirectory = dropDirectory
            self.errorsDirectory = errorsDirectory
            self.socketPath = socketPath
        }
    }

    public let ingestor: EventIngestor
    public let quarantine: QuarantineService
    public let spool: IngestSpool
    /// The one way a live event enters the daemon, shared by both capture paths (the
    /// socket and an HTTP hook route). It writes to the spool and pokes the drain.
    /// If the spool itself is unwritable it falls back to a drop file, which the
    /// directory watcher owns from then on.
    public let capture: @Sendable (ParsedEvent) throws -> Void
    /// Ingests one event straight into the database, bypassing the spool: what the
    /// quarantine retry feeds. It runs well after the migration, and routing an
    /// already-quarantined file back through the queue would only make it harder
    /// to follow. Strong capture of the ingestor on purpose: a nil (optional-chained)
    /// ingestor would return without throwing, so a retry would count the event
    /// "recovered" and delete the file WITHOUT ingesting it.
    public let retryIngest: @Sendable (ParsedEvent) throws -> Void

    private let drainer: IngestDrainer
    private let socketHandler: IngestSocketHandler

    /// - Parameters:
    ///   - queueLabel: maps a short name to a full label; labels the quarantine
    ///     queue, the tailer queue and the drain thread so a daemon can put them
    ///     under its own subsystem.
    ///   - decode: turns the bytes of one socket connection into an event, throwing
    ///     ``SocketDecodeFailure`` when they are malformed or untrackable.
    ///   - summarizeOnStop: called with the session id after `Stop` / `SessionEnd`.
    ///   - footprintSuffix: appended to the ingestor's backfill log lines.
    public init(
        paths: Paths,
        spool: IngestSpool,
        database: DaemonDatabase,
        sink: any SessionEventSink,
        queueLabel: @Sendable (String) -> String,
        decode: @escaping @Sendable (Data) throws -> ParsedEvent,
        summarizeOnStop: (@Sendable (String) async -> Void)? = nil,
        footprintSuffix: @escaping @Sendable () -> String = { "" }
    ) {
        let quarantine = QuarantineService(
            errorsDirectory: paths.errorsDirectory,
            database: database,
            queueLabel: queueLabel("quarantine-retry")
        )
        let ingestor = EventIngestor(
            dropDirectory: paths.dropDirectory,
            database: database,
            sink: sink,
            quarantine: quarantine,
            tailerQueueLabel: queueLabel("transcript-tailer"),
            summarizeOnStop: summarizeOnStop,
            footprintSuffix: footprintSuffix
        )
        let drainer = IngestDrainer(
            spool: spool,
            quarantine: quarantine,
            errorsDirectory: paths.errorsDirectory,
            ingestBatch: { [ingestor] in try ingestor.ingestBatch($0) },
            ingestOne: { [ingestor] in try ingestor.ingest($0) },
            threadName: queueLabel("ingest-drain")
        )
        let dropDirectory = paths.dropDirectory
        let capture: @Sendable (ParsedEvent) throws -> Void = { [drainer] event in
            do {
                try spool.enqueue(event)
            } catch {
                // The spool file itself is unwritable — a full volume, most
                // likely, which is also the one condition under which an
                // undrainable spool grows until it causes exactly this. Both
                // callers fail open (a hook delivery must never surface an error
                // to Claude), so a throw from here is an event deleted. Fall back
                // to the drop directory, the capture path that predates the spool
                // and is still watched: one more small file may well fit where a
                // SQLite page did not, and if it doesn't, the throw is at least
                // now the *second* thing that failed rather than the first.
                Self.logger.error("""
                    Spool enqueue failed (\(error.localizedDescription, privacy: .public)); \
                    falling back to a drop file
                    """)
                try Self.writeDropFile(event, into: dropDirectory)
                return  // The directory watcher owns it now; nothing to wake.
            }
            drainer.wake()
        }
        self.quarantine = quarantine
        self.ingestor = ingestor
        self.spool = spool
        self.drainer = drainer
        self.capture = capture
        self.retryIngest = { [ingestor] in try ingestor.ingest($0) }
        self.socketHandler = IngestSocketHandler(
            socketPath: paths.socketPath, capture: capture, decode: decode
        )
    }

    // MARK: - Lifecycle

    /// Binds the hook socket. Needs no main-database schema, so it can run before
    /// the migration. Throws on a bind failure.
    public func startAcceptingCaptures() throws {
        try socketHandler.start()
    }

    /// Starts emptying the spool into the database. Call only once the database is
    /// migrated — this is the writer the migration protects the schema for.
    public func startDraining() {
        drainer.start()
    }

    /// Stops the drain (waiting for the pass in flight, so a batch already running
    /// finishes against the database rather than being abandoned mid-transaction)
    /// and then the socket. Anything still spooled stays spooled and drains on
    /// the next launch — that is what the file is for.
    public func stop() async {
        drainer.stop()
        socketHandler.stop()
    }

    // MARK: - Drop file fallback

    /// Last-resort capture when the spool refuses a write: the same envelope, in
    /// the same format, in the directory ``EventIngestor`` already watches. The
    /// name sorts by arrival and must not start with `error-`, which that scan
    /// skips.
    static func writeDropFile(_ event: ParsedEvent, into directory: URL) throws {
        let envelope = try event.envelopeJSON()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = "spill-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString).json"
        // Atomic: a plain write creates the file and fills it in two steps, so a
        // daemon killed in between (an install restart, say) leaves a 0-byte drop
        // that the ingestor can only read as a lost event.
        try envelope.write(to: directory.appendingPathComponent(name), options: .atomic)
    }
}

extension IngestionPipeline: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
