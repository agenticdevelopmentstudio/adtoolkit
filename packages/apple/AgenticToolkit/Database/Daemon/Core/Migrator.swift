#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB

/// One numbered schema step. `run` receives the database it migrates and is
/// applied at most once per database, then recorded in `schema_migrations`.
public struct DaemonMigration: Sendable {
    public let version: Int
    public let run: @Sendable (DaemonDatabase) throws -> Void

    public init(version: Int, run: @escaping @Sendable (DaemonDatabase) throws -> Void) {
        self.version = version
        self.run = run
    }
}

extension DaemonDatabase {

    // MARK: - Migrations

    func runMigrations() throws {
        try migrationExecute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)

        let applied = try appliedMigrations()

        for migration in migrations where !applied.contains(migration.version) {
            try migration.run(self)
            try migrationExecute("INSERT INTO schema_migrations(version) VALUES (?)",
                                 params: [migration.version])
        }

        // Ensure steps OUTSIDE the version gate: idempotent repairs that must
        // hold however the database got to its version (a build whose branch
        // recorded a version for a different change, say).
        for ensure in postMigration {
            try ensure(self)
        }
    }

    private func appliedMigrations() throws -> Set<Int> {
        var versions = Set<Int>()
        try query("SELECT version FROM schema_migrations") { row in
            versions.insert(Int(int(row, 0)))
        }
        return versions
    }
}
#endif
