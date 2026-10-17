#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// The SQLite store a daemon owns: a GRDB WAL pool wrapped by `BoundedDatabase`,
/// a migration runner, and the low-level SQL helpers every feature store builds on.
///
/// All access goes through the pool: reads run concurrently on a small reader pool,
/// writes on the single writer connection (the WAL bulkhead, so a read never queues
/// behind a write), and every op carries a wall-clock deadline — a runaway is ejected
/// rather than held until launchd SIGKILLs the daemon. `execute`/`query`/`transaction`
/// are the chokepoints; a nested `execute`/`query` runs reentrantly on the current
/// connection (read-your-writes). `@unchecked Sendable`: the pool is thread-safe.
///
/// The schema is the caller's: it passes the ordered ``DaemonMigration`` list (and
/// any `postMigration` ensure steps) at init, so two daemons can share one core and
/// each append their own migrations after a shared prefix such as ``SessionSchema``.
public final class DaemonDatabase: @unchecked Sendable {

    // MARK: - Constants

    private static let readerCount = 3
    /// Ceiling for one off-queue read: long enough for a legitimate aggregate,
    /// short enough to eject a runaway scan. Reads are isolated from the writer.
    private static let readDeadline: Duration = .seconds(10)
    /// Ceiling for one write; generous so only a runaway hits it.
    private static let writeDeadline: Duration = .seconds(60)
    /// Wider ceiling for a one-time migration statement/transaction: an index build
    /// or backfill UPDATE on a large DB can legitimately take minutes and must never
    /// be ejected mid-flight. Passed explicitly by `migrationExecute` /
    /// `migrationTransaction` — there is no mutable per-instance deadline override
    /// (which would be a data race waiting to happen on the shared writer).
    public static let migrationWriteDeadline: Duration = .seconds(300)
    /// Ceiling for a one-time maintenance READ — the read-lane twin of
    /// `migrationWriteDeadline`, and the widest of the four. A maintenance scan
    /// is the one read legitimately allowed to take minutes
    /// (`repriceSessionMetricsIfNeeded` groups the whole of `transcript_turns`),
    /// and the serving ceiling above ejects it every time on a large DB.
    ///
    /// Wider than the migration ceiling on purpose: this one runs off both the
    /// startup and the serving path, and a pass that cannot finish inside it
    /// re-spends its whole cost on every launch forever, since the revision is
    /// recorded only on success. So the number is here to catch a hang, not to
    /// bound a scan that is merely slow. Passed explicitly, for the same reason
    /// as the others: no mutable per-instance override.
    public static let maintenanceReadDeadline: Duration = .seconds(900)

    // MARK: - Properties

    /// GRDB-backed database: a reader/writer WAL pool (bulkhead) with deadline
    /// ejection and read-your-writes reentrancy. Reads run on the read pool, writes
    /// on the single writer; a runaway op is ejected rather than holding a lane
    /// until launchd SIGKILLs the daemon. See `execute`/`query`.
    private let pool: BoundedDatabase
    public let path: String
    let migrations: [DaemonMigration]
    let postMigration: [@Sendable (DaemonDatabase) throws -> Void]

    /// A consumer's extra handling of a `StatusLine` event, run by `ingestEvent`
    /// inside the same write transaction as the rest of that event. It receives
    /// the database, the session id, the hook payload, the event timestamp and
    /// the account the event was attributed to. Because it runs inside the
    /// transaction, it may call the reentrant `execute` / `query` directly.
    public typealias StatusLineIngest = @Sendable (
        DaemonDatabase, _ sessionId: String, _ hookData: [String: Any],
        _ timestamp: String, _ accountEmail: String
    ) throws -> Void

    /// The consumer's `StatusLine` handler, or nil when it has none (the event is
    /// still recorded; only the extra routing is skipped).
    public let statusLineIngest: StatusLineIngest?

