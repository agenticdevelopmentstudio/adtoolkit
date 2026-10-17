#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// One captured event waiting to be moved into the main database.
public struct SpooledEvent: Sendable {
    public let id: Int64
    public let eventType: String
    /// The drop-file envelope JSON — `ParseResult.parse(envelopeJSON:)` reads it
    /// back, so spooling costs no second encoding and no second format.
    public let envelope: Data
    public let attempts: Int

    public init(id: Int64, eventType: String, envelope: Data, attempts: Int) {
        self.id = id
        self.eventType = eventType
        self.envelope = envelope
        self.attempts = attempts
    }
}

/// What the spool is holding right now, served at `GET /ingestion/spool`.
public struct IngestSpoolStatusDTO: Codable, Sendable {
    public let pending: Int
    /// Age in seconds of the oldest undrained event, or nil when empty. This is
    /// the number that says whether the drain is keeping up.
    public let oldestPendingAgeSeconds: Double?

    public init(pending: Int, oldestPendingAgeSeconds: Double?) {
        self.pending = pending
        self.oldestPendingAgeSeconds = oldestPendingAgeSeconds
    }
}

/// The daemon's staging queue for captured events, in its own SQLite file.
///
/// Capture and storage used to be the same write: a hook POST ran
/// the database ingest inside the request, so anything that made the
/// main database unavailable made the daemon *lose* events rather than merely
/// delay them. The two worst cases were structural. Migrations ran inside
/// the database initializer, before the HTTP listener existed, so every POST
/// during a migration was refused by a closed port — and Claude Code's native
/// `http` hook does not retry or spool, so a refused delivery is simply gone.
/// And even with the daemon up, the hook handler failed open:
/// the hook contract forbids ever failing a delivery back to Claude, so an
/// ingest error was logged and the event discarded.
///
/// So capture writes here instead. This file holds one table of opaque
/// envelopes and is the only thing a hook delivery touches; `IngestDrainer` is
/// the only reader, and moves events into the main database when it is healthy.
/// Three properties follow from the split:
///
/// - **The listener can precede the schema.** `DaemonController` opens the main
///   DB without migrating it, starts the listener, and migrates behind it.
///   Events that arrive during those minutes land here and drain afterwards.
/// - **No DDL on the capture path.** `DynamicSchema.ensureColumns` can `ALTER
///   TABLE` inside the live ingest transaction when a payload carries a
///   never-seen field. Here the payload is one opaque blob, so the schema below
///   is the schema forever and the ALTER happens in the drain instead.
/// - **Writes amortize.** The drain moves a batch in one main-DB transaction
///   rather than one transaction per event.
///
/// **What the split costs.** Every event now goes through three write
/// transactions instead of one — enqueue here, ingest into the main DB, delete
/// here — which sounds like three times the durability cost and isn't. Both
/// files are GRDB `DatabasePool`s, so both are WAL with `synchronous=NORMAL`:
/// a commit appends to the WAL and does **not** fsync, and the fsync happens
/// per checkpoint rather than per commit. Two of the three are also on the
/// *drain's* thread, off the hook-delivery path entirely, and the delete is one
/// statement for a whole batch. What the hook delivery actually pays is one
/// append to a single-table file with no DDL, no joins and no triggers — which
/// is why the spool is faster on the path that matters than the thing it
/// replaced, not merely safer.
///
/// **This is a queue, and it only stays a simplification while it stays one.**
/// A second table, a foreign key, or a column that means something to a reader
/// other than the drain turns it into a fork of the schema — two to migrate,
/// which is the problem it was built to remove. `CREATE TABLE IF NOT EXISTS` is
/// the whole of its migration story, and must remain so.
public final class IngestSpool: @unchecked Sendable {

    public static let defaultDBName = "ingest.db"

    /// Drain attempts before an event is handed to the file quarantine. Only
    /// *permanent* failures count toward it — a transient DB error backs the
    /// whole batch off and is never charged to an event (see `IngestDrainer`).
    static let maxAttempts = 5

    /// Reads come from the single drain loop, so one reader is the true
    /// concurrency. The second is headroom for `status()`, which the app polls.
    private static let readerCount = 2
    /// Both lanes are deliberately far tighter than the main DB's. Nothing here
    /// scans, joins or migrates: every statement is a primary-key write or a
    /// `LIMIT`ed read off one index, so a second is already pathological — and
    /// the enqueue sits on the hook-delivery path, where slow is the failure.
    private static let readDeadline: Duration = .seconds(5)
    private static let writeDeadline: Duration = .seconds(10)

