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
        _ = try open()
        let again = try open()
        XCTAssertTrue(again.isReady)
    }
}