    /// A consumer's follow-up to the `sessions` upsert, run by `ingestEvent`
    /// inside the same write transaction, immediately after the upsert. It lets a
    /// consumer maintain its own per-session derived state. It receives the
    /// database, the session id, the event's timestamp as received, and whether
    /// the event counts as session activity. A throw rolls the whole ingest back.
    public typealias SessionUpsertHook = @Sendable (
        DaemonDatabase, _ sessionId: String, _ eventTimestamp: String,
        _ countsAsActivity: Bool
    ) throws -> Void

    /// The consumer's post-upsert hook, or nil when it has none.
    public let sessionUpsertHook: SessionUpsertHook?
    public let dynamicSchema = DynamicSchema()
    public let accountResolver: AccountResolver

    /// The Claude account currently logged in (`~/.claude.json`), or `""` if
    /// none can be resolved. Used to scope the usage views to the active
    /// account.
    public var currentAccountEmail: String { accountResolver.currentEmail() }

    // MARK: - Readiness

    /// Guards `_isReady` only. Deliberately not the DB queue: `isReady` is read
    /// by the router on every request, including while the migration holds the
    /// write lane, which is exactly when it must not be able to block.
    private let readyLock = NSLock()
    private var _isReady = false

    /// Whether the schema is migrated and the database can serve queries.
    ///
    /// False only during the window between `init(deferMigrations: true)` and
    /// `migrateNow()`. A daemon's HTTP layer reads it to answer 503 rather than
    /// run a query against a half-migrated schema; nothing else should need it,
    /// because everything else is started after the migration by construction.
    public var isReady: Bool {
        readyLock.lock()
        defer { readyLock.unlock() }
        return _isReady
    }

    // MARK: - Attachments

    private let attachmentLock = NSLock()
    private var attachments: [ObjectIdentifier: AnyObject] = [:]

    /// Per-database state for code that extends `DaemonDatabase` from outside
    /// this file. An extension cannot hold a stored property, so it keeps its
    /// caches in one object of its own type and reaches it through here.
    ///
    /// The first call for a type runs `make` and keeps the result; every later
    /// call for that type returns the same instance.
    public func attachment<T: AnyObject & Sendable>(_ type: T.Type, make: () -> T) -> T {
        attachmentLock.lock()
        defer { attachmentLock.unlock() }
        let key = ObjectIdentifier(type)
        if let existing = attachments[key] as? T { return existing }
        let created = make()
        attachments[key] = created
        return created
    }

    // MARK: - Initialization

    /// Opens the database and, unless `deferMigrations`, migrates it.
    ///
    /// - Parameter deferMigrations: when true, returns as soon as the pool is
    ///   open and leaves the schema to a later `migrateNow()`. The daemon uses
    ///   this to get the HTTP listener up *before* a long migration instead of
    ///   after it: migrating inside `init` meant the port stayed closed for the
    ///   whole migration, and Claude Code's `http` hook neither retries nor
    ///   spools, so every event delivered during that window was lost outright.
    ///   The split is only worth anything in combination with `IngestSpool`,
    ///   which is what those events land in meanwhile.
    ///
    ///   The *pool* is never deferred — only the schema. A `DaemonDatabase?`
    ///   would push an optional through every one of its several hundred call
    ///   sites to express a state that lasts seconds at startup; one `isReady`
    ///   flag, checked at the one boundary that faces the outside world, says
    ///   the same thing without contorting the rest of the daemon.
    /// - Parameter migrations: the schema, numbered `1…n` contiguously and in order.
    ///   A broken chain throws `openFailed` rather than skipping or double-applying a step.
    /// - Parameter postMigration: ensure steps run after every migration pass, outside
    ///   the version gate (each must be idempotent).
    /// - Parameter statusLineIngest: optional extra handling of a `StatusLine`
    ///   event, run inside that event's write transaction (see ``StatusLineIngest``).
    /// - Parameter sessionUpsertHook: optional follow-up to each `sessions` upsert,
    ///   run inside the same write transaction (see ``SessionUpsertHook``).
    public init(
        path: String,
        accountResolver: AccountResolver = AccountResolver(),
        deferMigrations: Bool = false,
        migrations: [DaemonMigration],
        postMigration: [@Sendable (DaemonDatabase) throws -> Void] = [],
        statusLineIngest: StatusLineIngest? = nil,
        sessionUpsertHook: SessionUpsertHook? = nil
    ) throws {
        let versions = migrations.map(\.version)
        guard versions == (0..<versions.count).map({ $0 + 1 }) else {
            throw DaemonDatabaseError.openFailed(
                "migrations must be numbered 1…n contiguously; found \(versions)"
            )
        }
        self.path = path
        self.accountResolver = accountResolver
        self.migrations = migrations
        self.postMigration = postMigration
        self.statusLineIngest = statusLineIngest
        self.sessionUpsertHook = sessionUpsertHook
        // GRDB owns the reader/writer WAL pool + FK enforcement + statement
        // plumbing; BoundedDatabase layers deadline-ejection + per-lane metrics on
        // top, and transparently uses a serial DatabaseQueue for an in-memory path.
        self.pool = try BoundedDatabase(
            path: self.path, readers: Self.readerCount,
            readDeadline: Self.readDeadline, writeDeadline: Self.writeDeadline
        )
        if deferMigrations {
            logger.info("Database open (migrations deferred) at \(self.path, privacy: .public)")
        } else {
            try migrateNow()
        }
    }

