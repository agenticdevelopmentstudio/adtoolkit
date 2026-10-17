import XCTest
import GRDB
@testable import AgenticToolkitDatabase

final class SessionSchemaTests: XCTestCase {

    private var path: String!
    private var created: DaemonDatabase!

    override func setUpWithError() throws {
        (created, path) = try TestDaemonDatabase.makeSessionDatabase()
    }

    override func tearDownWithError() throws {
        created = nil
        TestDaemonDatabase.remove(path: path)
    }

    /// A second handle on the same file, for the reopen cases.
    private func reopen() throws -> DaemonDatabase {
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
        let store = try XCTUnwrap(created)
        XCTAssertTrue(store.isReady)
        var newest = 0
        try store.query("SELECT MAX(version) FROM schema_migrations") { row in newest = store.int(row, 0) }
        XCTAssertEqual(newest, 45)
        for table in ["sessions", "event_log", "settings", "transcript_turns", "ingestion_errors"] {
            XCTAssertTrue(store.tableExists(table), "\(table) should exist")
        }
    }

    func testSettingsRoundTrip() throws {
        let store = try XCTUnwrap(created)
        try store.setSetting("k", "v")
        XCTAssertEqual(try store.setting(for: "k"), "v")
        try store.setSetting("k", "w")
        XCTAssertEqual(try store.setting(for: "k"), "w")
        XCTAssertNil(try store.setting(for: "missing"))
    }

    func testReopeningRunsEveryEnsureWithoutError() throws {
        let first = try XCTUnwrap(created)
        // Stamp every recorded migration so a re-run (a fresh INSERT) is visible.
        try first.execute("UPDATE schema_migrations SET applied_at = '2000-01-01 00:00:00'")

        let again = try reopen()
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
