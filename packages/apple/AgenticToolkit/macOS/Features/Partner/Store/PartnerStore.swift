import Combine
import Foundation
import SQLite3
import AgenticToolkitCore
import AgenticToolkitDatabase

public enum PartnerStoreError: Error {
    case openFailed(String)
    case prepareFailed(String)
    case executionFailed(String)
    case invalidData(String)
}

/// The Coding Partner's one database, `Partner.db`.
///
/// Raw sqlite3 with a numbered migration chain, shaped like `ProjectDatabase`.
/// Every public call takes one lock, so the store can be shared across the
/// partner's actors and the UI without a second layer of synchronisation.
/// `changes` fires after the lock is released, so a subscriber may read the
/// store from its sink without deadlocking.
public final class PartnerStore: @unchecked Sendable {

    public static let currentSchemaVersion = 1

    /// What kind of rows a committed write touched.
    public enum Change: Sendable, Equatable { case attention, transcript, jobs, sessions, reviews, settings }

    /// Sent after each committed write, on the calling thread.
    public let changes = PassthroughSubject<Change, Never>()

    let databasePath: String
    private var database: OpaquePointer?
    private let lock = NSLock()

    /// `~/.<token>/Partner.db`, beside `Projects.db`.
    public static func defaultPath(
        inHome home: URL = FileManager.default.homeDirectoryForCurrentUser,
        token: String = AppStorageLocation.token
    ) -> String {
        AppStorageLocation.directory(inHome: home, token: token)
            .appendingPathComponent("Partner.db")
            .path
    }

    public init(path: String) throws {
        databasePath = path
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        try openDatabase()
        try runMigrations()
    }

    deinit {
        if let database { sqlite3_close(database) }
    }

    private func openDatabase() throws {
        let result = sqlite3_open_v2(
            databasePath, &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil)
        guard result == SQLITE_OK else { throw PartnerStoreError.openFailed(lastErrorMessage) }
        try execute("PRAGMA journal_mode=WAL")
        try execute("PRAGMA foreign_keys=ON")
        sqlite3_busy_timeout(database, 5_000)
    }

    // MARK: - Migrations