    /// Runs the migrations and marks the database ready. Idempotent: a second
    /// call is a no-op, so a caller that isn't sure whether `init` already
    /// migrated can call it anyway.
    public func migrateNow() throws {
        readyLock.lock()
        let alreadyReady = _isReady
        readyLock.unlock()
        guard !alreadyReady else { return }

        try runMigrations()

        readyLock.lock()
        _isReady = true
        readyLock.unlock()
        logger.info("Database ready at \(self.path, privacy: .public)")
    }

    // MARK: - Executor stats (observability)

    /// Per-lane counters for `/db/stats`: how many ops each pool ran, how many were
    /// ejected for exceeding their deadline, and recent latency percentiles. Makes
    /// the bounded-execution subsystem visible so a regression (rising evictions or
    /// p99) is observable instead of silent.
    public func dbStats() -> DBStatsDTO {
        let lanes = pool.stats.lanes
        func dtos(_ lane: String) -> [DBStatsDTO.Pool] {
            lanes.filter { $0.lane == lane }.map {
                DBStatsDTO.Pool(
                    pool: $0.lane, inFlight: $0.inFlight, completed: $0.completed,
                    evicted: $0.evicted, p50Ms: $0.p50Ms, p99Ms: $0.p99Ms
                )
            }
        }
        return DBStatsDTO(write: dtos("write"), read: dtos("read"))
    }

    // MARK: - Test support

    /// Flushes the write lane: enqueues an empty write op and waits for it, so any
    /// previously-submitted writes have completed. Only for use in tests.
    public func waitForPendingWrites() {
        _ = try? pool.write { _ in }
    }

    // MARK: - Low-level helpers (GRDB)

    /// Runs `sql` as a write on the write lane (default 60s ceiling) — deadline-bounded
    /// and ejectable. Reentrant via BoundedDatabase (a nested write/read runs inline on
    /// the same connection). Migrations use `migrationExecute` for a wider ceiling.
    public func execute(_ sql: String, params: [any Sendable] = []) throws {
        try write { database in
            try database.execute(sql: sql, arguments: try Self.args(params))
        }
    }

