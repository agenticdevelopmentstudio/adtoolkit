import XCTest
import GRDB
@testable import AgenticToolkitDatabase

final class SessionSchemaTests: XCTestCase {

    private var path: String!

    override func setUpWithError() throws {
        path = NSTemporaryDirectory() + "sessionschema-\(UUID().uuidString).db"
    }

    override func tearDownWithError() throws {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
    }

    private func open() throws -> DaemonDatabase {
        try DaemonDatabase(
            path: path,
            migrations: SessionSchema.migrations,
            postMigration: SessionSchema.postMigration
        )
    }

    func testMigrationsAreNumberedOneThroughFortyFive() {
        XCTAssertEqual(SessionSchema.migrations.map(\.version), Array(1...45))
    }

    func testFreshDatabaseMigratesToTheLatestVersionWithTheCoreTables() throws {
        let store = try open()
        XCTAssertTrue(store.isReady)
        var newest = 0
        try store.query("SELECT MAX(version) FROM schema_migrations") { row in newest = store.int(row, 0) }
        XCTAssertEqual(newest, 45)
        for table in ["sessions", "event_log", "settings", "transcript_turns", "ingestion_errors"] {
            XCTAssertTrue(store.tableExists(table), "\(table) should exist")
        }
    }

    func testSettingsRoundTrip() throws {
        let store = try open()
        try store.setSetting("k", "v")
        XCTAssertEqual(try store.setting(for: "k"), "v")
        try store.setSetting("k", "w")
        XCTAssertEqual(try store.setting(for: "k"), "w")
        XCTAssertNil(try store.setting(for: "missing"))
    }

    func testReopeningRunsEveryEnsureWithoutError() throws {
        let first = try open()
        // Stamp every recorded migration so a re-run (a fresh INSERT) is visible.
        try first.execute("UPDATE schema_migrations SET applied_at = '2000-01-01 00:00:00'")

        let again = try open()
        XCTAssertTrue(again.isReady)

        var rows = 0
        var untouched = 0
        try again.query("SELECT applied_at FROM schema_migrations") { row in
            rows += 1
            if again.string(row, 0) == "2000-01-01 00:00:00" { untouched += 1 }
        }
        XCTAssertEqual(rows, SessionSchema.migrations.count, "reopening must not add or drop a record")
        XCTAssertEqual(untouched, rows, "no migration may re-run on reopen")
    }
}
