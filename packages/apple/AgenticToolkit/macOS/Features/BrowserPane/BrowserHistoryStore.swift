//
//  BrowserHistoryStore.swift
//  AgenticToolkit
//

import Foundation
import GRDB
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

/// Where the browser remembers the pages it has shown: one row per visit, in
/// its own SQLite file beside the project database.
///
/// Its own file rather than a table in `Projects.db` because history is the
/// one store here that a user clears wholesale, often, and a file that is
/// *only* history can be deleted without a migration touching anything else
/// (`design-for-deletion`). The file is opened through `BoundedDatabase`, the
/// same pool every other store in the toolkit sits on: WAL with one writer
/// and pooled readers, a deadline on every statement so a wedged file cannot
/// hang the pane, and GRDB's binding and row reading in place of hand-rolled
/// `sqlite3_*` calls (`open-source-preference`, `dry`).
///
/// Every method here runs on the caller's thread and returns when the file
/// has answered. The pane and the panel are on the main actor, and a WAL
/// commit waits on the disk, so they go through ``perform(_:)``.
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
    private let database: BoundedDatabase

    public init(path: String) throws {
        databasePath = path
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        database = try BoundedDatabase(path: path)
        try database.write { connection in
            try connection.execute(sql: """
                CREATE TABLE IF NOT EXISTS visit (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT NOT NULL,
                    title TEXT NOT NULL DEFAULT '',
                    visited_at REAL NOT NULL
                )
            """)
            try connection.execute(sql: "CREATE INDEX IF NOT EXISTS visit_visited_at ON visit (visited_at DESC)")
        }
    }

    /// Runs `work` against the store off the caller's thread, for a caller
    /// on the main actor. Every method here reads or writes the file, and a
    /// write's commit waits on the disk; neither belongs on the thread that
    /// draws the pane.
    public func perform<T: Sendable>(_ work: @escaping @Sendable (BrowserHistoryStore) throws -> T) async throws -> T {
        let store = self
        return try await Task.detached(priority: .utility) { try work(store) }.value
    }

    // MARK: - Writing

    /// Records a visit and returns its id, so a title that arrives after the
    /// load can be filed against the right row.
    @discardableResult
    public func record(_ url: URL, title: String, at date: Date = Date()) throws -> Int64 {
        try database.write { connection in
            try connection.execute(
                sql: "INSERT INTO visit (url, title, visited_at) VALUES (?, ?, ?)",
                arguments: [url.absoluteString, title, date.timeIntervalSince1970]
            )
            return connection.lastInsertedRowID
        }
    }

    public func updateTitle(ofVisit id: Int64, to title: String) throws {
        try database.write { connection in
            try connection.execute(sql: "UPDATE visit SET title = ? WHERE id = ?", arguments: [title, id])
        }
    }

    public func remove(visit id: Int64) throws {
        try database.write { connection in
            try connection.execute(sql: "DELETE FROM visit WHERE id = ?", arguments: [id])
        }
    }

    /// Forgets every visit before `cutoff`.
    public func removeVisits(before cutoff: Date) throws {
        try database.write { connection in
            try connection.execute(
                sql: "DELETE FROM visit WHERE visited_at < ?", arguments: [cutoff.timeIntervalSince1970])
        }
    }

    public func removeAll() throws {
        try database.write { connection in
            try connection.execute(sql: "DELETE FROM visit")
        }
    }

    // MARK: - Reading

    /// The latest visits, newest first.
    public func recent(limit: Int = 200) throws -> [BrowserVisit] {
        try database.read { connection in
            try Row.fetchAll(connection, sql: """
                SELECT id, url, title, visited_at FROM visit
                ORDER BY visited_at DESC, id DESC LIMIT ?
            """, arguments: [limit]).compactMap(Self.visit(from:))
        }
    }

    /// Visits whose address or title contains `text`, newest first.
    public func search(_ text: String, limit: Int = 200) throws -> [BrowserVisit] {
        let pattern = "%" + Self.escapedForLike(text) + "%"
        return try database.read { connection in
            try Row.fetchAll(connection, sql: """
                SELECT id, url, title, visited_at FROM visit
                WHERE url LIKE ? ESCAPE '\\' OR title LIKE ? ESCAPE '\\'
                ORDER BY visited_at DESC, id DESC LIMIT ?
            """, arguments: [pattern, pattern, limit]).compactMap(Self.visit(from:))
        }
    }

    public func count() throws -> Int {
        try database.read { connection in
            try Int.fetchOne(connection, sql: "SELECT COUNT(*) FROM visit") ?? 0
        }
    }

    /// `%` and `_` are LIKE's wildcards, so a search for either must escape
    /// it or match everything; `\` is the escape the query names.
    static func escapedForLike(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    /// A row that no longer parses as an address is skipped, not fatal: the
    /// rest of the history is still worth showing.
    private static func visit(from row: Row) -> BrowserVisit? {
        guard let url = URL(string: row["url"]) else { return nil }
        return BrowserVisit(
            id: row["id"],
            url: url,
            title: row["title"],
            visitedAt: Date(timeIntervalSince1970: row["visited_at"])
        )
    }
}