    /// One transaction around the whole chain, so a crash cannot leave the
    /// schema changed with the version row still behind it.
    private func runMigrations() throws {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            try execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version INTEGER PRIMARY KEY,
                    applied_at TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
            if try schemaVersion() < 1 {
                try migration001_createSchema()
            }
            try execute("COMMIT")
        } catch {
            _ = try? execute("ROLLBACK")
            throw error
        }
    }

    func schemaVersion() throws -> Int {
        let rows = try runQuery("SELECT COALESCE(MAX(version), 0) FROM schema_migrations", []) { Int($0.int(0)) }
        return rows.first ?? 0
    }

    private func migration001_createSchema() throws {
        let statements = [
            """
            CREATE TABLE IF NOT EXISTS attention_item (
                id TEXT PRIMARY KEY, kind TEXT NOT NULL, text TEXT NOT NULL, reference_json TEXT NOT NULL,
                state TEXT NOT NULL, created_by TEXT NOT NULL, created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL, completed_at TEXT
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_attention_item_state ON attention_item(state, created_at)",
            """
            CREATE TABLE IF NOT EXISTS attention_action (
                id TEXT PRIMARY KEY, item_id TEXT NOT NULL, action TEXT NOT NULL, at TEXT NOT NULL,
                message_id TEXT
            )
            """,
            "CREATE INDEX IF NOT EXISTS idx_attention_action_item ON attention_action(item_id)",
            """
            CREATE TABLE IF NOT EXISTS partner_message (
                id TEXT NOT NULL, role TEXT NOT NULL, text TEXT NOT NULL,
                attribution_source TEXT, attribution_name TEXT, attribution_icon TEXT,
                attribution_context_json TEXT, created_at TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS job (
                id TEXT PRIMARY KEY, name TEXT NOT NULL, is_enabled INTEGER NOT NULL, schedule_seconds INTEGER,
                guidelines TEXT NOT NULL, steps_json TEXT NOT NULL, is_builtin INTEGER NOT NULL,
                updated_at TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS partner_session (
                id TEXT PRIMARY KEY, title TEXT NOT NULL, directory TEXT NOT NULL, opened_at TEXT NOT NULL,
                closed_at TEXT, final_screen TEXT, review_id TEXT
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS tool_call (
                id INTEGER PRIMARY KEY, caller TEXT, name TEXT NOT NULL, arguments TEXT NOT NULL,
                is_error INTEGER NOT NULL, at TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS partner_lock (
                id INTEGER PRIMARY KEY CHECK(id = 1), pid INTEGER NOT NULL, started_at TEXT NOT NULL
            )
            """,
            "CREATE TABLE IF NOT EXISTS partner_setting (key TEXT PRIMARY KEY, value TEXT NOT NULL)",
            "INSERT INTO schema_migrations (version) VALUES (1)"
        ]
        for sql in statements { try execute(sql) }
    }

    // MARK: - Settings

    public func sessionID() throws -> UUID? {
        try value(forKey: Self.sessionIDKey).flatMap { UUID(uuidString: $0) }
    }

    public func setSessionID(_ id: UUID?) throws {
        try setValue(id?.uuidString, forKey: Self.sessionIDKey)
    }

    public func value(forKey key: String) throws -> String? {
        try locked {
            try runQuery("SELECT value FROM partner_setting WHERE key = ?", [.text(key)]) { $0.text(0) }.first
        }
    }

    public func setValue(_ value: String?, forKey key: String) throws {
        try write(.settings) {
            if let value {
                try run("INSERT OR REPLACE INTO partner_setting (key, value) VALUES (?, ?)",
                        [.text(key), .text(value)])
            } else {
                try run("DELETE FROM partner_setting WHERE key = ?", [.text(key)])
            }
        }
    }

    private static let sessionIDKey = "session_id"

    // MARK: - Live lock

    /// The process holding the partner, if any. Says nothing about whether it is still alive.
    public func liveLock() throws -> (pid: Int32, startedAt: Date)? {
        try locked { try readLock() }
    }

    /// Takes the lock for `pid`. False when another pid holds it and `isAlive` says it still runs.
    public func acquireLock(pid: Int32, isAlive: (Int32) -> Bool) throws -> Bool {
        try locked {
            if let held = try readLock(), held.pid != pid, isAlive(held.pid) { return false }
            try run("INSERT OR REPLACE INTO partner_lock (id, pid, started_at) VALUES (1, ?, ?)",
                    [.int(Int64(pid)), .text(Self.string(from: Date()))])
            return true
        }
    }

    /// Releases the lock only if `pid` still holds it.
    public func releaseLock(pid: Int32) throws {
        try locked { try run("DELETE FROM partner_lock WHERE id = 1 AND pid = ?", [.int(Int64(pid))]) }
    }

    private func readLock() throws -> (pid: Int32, startedAt: Date)? {
        try runQuery("SELECT pid, started_at FROM partner_lock WHERE id = 1", []) { row in
            (Int32(row.int(0)), try Self.date(from: row.text(1)))
        }.first
    }

    // MARK: - Tool log

    public func logToolCall(caller: String?, name: String, arguments: String, isError: Bool) throws {
        try locked {
            try run("INSERT INTO tool_call (caller, name, arguments, is_error, at) VALUES (?, ?, ?, ?, ?)",
                    [.optText(caller), .text(name), .text(arguments), .int(isError ? 1 : 0),
                     .text(Self.string(from: Date()))])
        }
    }

    // MARK: - JSON

    static func json<T: Encodable>(_ value: T, sorted: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        if sorted { encoder.outputFormatting = [.sortedKeys] }
        guard let text = String(data: try encoder.encode(value), encoding: .utf8) else {
            throw PartnerStoreError.invalidData("unencodable JSON")
        }
        return text
    }

    // MARK: - Dates

    // ISO8601DateFormatter is documented thread-safe; every use here is also under `lock`.
    nonisolated(unsafe) private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }

    static func date(from string: String) throws -> Date {
        guard let date = formatter.date(from: string) else {
            throw PartnerStoreError.invalidData("bad date \(string)")
        }
        return date
    }

    // MARK: - SQLite plumbing

    /// A bound parameter.
    enum Value {
        case text(String)
        case int(Int64)
        case null

        static func optText(_ value: String?) -> Value { value.map { .text($0) } ?? .null }
        static func optDate(_ value: Date?) -> Value { value.map { .text(PartnerStore.string(from: $0)) } ?? .null }
        static func date(_ value: Date) -> Value { .text(PartnerStore.string(from: value)) }
    }

    /// A positioned view over the current result row.
    struct Row {
        let stmt: OpaquePointer?

        func text(_ index: Int32) -> String { optText(index) ?? "" }
        func optText(_ index: Int32) -> String? { sqlite3_column_text(stmt, index).map { String(cString: $0) } }
        func int(_ index: Int32) -> Int64 { sqlite3_column_int64(stmt, index) }
        func optInt(_ index: Int32) -> Int64? {
            sqlite3_column_type(stmt, index) == SQLITE_NULL ? nil : int(index)
        }
        func date(_ index: Int32) throws -> Date { try PartnerStore.date(from: text(index)) }
        func optDate(_ index: Int32) throws -> Date? { try optText(index).map { try PartnerStore.date(from: $0) } }
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var lastErrorMessage: String {
        database.map { String(cString: sqlite3_errmsg($0)) } ?? "Database not open"
    }

    /// Runs `body` holding the store's lock.
    @discardableResult
    func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    /// Runs `body` under the lock, then announces `change` once the lock is released.
    @discardableResult
    func write<T>(_ change: Change, _ body: () throws -> T) throws -> T {
        let result = try locked(body)
        changes.send(change)
        return result
    }

    @discardableResult
    private func execute(_ sql: String) throws -> Int32 {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        if result != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw PartnerStoreError.executionFailed(message)
        }
        return result
    }

    private func prepare(_ sql: String, _ binds: [Value]) throws -> OpaquePointer? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            sqlite3_finalize(stmt)
            throw PartnerStoreError.prepareFailed(lastErrorMessage)
        }
        for (offset, bind) in binds.enumerated() {
            let index = Int32(offset + 1)
            switch bind {
            case .text(let value): sqlite3_bind_text(stmt, index, value, -1, Self.transient)
            case .int(let value): sqlite3_bind_int64(stmt, index, value)
            case .null: sqlite3_bind_null(stmt, index)
            }
        }
        return stmt
    }

    /// Executes one statement and returns the number of rows it changed. Caller holds the lock.
    @discardableResult
    func run(_ sql: String, _ binds: [Value]) throws -> Int {
        let stmt = try prepare(sql, binds)
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw PartnerStoreError.executionFailed(lastErrorMessage) }
        return Int(sqlite3_changes(database))
    }

    /// Maps every result row of `sql`. Caller holds the lock.
    func runQuery<T>(_ sql: String, _ binds: [Value], _ map: (Row) throws -> T) throws -> [T] {
        let stmt = try prepare(sql, binds)
        defer { sqlite3_finalize(stmt) }
        var results: [T] = []
        while true {
            let status = sqlite3_step(stmt)
            if status == SQLITE_DONE { return results }
            guard status == SQLITE_ROW else { throw PartnerStoreError.executionFailed(lastErrorMessage) }
            results.append(try map(Row(stmt: stmt)))
        }
    }
}