    private let pool: BoundedDatabase
    private let dbPath: String

    /// - Parameter path: the spool file. The caller decides where; a daemon puts it
    ///   beside its main database (see ``defaultDBName``).
    public init(path: String) throws {
        self.dbPath = path
        self.pool = try BoundedDatabase(
            path: self.dbPath, readers: Self.readerCount,
            readDeadline: Self.readDeadline, writeDeadline: Self.writeDeadline
        )
        try createSchema()
        logger.info("Ingest spool ready at \(self.dbPath, privacy: .public)")
    }

    /// The entire schema. Not a migration list, and must never become one —
    /// see the note on the type.
    private func createSchema() throws {
        try pool.write { database in
            try database.execute(sql: """
                CREATE TABLE IF NOT EXISTS spooled_event (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    received_at REAL NOT NULL,
                    event_type  TEXT NOT NULL,
                    session_id  TEXT NOT NULL DEFAULT '',
                    envelope    BLOB NOT NULL,
                    attempts    INTEGER NOT NULL DEFAULT 0,
                    last_error  TEXT
                )
            """)
        }
    }

    // MARK: - In

    /// Records an event and returns. The only write a hook delivery performs.
    public func enqueue(_ event: ParsedEvent, now: Date = Date()) throws {
        let envelope = try event.envelopeJSON()
        try pool.write { database in
            try database.execute(
                sql: """
                    INSERT INTO spooled_event (received_at, event_type, session_id, envelope)
                    VALUES (?, ?, ?, ?)
                """,
                arguments: [now.timeIntervalSince1970, event.eventType, event.sessionId, envelope]
            )
        }
    }

    // MARK: - Out

    /// The oldest `limit` undrained events, in arrival order. Order is part of
    /// the contract: a session's events only make sense replayed as they came.
    public func pendingBatch(limit: Int) throws -> [SpooledEvent] {
        try pool.read { database in
            try Row.fetchAll(
                database,
                sql: """
                    SELECT id, event_type, envelope, attempts
                    FROM spooled_event ORDER BY id LIMIT ?
                """,
                arguments: [limit]
            ).map {
                SpooledEvent(
                    id: $0["id"], eventType: $0["event_type"],
                    envelope: $0["envelope"], attempts: $0["attempts"]
                )
            }
        }
    }

    /// Forgets events the main database has accepted. Called only after that
    /// write has committed, which is what makes delivery at-least-once: a kill
    /// in the gap replays the batch rather than dropping it.
    public func complete(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ",")
        try pool.write { database in
            try database.execute(
                sql: "DELETE FROM spooled_event WHERE id IN (\(placeholders))",
                arguments: StatementArguments(ids)
            )
        }
    }

    /// Charges one permanent failure to an event and reports whether that was
    /// its last. The caller quarantines and `complete`s an exhausted event —
    /// this only counts, so that "what happens to a doomed event" stays in one
    /// place (`IngestDrainer`) instead of being split across two files.
    public func recordFailure(id: Int64, reason: String) throws -> Bool {
        var exhausted = false
        try pool.write { database in
            try database.execute(
                sql: """
                    UPDATE spooled_event SET attempts = attempts + 1, last_error = ?
                    WHERE id = ?
                """,
                arguments: [reason, id]
            )
            // A row that vanished under us (a concurrent drain, a manual DELETE)
            // reads as exhausted: the caller then quarantines a copy it already
            // holds, which is the safe direction to be wrong in.
            exhausted = try Int.fetchOne(
                database, sql: "SELECT attempts FROM spooled_event WHERE id = ?", arguments: [id]
            ).map { $0 >= Self.maxAttempts } ?? true
        }
        return exhausted
    }

    // MARK: - Status

    public func status(now: Date = Date()) throws -> IngestSpoolStatusDTO {
        try pool.read { database in
            let pending = try Int.fetchOne(
                database, sql: "SELECT COUNT(*) FROM spooled_event"
            ) ?? 0
            let oldest = try Double.fetchOne(
                database, sql: "SELECT MIN(received_at) FROM spooled_event"
            )
            return IngestSpoolStatusDTO(
                pending: pending,
                oldestPendingAgeSeconds: oldest.map { now.timeIntervalSince1970 - $0 }
            )
        }
    }

    /// Undrained events, for log lines that shouldn't throw. The table is a
    /// queue, so this is a cheap count, not a scan.
    public func pendingCount() -> Int {
        (try? status().pending) ?? 0
    }
}

extension IngestSpool: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