    /// Runs `body` as ONE real transaction on the write lane. GRDB opens the
    /// transaction and commits it, or rolls back automatically if `body` throws, so
    /// multi-statement work (per-day backfills) is atomic. Reentrant `execute`/`query`
    /// inside `body` join this transaction. Prefer this over hand-written
    /// `BEGIN`/`COMMIT`: the write lane has already opened a transaction, so a literal
    /// `BEGIN` statement would throw "cannot start a transaction within a transaction"
    /// (fail-fast) rather than silently nest.
    ///
    /// Public so a service can batch a whole provider-config reconcile — dozens of
    /// `setSetting`s — into one commit; the nested reentrant `execute` calls join
    /// this transaction.
    @discardableResult
    public func transaction<T>(_ body: () throws -> T) throws -> T {
        try write { _ in try body() }
    }

    /// `execute`, but with the wider migration deadline. Migrations run once at startup
    /// and may build a large index or backfill a big table, so a runtime-tight 60s
    /// ceiling would eject them mid-flight and fail startup on a large DB.
    public func migrationExecute(_ sql: String, params: [any Sendable] = []) throws {
        try write(deadline: Self.migrationWriteDeadline) { database in
            try database.execute(sql: sql, arguments: try Self.args(params))
        }
    }

    /// `transaction`, but with the wider migration deadline (see `migrationExecute`).
    /// Reentrant `execute`/`migrationExecute` inside `body` inherit this deadline.
    /// Public so a migration in another file can make a schema change and its
    /// backfill one atomic step.
    public func migrationTransaction(_ body: () throws -> Void) throws {
        try write(deadline: Self.migrationWriteDeadline) { _ in try body() }
    }

    /// Runs `sql` as a read (or, inside a write, read-your-writes on the writer),
    /// invoking `handler` once per row. `deadline` is for a maintenance scan that
    /// may legitimately outlast the serving ceiling; serving reads leave it nil.
    public func query(
        _ sql: String,
        params: [any Sendable] = [],
        deadline: Duration? = nil,
        handler: (Row) throws -> Void
    ) throws {
        try read(deadline: deadline) { database in
            let cursor = try Row.fetchCursor(database, sql: sql, arguments: try Self.args(params))
            while let row = try cursor.next() { try handler(row) }
        }
    }

    // MARK: - Pool boundary (error mapping)

    /// Every write goes through here so a GRDB / BoundedDatabase error surfaces as the
    /// daemon's `DaemonDatabaseError` — but ONLY at the outermost boundary. When the call is
    /// reentrant (nested inside another op) the raw `BoundedDatabaseError` is rethrown
    /// untouched so the enclosing `run` still records the eviction in `/db/stats`; the
    /// top-level caller then maps it. Errors from the transaction machinery itself
    /// (a COMMIT-time SQLITE_BUSY, an ejected `insertDynamic`) surface HERE, not inside
    /// `execute`, which is why mapping must live at this boundary.
    @discardableResult
    public func write<T>(deadline: Duration? = nil, _ body: (Database) throws -> T) throws -> T {
        do {
            return try pool.write(deadline: deadline, body)
        } catch {
            throw pool.isReentrant ? error : Self.mapDBError(error)
        }
    }

    /// Like `write` but opens no transaction (for `ATTACH` / self-managed `BEGIN`).
    @discardableResult
    public func writeWithoutTransaction<T>(
        deadline: Duration? = nil, _ body: (Database) throws -> T
    ) throws -> T {
        do {
            return try pool.writeWithoutTransaction(deadline: deadline, body)
        } catch {
            throw pool.isReentrant ? error : Self.mapDBError(error)
        }
    }

    /// Every read goes through here (same outermost-boundary mapping as `write`).
    @discardableResult
    public func read<T>(deadline: Duration? = nil, _ body: (Database) throws -> T) throws -> T {
        do {
            return try pool.read(deadline: deadline, body)
        } catch {
            throw pool.isReentrant ? error : Self.mapDBError(error)
        }
    }

