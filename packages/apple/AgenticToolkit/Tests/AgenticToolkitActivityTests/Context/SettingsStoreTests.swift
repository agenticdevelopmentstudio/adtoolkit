#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

final class SettingsStoreTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!
    private var settings: SettingsStore!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-settings-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try BoundedDatabase(path: dir.appendingPathComponent("test.sqlite").path)
        settings = SettingsStore(database: db)
        try settings.runMigrations()
    }

    override func tearDownWithError() throws {
        settings = nil; db = nil
        try? FileManager.default.removeItem(at: dir)
    }

    func testEveryTriggerIsOffUntilTheUserOptsIn() throws {
        // The opt-in default must be OFF for every kind — a trigger that
        // defaults on collects data the user never agreed to.
        for kind in ContextEventKind.allCases {
            XCTAssertFalse(try settings.isTriggerEnabled(kind), "\(kind) defaulted to on")
        }
    }

    func testTriggerOptInRoundTrips() throws {
        try settings.setTriggerEnabled(.location, true)
        XCTAssertTrue(try settings.isTriggerEnabled(.location))
        XCTAssertFalse(try settings.isTriggerEnabled(.network), "kinds must not share a key")
        try settings.setTriggerEnabled(.location, false)
        XCTAssertFalse(try settings.isTriggerEnabled(.location))
    }

    func testTriggerKeysAreDistinctAndStable() throws {
        let keys = ContextEventKind.allCases.map(SettingsStore.triggerKey)
        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertEqual(ContextEventKind.allCases.count, 8)
        XCTAssertEqual(SettingsStore.triggerKey(.appFocus), "trigger.app_focus.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.window), "trigger.window.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.network), "trigger.network.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.location), "trigger.location.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.input), "trigger.input.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.session), "trigger.session.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.power), "trigger.power.enabled")
        XCTAssertEqual(SettingsStore.triggerKey(.appLifecycle), "trigger.app_lifecycle.enabled")
    }

    func testSettingsSurviveANewStoreOverTheSameDatabase() throws {
        try settings.setBool("some.flag", true)
        let reopened = SettingsStore(database: db)
        try reopened.runMigrations()
        XCTAssertTrue(try reopened.bool("some.flag", default: false))
    }

    // MARK: - Inactivity threshold

    func testInactivityThresholdDefaultsToTheSharedDefault() throws {
        XCTAssertEqual(try settings.inactivityThresholdSeconds(),
                       InactivityThreshold.defaultSeconds,
                       "an unset threshold must not read as zero — that declares the "
                       + "user absent the instant they stop typing")
    }

    func testInactivityThresholdRoundTrips() throws {
        try settings.setInactivityThresholdSeconds(600)
        XCTAssertEqual(try settings.inactivityThresholdSeconds(), 600)
        let reopened = SettingsStore(database: db)
        XCTAssertEqual(try reopened.inactivityThresholdSeconds(), 600,
                       "the daemon and the app read the same setting from the same file")
    }

    func testInactivityThresholdIsClampedOnTheWayIn() throws {
        try settings.setInactivityThresholdSeconds(0)
        XCTAssertEqual(try settings.inactivityThresholdSeconds(),
                       InactivityThreshold.secondsRange.lowerBound)
        try settings.setInactivityThresholdSeconds(Int.max)
        XCTAssertEqual(try settings.inactivityThresholdSeconds(),
                       InactivityThreshold.secondsRange.upperBound)
    }

    func testAnOutOfRangeStoredThresholdIsClampedOnTheWayOut() throws {
        // A row written by an older build, or by hand. Reading it back
        // unclamped would hand the trigger a threshold the UI cannot show.
        try settings.setString("trigger.input.inactivity_seconds", "999999999")
        XCTAssertEqual(try settings.inactivityThresholdSeconds(),
                       InactivityThreshold.secondsRange.upperBound)
    }

    func testAnUnparseableStoredThresholdFallsBackToTheDefault() throws {
        try settings.setString("trigger.input.inactivity_seconds", "soon")
        XCTAssertEqual(try settings.inactivityThresholdSeconds(),
                       InactivityThreshold.defaultSeconds)
    }

    func testMachineIDIsMintedOnceAndThenStable() throws {
        let first = try settings.machineID()
        XCTAssertEqual(try settings.machineID(), first)
        let reopened = SettingsStore(database: db)
        XCTAssertEqual(try reopened.machineID(), first,
                       "a re-minted machine id would fork this device's history")
    }

    func testMachineIDIsStableAcrossConcurrentFirstCalls() throws {
        // Both the app and the daemon can start at the same moment and call
        // machineID() for the first time; the mint-and-persist must happen
        // inside one write transaction so they can never mint two different
        // UUIDs for the same machine.
        let iterations = 20
        let uuidCollector = ResultCollector()
        let errorCollector = ErrorCollector()
        let db = self.db!
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            let store = SettingsStore(database: db)
            do {
                let id = try store.machineID()
                uuidCollector.append(id)
            } catch {
                errorCollector.append(error)
            }
        }
        if let firstError = errorCollector.errors.first {
            XCTFail("machineID() threw error: \(firstError)")
        }
        XCTAssertEqual(Set(uuidCollector.values).count, 1, "concurrent first calls minted different ids")
    }
}

/// Thread-safe accumulator for results produced across `concurrentPerform`
/// workers, which run on arbitrary threads with no serialization of their own.
private final class ResultCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [UUID] = []
    func append(_ value: UUID) { lock.withLock { stored.append(value) } }
    var values: [UUID] { lock.withLock { stored } }
}

/// Thread-safe accumulator for errors thrown across `concurrentPerform`
/// workers, which run on arbitrary threads with no serialization of their own.
private final class ErrorCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Error] = []
    func append(_ value: Error) { lock.withLock { stored.append(value) } }
    var errors: [Error] { lock.withLock { stored } }
}
#endif
