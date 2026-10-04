#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

final class SchemaMigratorTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-migrator-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try BoundedDatabase(path: dir.appendingPathComponent("test.sqlite").path)
    }

    override func tearDownWithError() throws {
        db = nil
        try? FileManager.default.removeItem(at: dir)
    }

    func testAppliesMigrationsInOrderAndRecordsThem() throws {
        let m = SchemaMigrator(database: db)
        try m.migrate([
            SchemaMigration(version: 1, sql: "CREATE TABLE a (x INTEGER)"),
            SchemaMigration(version: 2, sql: "CREATE TABLE b (y INTEGER)"),
        ])
        XCTAssertEqual(try m.appliedVersions(), [1, 2])
        try db.read { db in
            XCTAssertTrue(try db.tableExists("a"))
            XCTAssertTrue(try db.tableExists("b"))
        }
    }

    func testIsIdempotentAndAppliesOnlyTheNewMigrationOnASecondRun() throws {
        let m = SchemaMigrator(database: db)
        try m.migrate([SchemaMigration(version: 1, sql: "CREATE TABLE a (x INTEGER)")])
        try db.write { db in try db.execute(sql: "INSERT INTO a (x) VALUES (42)") }

        // Re-running migration 1 must NOT re-execute it (which would fail on
        // CREATE TABLE, or worse, silently wipe data in a destructive script).
        try m.migrate([
            SchemaMigration(version: 1, sql: "CREATE TABLE a (x INTEGER)"),
            SchemaMigration(version: 2, sql: "CREATE TABLE b (y INTEGER)"),
        ])
        XCTAssertEqual(try m.appliedVersions(), [1, 2])
        try db.read { db in
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT x FROM a"), 42)
        }
    }

    /// A version can be recorded as applied between the migrator deciding it
    /// is unapplied and the migrator applying it. In the field that is the app
    /// and olylod opening the same database at once, both reading `{1, 2, 3}`
    /// before either writes; two entries for one version in a single call
    /// reproduces the identical stale-set condition deterministically, because
    /// the loop's membership test is what has to notice.
    ///
    /// The colliding migration is a bare `ALTER TABLE … ADD COLUMN`, which is
    /// the shape migration 4 actually ships (`OlyloSchema.swift`) and which
    /// SQLite has no `IF NOT EXISTS` form for. Anything re-runnable here — a
    /// `CREATE TABLE IF NOT EXISTS`, say — would encode the assumption instead
    /// of testing it: the run would survive the second pass by luck rather
    /// than because the migrator declined to make it.
    func testAVersionAlreadyRecordedIsNotReRunEvenWhenItsSQLCannotBeReRun() throws {
        let m = SchemaMigrator(database: db)
        try m.migrate([
            SchemaMigration(version: 1, sql: "CREATE TABLE a (x INTEGER)"),
            SchemaMigration(version: 2, sql: "ALTER TABLE a ADD COLUMN y TEXT"),
            SchemaMigration(version: 2, sql: "ALTER TABLE a ADD COLUMN y TEXT"),
            SchemaMigration(version: 3, sql: "CREATE TABLE b (z INTEGER)"),
        ])
        XCTAssertEqual(try m.appliedVersions(), [1, 2, 3])
        try db.read { db in
            XCTAssertTrue(try db.columns(in: "a").contains { $0.name == "y" },
                          "migration 2 must have been applied once")
            XCTAssertTrue(try db.tableExists("b"),
                          "the collision must not have stopped migration 3")
        }
    }

    func testAppliesOutOfOrderInputInVersionOrder() throws {
        let m = SchemaMigrator(database: db)
        // Migration 2 depends on the table migration 1 creates; if the
        // migrator ran them as given it would fail.
        try m.migrate([
            SchemaMigration(version: 2, sql: "CREATE INDEX idx_a_x ON a(x)"),
            SchemaMigration(version: 1, sql: "CREATE TABLE a (x INTEGER)"),
        ])
        XCTAssertEqual(try m.appliedVersions(), [1, 2])
    }

    func testAFailingMigrationIsNotRecordedAsApplied() throws {
        let m = SchemaMigrator(database: db)
        XCTAssertThrowsError(try m.migrate([
            SchemaMigration(version: 1, sql: "CREATE TABLE a (x INTEGER)"),
            SchemaMigration(version: 2, sql: "THIS IS NOT SQL"),
        ]))
        // 1 succeeded and stays recorded; 2 must be retried next launch.
        XCTAssertEqual(try m.appliedVersions(), [1])
    }
}
#endif
