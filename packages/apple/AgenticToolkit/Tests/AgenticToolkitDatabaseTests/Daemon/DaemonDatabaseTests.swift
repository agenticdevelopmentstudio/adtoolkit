import XCTest
import GRDB
@testable import AgenticToolkitDatabase

final class DaemonDatabaseTests: XCTestCase {

    private var path: String!

    override func setUpWithError() throws {
        path = NSTemporaryDirectory() + "daemondb-\(UUID().uuidString).store"
    }

    override func tearDownWithError() throws {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
    }

    /// Counts how many times each migration body ran.
    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var counts: [Int: Int] = [:]
        private var order: [String] = []
        func hit(_ key: Int) { lock.withLock { counts[key, default: 0] += 1 } }
        func note(_ label: String) { lock.withLock { order.append(label) } }
        func count(_ key: Int) -> Int { lock.withLock { counts[key] ?? 0 } }
        var labels: [String] { lock.withLock { order } }
    }

    private func twoMigrations(_ counter: Counter) -> [DaemonMigration] {
        [
            DaemonMigration(version: 1) { store in
                counter.hit(1)
                try store.migrationExecute("CREATE TABLE IF NOT EXISTS a (x INTEGER)")
            },
            DaemonMigration(version: 2) { store in
                counter.hit(2)
                try store.migrationExecute("CREATE TABLE IF NOT EXISTS b (x INTEGER)")
            }
        ]
    }

    private func recordedVersions(_ store: DaemonDatabase) throws -> Set<Int> {
        var versions: Set<Int> = []
        try store.query("SELECT version FROM schema_migrations") { row in versions.insert(store.int(row, 0)) }
        return versions
    }

    // MARK: - Migration runner

    func testMigrateNowRunsEachMigrationOnceAndIsIdempotent() throws {
        let counter = Counter()
        let store = try DaemonDatabase(path: path, deferMigrations: true, migrations: twoMigrations(counter))
        try store.migrateNow()
        try store.migrateNow()
        XCTAssertEqual(counter.count(1), 1)
        XCTAssertEqual(counter.count(2), 1)
        XCTAssertEqual(try recordedVersions(store), [1, 2])

        let second = try DaemonDatabase(path: path, migrations: twoMigrations(counter))
        XCTAssertTrue(second.isReady)
        XCTAssertEqual(counter.count(1), 1, "an already-recorded migration must not run again")
        XCTAssertEqual(counter.count(2), 1)
    }

    func testDeferredMigrationsLeaveTheDatabaseNotReady() throws {
        let counter = Counter()
        let store = try DaemonDatabase(path: path, deferMigrations: true, migrations: twoMigrations(counter))
        XCTAssertFalse(store.isReady)
        XCTAssertFalse(store.tableExists("schema_migrations"))
        try store.migrateNow()
        XCTAssertTrue(store.isReady)
        XCTAssertTrue(store.tableExists("schema_migrations"))
    }

    func testDefaultInitIsReadyImmediately() throws {
        let store = try DaemonDatabase(path: path, migrations: twoMigrations(Counter()))
        XCTAssertTrue(store.isReady)
    }

    func testAGapInTheVersionsIsAccepted() throws {
        let counter = Counter()
        let migrations = [1, 3, 1001].map { version in
            DaemonMigration(version: version) { _ in counter.note("m\(version)") }
        }
        _ = try DaemonDatabase(path: path, migrations: migrations)
        XCTAssertEqual(counter.labels, ["m1", "m3", "m1001"])
    }

    func testADaemonMigrationAddedAfterAHigherSharedOneHasRunStillRuns() throws {
        let counter = Counter()
        func migration(_ version: Int) -> DaemonMigration {
            DaemonMigration(version: version) { _ in counter.note("m\(version)") }
        }
        _ = try DaemonDatabase(path: path, migrations: [migration(1), migration(1001)])
        XCTAssertEqual(counter.labels, ["m1", "m1001"])

        // The daemon later ships its own 46; the database has already applied 1001.
        _ = try DaemonDatabase(path: path, migrations: [migration(1), migration(1001), migration(46)])
        XCTAssertEqual(counter.labels, ["m1", "m1001", "m46"], "46 runs once; 1 and 1001 do not rerun")
    }

    func testMigrationsRunInAscendingOrderWhateverOrderTheyArePassedIn() throws {
        let counter = Counter()
        let migrations = [1001, 46, 1].map { version in
            DaemonMigration(version: version) { _ in counter.note("m\(version)") }
        }
        _ = try DaemonDatabase(path: path, migrations: migrations)
        XCTAssertEqual(counter.labels, ["m1", "m46", "m1001"])
    }

    func testDuplicateOrNonPositiveVersionsAreRefused() {
        let noop: @Sendable (DaemonDatabase) throws -> Void = { _ in }
        for versions in [[1, 2, 2], [1, 46, 1, 46], [0, 1], [-1]] {
            let migrations = versions.map { DaemonMigration(version: $0, run: noop) }
            XCTAssertThrowsError(try DaemonDatabase(path: path, migrations: migrations)) { error in
                guard case DaemonDatabaseError.openFailed(let message) = error else {
                    return XCTFail("expected openFailed, got \(error)")
                }
                XCTAssertTrue(message.contains("unique"), message)
            }
        }
    }

    func testPostMigrationRunsAfterMigrationsInOrderOnEveryFreshInstance() throws {
        let counter = Counter()
        let migrations = [
            DaemonMigration(version: 1) { _ in counter.note("m1") },
            DaemonMigration(version: 2) { _ in counter.note("m2") }
        ]
        let post: [@Sendable (DaemonDatabase) throws -> Void] = [
            { _ in counter.note("p1") },
            { _ in counter.note("p2") }
        ]
        _ = try DaemonDatabase(path: path, migrations: migrations, postMigration: post)
        XCTAssertEqual(counter.labels, ["m1", "m2", "p1", "p2"])

        // Ensures are not version-gated: a second instance runs them again, but no migration.
        _ = try DaemonDatabase(path: path, migrations: migrations, postMigration: post)
        XCTAssertEqual(counter.labels, ["m1", "m2", "p1", "p2", "p1", "p2"])
    }

    // MARK: - Error mapping

    func testDeadlineExceededMapsToTransientBusy() throws {
        let mapped = DaemonDatabase.mapDBError(BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 1))
        guard case DaemonDatabaseError.stepFailed(_, let code) = mapped else {
            return XCTFail("expected stepFailed, got \(mapped)")
        }
        XCTAssertEqual(code, ResultCode.SQLITE_BUSY.rawValue)
        XCTAssertEqual((mapped as? DaemonDatabaseError)?.isTransient, true)
    }

    func testConstraintErrorMapsToPermanentStepFailed() throws {
        let grdb = GRDB.DatabaseError(resultCode: .SQLITE_CONSTRAINT)
        let mapped = DaemonDatabase.mapDBError(grdb)
        guard case DaemonDatabaseError.stepFailed(_, let code) = mapped else {
            return XCTFail("expected stepFailed, got \(mapped)")
        }
        XCTAssertEqual(code, ResultCode.SQLITE_CONSTRAINT.rawValue)
        XCTAssertEqual((mapped as? DaemonDatabaseError)?.isTransient, false)
    }

    func testDaemonDatabaseErrorPassesThroughUnchanged() {
        let original = DaemonDatabaseError.prepareFailed(message: "boom", code: 1)
        guard case DaemonDatabaseError.prepareFailed(let message, let code) = DaemonDatabase.mapDBError(original) else {
            return XCTFail("expected prepareFailed to pass through")
        }
        XCTAssertEqual(message, "boom")
        XCTAssertEqual(code, 1)
    }

    // MARK: - Attachments

    private final class Slot: @unchecked Sendable {}

    func testAttachmentIsCreatedOncePerType() throws {
        let store = try DaemonDatabase(path: path, migrations: twoMigrations(Counter()))
        var made = 0
        let first = store.attachment(Slot.self) { made += 1; return Slot() }
        let second = store.attachment(Slot.self) { made += 1; return Slot() }
        XCTAssertTrue(first === second)
        XCTAssertEqual(made, 1)
    }
}
