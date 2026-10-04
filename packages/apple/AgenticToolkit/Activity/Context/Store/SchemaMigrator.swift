// BoundedDatabase ships only a macOS target today; the iOS database target is
// added in Task 1. Guarded on the module, not the platform, so this file needs
// no change when iOS gains it.
#if canImport(AgenticToolkitDatabase)
import Foundation
import AgenticToolkitDatabase
import GRDB

/// One numbered, forward-only schema step. `sql` may contain several
/// statements separated by `;` — GRDB's `execute` runs them all.
public struct SchemaMigration: Sendable {
    public let version: Int
    public let sql: String
    public init(version: Int, sql: String) {
        self.version = version
        self.sql = sql
    }
}

/// Applies numbered migrations against a `schema_migrations` table, replacing
/// the single-lump `if applied(1)` block that could never grow a version 2.
///
/// Each migration runs in its own write transaction together with the check
/// that it is unapplied and the bookkeeping row that records it, so a
/// migration and the record of it having been applied can never disagree: a
/// failure leaves that version unrecorded and it is retried on the next
/// launch, and a second process opening the same database serialises behind
/// the transaction rather than racing it (see ``migrate(_:)``).
public struct SchemaMigrator: Sendable {
    private let db: BoundedDatabase
    public init(database: BoundedDatabase) { self.db = database }

    public func appliedVersions() throws -> Set<Int> {
        try db.write { db in
            try Self.ensureTable(db)
            return try Self.versions(db)
        }
    }

    private static func versions(_ db: Database) throws -> Set<Int> {
        Set(try Int.fetchAll(db, sql: "SELECT version FROM schema_migrations"))
    }

    /// Applies every migration this database has not recorded yet.
    ///
    /// The "has it been applied?" read lives **inside** the transaction that
    /// applies it. That is what makes a concurrent opener safe, and only the
    /// read being inside will do: `BoundedDatabase.write` opens an IMMEDIATE
    /// transaction, so a second process blocks at `BEGIN` until the first
    /// commits and then reads a snapshot that already contains the version it
    /// was about to apply. Reading the applied set once, before the loop, let
    /// two processes at schema v3 both decide v4 was unapplied; the loser then
    /// re-ran migration 4's bare `ALTER TABLE usage_capture_spans ADD COLUMN
    /// machine_id TEXT` — a statement SQLite has no `IF NOT EXISTS` form for —
    /// and threw `duplicate column name` out of `ContextStore.init`, so v5 and
    /// v6 never applied in that process.
    ///
    /// Migration SQL is *not* assumed re-runnable. Several statements on the
    /// branch are not, and with the check inside the transaction none of them
    /// needs to be.
    public func migrate(_ migrations: [SchemaMigration]) throws {
        // Sorted by version, not by array order: a caller listing migrations
        // out of order still gets dependency-correct execution.
        for migration in migrations.sorted(by: { $0.version < $1.version }) {
            // One transaction per migration, not one for the whole run: a
            // migration and the record of it having been applied still commit
            // together, and a later failure leaves the earlier versions
            // recorded rather than replaying them next launch.
            try db.write { db in
                try Self.ensureTable(db)
                let applied = try Self.versions(db)
                guard !applied.contains(migration.version) else { return }
                try db.execute(sql: migration.sql)
                // `OR IGNORE` is belt and braces now that the read above
                // shares this transaction — kept because it costs one word and
                // the row is bookkeeping, so losing a race for it must never
                // abort a run whose migration actually succeeded.
                try db.execute(sql: """
                    INSERT OR IGNORE INTO schema_migrations (version, applied_at) VALUES (?, ?)
                    """,
                               arguments: [migration.version, ISO8601Timestamp.string(from: Date())])
            }
        }
    }

    private static func ensureTable(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS schema_migrations (
              version INTEGER PRIMARY KEY, applied_at TEXT)
            """)
    }
}
#endif
