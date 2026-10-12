//
//  BrowserHistoryStore.swift
//  AgenticToolkit
//

import Foundation
import SQLite3
import AgenticToolkitDatabase

/// One page the browser was on.
public struct BrowserVisit: Equatable, Sendable, Identifiable {
    public let id: Int64
    public let url: URL
    public let title: String
    public let visitedAt: Date

    public init(id: Int64, url: URL, title: String, visitedAt: Date) {
        self.id = id
        self.url = url
        self.title = title
        self.visitedAt = visitedAt
    }
}

public enum BrowserHistoryStoreError: Error {
    case openFailed(String)
    case prepareFailed(String)
    case executionFailed(String)
}

/// Where the browser remembers the pages it has shown: one row per visit, in
/// its own SQLite file beside the project database.
///
/// Its own file rather than a table in `Projects.db` because history is the
/// one store here that a user clears wholesale, often, and a file that is
/// *only* history can be deleted without a migration touching anything else
/// (`design-for-deletion`). A single open connection serialised through its
/// own queue — the pane writes a row per page load and the panel reads a few
/// hundred, which is nowhere near needing a pool.
public final class BrowserHistoryStore: @unchecked Sendable {

    public static let fileName = "BrowserHistory.db"

    /// `~/.<app token>/BrowserHistory.db`, with the home directory explicit so
    /// a test run can point it anywhere.
    public static func defaultPath(
        inHome home: URL = FileManager.default.homeDirectoryForCurrentUser,
        token: String = AppStorageLocation.token
    ) -> String {
        AppStorageLocation.directory(inHome: home, token: token).appendingPathComponent(fileName).path
    }

    public let databasePath: String
    private var database: OpaquePointer?
    private let queue = DispatchQueue(label: "AgenticToolkit.BrowserHistoryStore")

    public init(path: String) throws {
        databasePath = path
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        let result = sqlite3_open_v2(
            path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil
        )
        guard result == SQLITE_OK else { throw BrowserHistoryStoreError.openFailed(lastErrorMessage) }
        sqlite3_busy_timeout(database, 5_000)
        try execute("PRAGMA journal_mode=WAL")
        try execute("""
            CREATE TABLE IF NOT EXISTS visit (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT NOT NULL,
                title TEXT NOT NULL DEFAULT '',
                visited_at REAL NOT NULL
            )
        """)
        try execute("CREATE INDEX IF NOT EXISTS visit_visited_at ON visit (visited_at DESC)")
    }

    deinit {
        sqlite3_close(database)
    }

    // MARK: - Writing

    /// Records a visit and returns its id, so a title that arrives after the
    /// load can be filed against the right row.
    @discardableResult
    public func record(_ url: URL, title: String, at date: Date = Date()) throws -> Int64 {
        try queue.sync {
            try executeBound("INSERT INTO visit (url, title, visited_at) VALUES (?, ?, ?)") { stmt in
                bindText(stmt, 1, url.absoluteString)
                bindText(stmt, 2, title)
                sqlite3_bind_double(stmt, 3, date.timeIntervalSince1970)
            }
            return sqlite3_last_insert_rowid(database)
        }
    }

    public func updateTitle(ofVisit id: Int64, to title: String) throws {
        try queue.sync {
            try executeBound("UPDATE visit SET title = ? WHERE id = ?") { stmt in
                bindText(stmt, 1, title)
                sqlite3_bind_int64(stmt, 2, id)
            }
        }
    }

    public func remove(visit id: Int64) throws {
        try queue.sync {
            try executeBound("DELETE FROM visit WHERE id = ?") { stmt in sqlite3_bind_int64(stmt, 1, id) }
        }
    }

    /// Forgets every visit before `cutoff`.
    public func removeVisits(before cutoff: Date) throws {
        try queue.sync {
            try executeBound("DELETE FROM visit WHERE visited_at < ?") { stmt in
                sqlite3_bind_double(stmt, 1, cutoff.timeIntervalSince1970)
            }
        }
    }

    public func removeAll() throws {
        try queue.sync { try execute("DELETE FROM visit") }
    }

    // MARK: - Reading

    /// The latest visits, newest first.
    public func recent(limit: Int = 200) throws -> [BrowserVisit] {
        try queue.sync {
            try query("""
                SELECT id, url, title, visited_at FROM visit
                ORDER BY visited_at DESC, id DESC LIMIT ?
            """) { stmt in
                sqlite3_bind_int(stmt, 1, Int32(limit))
            }
        }
    }

    /// Visits whose address or title contains `text`, newest first.
    public func search(_ text: String, limit: Int = 200) throws -> [BrowserVisit] {
        try queue.sync {
            try query("""
                SELECT id, url, title, visited_at FROM visit
                WHERE url LIKE ? ESCAPE '\\' OR title LIKE ? ESCAPE '\\'
                ORDER BY visited_at DESC, id DESC LIMIT ?
            """) { stmt in
                let pattern = "%" + Self.escapedForLike(text) + "%"
                bindText(stmt, 1, pattern)
                bindText(stmt, 2, pattern)
                sqlite3_bind_int(stmt, 3, Int32(limit))
            }
        }
    }

    public func count() throws -> Int {
        try queue.sync {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(database, "SELECT COUNT(*) FROM visit", -1, &stmt, nil) == SQLITE_OK else {
                throw BrowserHistoryStoreError.prepareFailed(lastErrorMessage)
            }
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                throw BrowserHistoryStoreError.executionFailed(lastErrorMessage)
            }
            return Int(sqlite3_column_int64(stmt, 0))
        }
    }

    /// `%` and `_` are LIKE's wildcards, so a search for either must escape
    /// it or match everything; `\` is the escape the query names.
    static func escapedForLike(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    // MARK: - SQLite

    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var lastErrorMessage: String {
        if let database { return String(cString: sqlite3_errmsg(database)) }
        return "Database not open"
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw BrowserHistoryStoreError.executionFailed(message)
        }
    }

    private func executeBound(_ sql: String, bind: (OpaquePointer?) -> Void) throws {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw BrowserHistoryStoreError.prepareFailed(lastErrorMessage)
        }
        bind(stmt)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw BrowserHistoryStoreError.executionFailed(lastErrorMessage)
        }
    }

    private func query(_ sql: String, bind: (OpaquePointer?) -> Void) throws -> [BrowserVisit] {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw BrowserHistoryStoreError.prepareFailed(lastErrorMessage)
        }
        bind(stmt)
        var visits: [BrowserVisit] = []
        while true {
            let status = sqlite3_step(stmt)
            if status == SQLITE_DONE { return visits }
            // Anything but ROW or DONE is a failure, not a short answer
            // (`fail-fast`) — a locked file must not read as an empty history.
            guard status == SQLITE_ROW else { throw BrowserHistoryStoreError.executionFailed(lastErrorMessage) }
            guard let urlText = sqlite3_column_text(stmt, 1).map({ String(cString: $0) }),
                  let url = URL(string: urlText) else { continue }
            let title = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
            visits.append(BrowserVisit(
                id: sqlite3_column_int64(stmt, 0),
                url: url,
                title: title,
                visitedAt: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
            ))
        }
    }

    private func bindText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, Self.sqliteTransient)
    }
}
