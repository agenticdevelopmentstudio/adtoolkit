// swiftlint:disable identifier_name
import XCTest
@testable import AgenticToolkitDatabase

/// A throwaway session database for tests that need the real schema (the
/// `ingestion_errors` table, for one). Every test that opens one removes it
/// again with `remove(path:)`.
enum TestDaemonDatabase {

    /// Opens a fresh `SessionSchema` database at a unique temp path.
    static func makeSessionDatabase(
        statusLineIngest: DaemonDatabase.StatusLineIngest? = nil,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook? = nil,
        file: StaticString = #filePath, line: UInt = #line
    ) throws -> (db: DaemonDatabase, path: String) {
        let path = NSTemporaryDirectory() + "daemontest-\(UUID().uuidString).db"
        do {
            let db = try DaemonDatabase(
                path: path,
                migrations: SessionSchema.migrations,
                postMigration: SessionSchema.postMigration,
                statusLineIngest: statusLineIngest,
                sessionUpsertHook: sessionUpsertHook
            )
            return (db, path)
        } catch {
            remove(path: path)
            XCTFail("could not open a session database: \(error)", file: file, line: line)
            throw error
        }
    }

    /// Removes the database file and its WAL siblings.
    static func remove(path: String) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
    }
}
// swiftlint:enable identifier_name