    /// Translates the DB layer's error vocabulary into the daemon's `DaemonDatabaseError`
    /// so callers — notably the ingest retry/quarantine path — can classify
    /// transient failures. The write/read lanes throw `GRDB.DatabaseError` (raw
    /// SQLite result codes) and `BoundedDatabaseError.deadlineExceeded`; neither is
    /// the daemon's `DaemonDatabaseError`, so without this a write that hit SQLITE_BUSY (or
    /// was ejected) would be quarantined as permanent instead of retried.
    public static func mapDBError(_ error: Error) -> Error {
        switch error {
        case is DaemonDatabaseError:
            return error
        case let grdb as GRDB.DatabaseError:
            return DaemonDatabaseError.stepFailed(
                message: grdb.message ?? "\(grdb.resultCode)", code: grdb.resultCode.rawValue
            )
        case BoundedDatabaseError.deadlineExceeded:
            // A timing failure, not a data problem — surface as SQLITE_BUSY so the
            // ingest path treats it as transient and leaves the event for retry.
            return DaemonDatabaseError.stepFailed(
                message: "operation exceeded its deadline", code: ResultCode.SQLITE_BUSY.rawValue
            )
        default:
            return error
        }
    }

    /// Maps the daemon's loosely-typed bind params to GRDB positional arguments.
    /// Anything GRDB can bind (`DatabaseValueConvertible`: String/Int/Int64/Double/
    /// Bool/Date/Data/…) is forwarded natively; an unsupported type throws rather
    /// than being silently coerced to lossy TEXT (which would break BLOB/date
    /// comparisons with no error).
    public static func args(_ params: [Any]) throws -> StatementArguments {
        let values = try params.map { param -> (any DatabaseValueConvertible)? in
            switch param {
            case Optional<Any>.none: return nil          // a nil optional → SQL NULL
            case is NSNull: return nil                    // JSON null (from a hook payload) → SQL NULL
            case let text as String: return text
            case let num as Int: return num
            case let num as Int64: return num
            case let num as Double: return num
            case let flag as Bool: return flag
            case let value as any DatabaseValueConvertible: return value
            default:
                throw DaemonDatabaseError.stepFailed(
                    message: "unsupported bind parameter type: \(type(of: param))", code: 0
                )
            }
        }
        return StatementArguments(values)
    }

    // Column readers over a GRDB Row (GRDB decodes NULL as nil for optionals).
    public func string(_ row: Row, _ col: Int) -> String { row[col] ?? "" }
    public func optionalString(_ row: Row, _ col: Int) -> String? { row[col] }
    public func optionalInt(_ row: Row, _ col: Int) -> Int? { row[col] }
    public func int(_ row: Row, _ col: Int) -> Int { row[col] ?? 0 }
    public func int64(_ row: Row, _ col: Int) -> Int64 { row[col] ?? 0 }
    public func double(_ row: Row, _ col: Int) -> Double { row[col] ?? 0 }

    // MARK: - Schema introspection

    /// Every column name on `table`, or an empty set when the table is absent.
    /// Insights queries touch columns ``DynamicSchema`` creates lazily, so they
    /// check the whole set they read at once — checking one and reading five is
    /// how a fresh DB turns into a permanent HTTP 500.
    public func columnNames(of table: String) -> Set<String> {
        var names: Set<String> = []
        try? query("PRAGMA table_info(\(table))") { row in
            names.insert(self.string(row, 1))
        }
        return names
    }

    /// Check whether a table has a given column via `PRAGMA table_info`.
    /// Used by insights queries to short-circuit when a dynamic column
    /// (from ``DynamicSchema``) isn't present yet.
    public func tableHasColumn(_ table: String, _ column: String) -> Bool {
        var found = false
        try? query("PRAGMA table_info(\(table))") { row in
            let name = string(row, 1)
            if name == column { found = true }
        }
        return found
    }

    /// Whether a base table exists. Per-type event tables are created lazily by
    /// ``DynamicSchema`` on first ingest, so an event type never seen on this DB
    /// has no table yet — callers that reference one must guard with this.
    public func tableExists(_ table: String) -> Bool {
        var found = false
        try? query(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
            params: [table]
        ) { _ in found = true }
        return found
    }
}

extension DaemonDatabase: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
