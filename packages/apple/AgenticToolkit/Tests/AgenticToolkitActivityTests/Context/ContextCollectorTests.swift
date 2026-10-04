#if os(macOS)
import XCTest
import GRDB
import AgenticToolkitDatabase
@testable import AgenticToolkitActivity

@MainActor
final class ContextCollectorTests: XCTestCase {
    private var dir: URL!
    private var db: BoundedDatabase!
    private var store: ContextStore!
    private var settings: SettingsStore!
    private var machine: MachineDescriptor!

    // `async` overrides of XCTestCase's setUp/tearDown inherit the class's
    // `@MainActor` isolation; the `…WithError` pair does not, which left
    // every property access in here nonisolated.
    override func setUp() async throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("olylo-collector-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        db = try BoundedDatabase(path: dir.appendingPathComponent("test.sqlite").path)
        store = ContextStore(database: db)
        settings = SettingsStore(database: db)
        try store.runMigrations()
        try settings.runMigrations()
        machine = MachineDescriptor(id: try settings.machineID(), platform: .macOS,
                                    nativeID: nil, nativeIDKind: nil, hostname: nil,
                                    model: nil, osVersion: nil)
        try store.upsertMachine(machine, seenAt: Date(timeIntervalSince1970: 1_000))
    }

    override func tearDown() async throws {
        store = nil; settings = nil; db = nil
        try? FileManager.default.removeItem(at: dir)
    }

    private func makeCollector(_ triggers: [any ContextTrigger],
                               gate: any ContextPermissionGate = FakePermissionGate(statuses: [:]))
    -> ContextCollector {
        ContextCollector(store: store, settings: settings, machine: machine,
                         gate: gate, triggers: triggers, onWriteError: nil)
    }

    func testDoesNotStartATriggerTheUserHasNotEnabled() async throws {
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        await c.start()
        XCTAssertEqual(t.startCount, 0)
    }

    func testStartsAnEnabledTriggerWhosePermissionIsGranted() async throws {
        try settings.setTriggerEnabled(.session, true)
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        await c.start()
        XCTAssertEqual(t.startCount, 1)
    }

    func testDoesNotStartAnEnabledTriggerWhosePermissionIsDenied() async throws {
        // Consent alone is not enough — this is the second half of the dual gate.
        try settings.setTriggerEnabled(.location, true)
        let t = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let c = makeCollector([t], gate: FakePermissionGate(statuses: [.location: .denied]))
        await c.start()
        XCTAssertEqual(t.startCount, 0)
    }

    func testPersistsAnEventEmittedByARunningTrigger() async throws {
        try settings.setTriggerEnabled(.session, true)
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        await c.start()
        t.emit()
        XCTAssertEqual(try store.eventCount(kind: .session), 1)
        try db.read { db in
            XCTAssertEqual(try String.fetchOne(db, sql: "SELECT machine_id FROM context_event"),
                           machine.id.uuidString)
            XCTAssertEqual(try String.fetchOne(db, sql: "SELECT occurred_at FROM context_event"),
                           "1970-01-01T01:06:40.000Z")
        }
    }

    /// I-1: a trigger may emit synchronously from inside `start()` —
    /// `PowerTrigger` does it deliberately, so the log opens with a known
    /// power state, and `AppFocusTrigger` does it through
    /// `FrontmostFocusAdapter.start()`. That event must be recorded, not
    /// dropped by `record`'s `running` guard.
    func testRecordsAnEventEmittedSynchronouslyFromInsideStart() async throws {
        try settings.setTriggerEnabled(.power, true)
        let t = FakeContextTrigger(kind: .power)
        t.emitsDuringStart = Date(timeIntervalSince1970: 4_000)
        let c = makeCollector([t])
        await c.start()
        XCTAssertEqual(try store.eventCount(kind: .power), 1)
    }

    /// The same seam on the live-toggle path: ticking a box in the settings
    /// panel restarts the trigger, and its opening event must survive that
    /// too.
    func testRecordsAnEventEmittedFromInsideStartWhenEnabledLive() async throws {
        let t = FakeContextTrigger(kind: .power)
        t.emitsDuringStart = Date(timeIntervalSince1970: 4_000)
        let c = makeCollector([t])
        await c.start()
        XCTAssertEqual(try store.eventCount(kind: .power), 0, "not opted in yet")

        try await c.setEnabled(.power, true)
        XCTAssertEqual(try store.eventCount(kind: .power), 1)
    }

    /// The other half of the I-1 fix: marking the trigger running before
    /// `start()` must not survive a `start()` that throws, or a trigger that
    /// never attached would be treated as running — and its stale events
    /// recorded — forever.
    func testATriggerWhoseStartThrowsIsNotLeftMarkedRunning() async throws {
        struct Boom: Error {}
        try settings.setTriggerEnabled(.session, true)
        let t = FakeContextTrigger(kind: .session)
        t.startError = Boom()
        let c = makeCollector([t])
        await c.start()

        let states = await c.states()
        XCTAssertEqual(states.first(where: { $0.kind == .session })?.isRunning, false)
        t.emit()
        XCTAssertEqual(try store.eventCount(kind: .session), 0)
        c.stop()
        XCTAssertEqual(t.stopCount, 0, "a trigger that never attached must not be stopped")
    }

    /// I-3, end to end: a window retitle must reach the **context** pipeline
    /// and write an `app_focus` row. Usage capture is never started here —
    /// that is the default, and the nudge used to live entirely on the usage
    /// pipeline's adapters, so in this configuration it was dead code.
    ///
    /// Uses the production shape: a real `AppFocusTrigger` over a
    /// `SharedWindowLifecycleSource`, driven through a real `ContextCollector`
    /// into the real store.
    func testATitleChangeWritesAnAppFocusEventWithUsageCaptureOff() async throws {
        try settings.setTriggerEnabled(.appFocus, true)
        let focus = FakeFocusSource()
        focus.current = WindowFocus(app: AppInfo(bundleID: "com.apple.Safari", name: "Safari", pid: 7),
                                    windowID: 3, title: "Tab One", documentPath: nil)
        let windows = FakeWindowSource()
        // The hub is held for the duration of the test, as `ContextStrategy`
        // holds it for the daemon's: it references its clients weakly and they
        // reference it weakly, so a hub nobody retains takes the observation
        // down with it.
        let hub = SharedWindowLifecycleSource(windows)
        let trigger = AppFocusTrigger(source: focus,
                                      titleSource: hub.makeClient(),
                                      executablePath: { _ in nil })
        let c = makeCollector([trigger])
        await c.start()
        XCTAssertEqual(try store.eventCount(kind: .appFocus), 1, "start() records what is frontmost")

        // The tab switch: same window, new title, no app activation.
        focus.current = WindowFocus(app: AppInfo(bundleID: "com.apple.Safari", name: "Safari", pid: 7),
                                    windowID: 3, title: "Tab Two", documentPath: nil)
        windows.emitTitleChange()

        XCTAssertEqual(try store.eventCount(kind: .appFocus), 2)
        try db.read { db in
            XCTAssertEqual(try String.fetchOne(
                db, sql: "SELECT window_title FROM context_event_app_focus ORDER BY rowid DESC"),
                "Tab Two")
        }
        // Also keeps `hub` alive to here: ARC would otherwise release it after
        // its last use, which is `makeClient()` on the line it was created.
        XCTAssertTrue(hub.isObserving, "the hub must observe while a client is started")
    }

    func testIgnoresEventsFromATriggerThatWasNeverStarted() async throws {
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        await c.start()
        t.emit()   // a rogue trigger firing while gated off
        XCTAssertEqual(try store.eventCount(kind: .session), 0)
    }

    func testSetEnabledStartsAndStopsTheTriggerLive() async throws {
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        await c.start()
        XCTAssertEqual(t.startCount, 0)

        try await c.setEnabled(.session, true)
        XCTAssertEqual(t.startCount, 1)
        XCTAssertTrue(try settings.isTriggerEnabled(.session), "the choice must persist")

        try await c.setEnabled(.session, false)
        XCTAssertEqual(t.stopCount, 1)
        t.emit()
        XCTAssertEqual(try store.eventCount(kind: .session), 0, "a stopped trigger writes nothing")
    }

    func testStopStopsOnlyTheTriggersItStarted() async throws {
        try settings.setTriggerEnabled(.session, true)
        let running = FakeContextTrigger(kind: .session)
        let idle = FakeContextTrigger(kind: .power)
        let c = makeCollector([running, idle])
        await c.start()
        c.stop()
        XCTAssertEqual(running.stopCount, 1)
        XCTAssertEqual(idle.stopCount, 0)
    }

    func testATriggerThatFailsToStartDoesNotPreventTheOthers() async throws {
        struct Boom: Error {}
        try settings.setTriggerEnabled(.session, true)
        try settings.setTriggerEnabled(.power, true)
        let bad = FakeContextTrigger(kind: .session)
        bad.startError = Boom()
        let good = FakeContextTrigger(kind: .power)
        let c = makeCollector([bad, good])
        await c.start()
        XCTAssertEqual(good.startCount, 1)
        good.emit()
        XCTAssertEqual(try store.eventCount(kind: .power), 1)

        bad.emit()   // bad never started — its events must not be recorded either
        XCTAssertEqual(try store.eventCount(kind: .session), 0)
    }

    func testStatesReportEnablementPermissionAndRunning() async throws {
        try settings.setTriggerEnabled(.session, true)
        try settings.setTriggerEnabled(.location, true)
        let session = FakeContextTrigger(kind: .session)
        let location = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let c = makeCollector([session, location],
                              gate: FakePermissionGate(statuses: [.location: .denied]))
        await c.start()

        let states = await c.states()
        let byKind = Dictionary(uniqueKeysWithValues: states.map { ($0.kind, $0) })
        XCTAssertEqual(byKind[.session]?.isRunning, true)
        XCTAssertEqual(byKind[.session]?.permission, ContextPermission.none)
        XCTAssertEqual(byKind[.location]?.isEnabled, true)
        XCTAssertEqual(byKind[.location]?.isRunning, false)
        XCTAssertEqual(byKind[.location]?.permissionState, ContextPermissionState.denied)
    }

    func testStartIsIdempotentAndDoesNotDoubleAttachARunningTrigger() async throws {
        // Nothing exercised this before: removing the already-running guard
        // would double-attach every real observer and duplicate every event,
        // and the suite would stay green.
        try settings.setTriggerEnabled(.session, true)
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        await c.start()
        await c.start()
        XCTAssertEqual(t.startCount, 1)
    }

    func testSetEnabledIsIdempotentAndDoesNotDoubleAttachARunningTrigger() async throws {
        let t = FakeContextTrigger(kind: .session)
        let c = makeCollector([t])
        try await c.setEnabled(.session, true)
        try await c.setEnabled(.session, true)
        XCTAssertEqual(t.startCount, 1)
    }

    func testRefreshStopsATriggerWhosePermissionWasRevoked() async throws {
        try settings.setTriggerEnabled(.location, true)
        let t = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let gate = MutableFakePermissionGate(statuses: [.location: .granted])
        let c = makeCollector([t], gate: gate)
        await c.start()
        XCTAssertEqual(t.startCount, 1)

        gate.set(.location, .denied)
        await c.refresh()
        XCTAssertEqual(t.stopCount, 1)

        t.emit()
        XCTAssertEqual(try store.eventCount(kind: .location), 0, "a revoked-permission trigger writes nothing")
    }

    /// The consent half of the dual gate has to survive the same suspension
    /// the shutdown half already survives. `startIfAllowed` reads the opt-in,
    /// then suspends at `await gate.status(...)` — and that suspension
    /// releases the main actor, so the settings panel's `setEnabled(kind,
    /// false)` can run to completion inside it. The trigger is not in
    /// `running` yet, so the disable path finds nothing to stop; unless the
    /// resumed start re-reads the opt-in, it starts a trigger the owner has
    /// just switched off and records with it until the next refresh tick.
    func testAnOptOutThatLandsDuringThePermissionCheckStopsTheStart() async throws {
        try settings.setTriggerEnabled(.location, true)
        let t = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let gate = SuspendingPermissionGate()
        let c = makeCollector([t], gate: gate)

        let starting = Task { await c.start() }
        await gate.waitUntilAsked()

        // The owner unticks the box while the collector is parked mid-start.
        try await c.setEnabled(.location, false)

        await gate.answer(.granted)
        await starting.value

        XCTAssertEqual(t.startCount, 0, "a trigger switched off mid-start must not start")
        t.emit()
        XCTAssertEqual(try store.eventCount(kind: .location), 0,
                       "a trigger switched off mid-start must not record")
    }

    func testATriggerThatNeverStartedWritesNothingEvenWhenASiblingSharesItsKind() async throws {
        // This is the test that would have caught the `Set<ContextEventKind>`
        // bug directly: two triggers share `.session` (and therefore its one
        // opt-in), but only one of them actually starts.
        try settings.setTriggerEnabled(.session, true)
        let started = FakeContextTrigger(kind: .session)
        let neverStarted = FakeContextTrigger(kind: .session)
        struct Boom: Error {}
        neverStarted.startError = Boom()
        let c = makeCollector([started, neverStarted])
        await c.start()
        XCTAssertEqual(started.startCount, 1)
        XCTAssertEqual(neverStarted.startCount, 0)

        started.emit()
        neverStarted.emit()
        XCTAssertEqual(try store.eventCount(kind: .session), 1, "only the trigger that actually started may write")
    }

    /// The dual gate keys on each trigger's OWN required permission and
    /// nothing else: a denial the user gave for Location or Accessibility must
    /// not reach the four permission-free triggers (session, power, network,
    /// input), which would otherwise never start.
    ///
    /// The real gate's half of this contract — `.none` is granted without
    /// consulting the system — is `MacPermissionGateTests
    /// .testNoneIsAlwaysGrantedWithoutConsultingTheSystem`.
    func testADenialForOnePermissionDoesNotBlockAPermissionFreeTrigger() async throws {
        try settings.setTriggerEnabled(.session, true)
        try settings.setTriggerEnabled(.location, true)
        let session = FakeContextTrigger(kind: .session)
        let location = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let c = makeCollector([session, location],
                              gate: FakePermissionGate(statuses: [.location: .denied,
                                                                  .accessibility: .denied]))

        await c.start()

        XCTAssertEqual(session.startCount, 1, "a permission-free trigger runs regardless")
        XCTAssertEqual(location.startCount, 0, "the denial binds only the trigger that needs it")
        session.emit()
        XCTAssertEqual(try store.eventCount(kind: .session), 1)
    }

    // MARK: - requestPermission (I-4)

    /// The consent check. A permission request puts a system dialog on the
    /// user's screen, once, forever — so a client must not be able to raise
    /// one for capture nobody switched on.
    func testRefusesToAskForAPermissionNoOptedInTriggerNeeds() async {
        let t = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let gate = MutableFakePermissionGate(statuses: [.location: .undetermined])
        let c = makeCollector([t], gate: gate)

        let result = await c.requestPermission(.location)
        XCTAssertEqual(result, .notNeeded)
        XCTAssertEqual(gate.requestedPermissions, [], "the OS must not be asked at all")
    }

    /// The opt-in is per kind, and only the kind that needs THIS permission
    /// unlocks it — an enabled `session` trigger must not license a Location
    /// prompt.
    func testAnOptInForAnUnrelatedTriggerDoesNotUnlockAPermission() async throws {
        try settings.setTriggerEnabled(.session, true)
        let session = FakeContextTrigger(kind: .session)
        let location = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let gate = MutableFakePermissionGate(statuses: [.location: .undetermined])
        let c = makeCollector([session, location], gate: gate)

        let result = await c.requestPermission(.location)
        XCTAssertEqual(result, .notNeeded)
        XCTAssertEqual(gate.requestedPermissions, [])
    }

    func testAsksTheOSOnceTheUserHasOptedIntoATriggerThatNeedsIt() async throws {
        try settings.setTriggerEnabled(.location, true)
        let t = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let gate = MutableFakePermissionGate(statuses: [.location: .undetermined])
        gate.answersRequest(.location, with: .denied)
        let c = makeCollector([t], gate: gate)

        let result = await c.requestPermission(.location)
        XCTAssertEqual(gate.requestedPermissions, [.location])
        XCTAssertEqual(result, .denied, "the user's actual answer, not the pre-prompt status")
    }

    /// A grant has to take effect now. Without the `refresh()` inside
    /// `requestPermission`, a trigger the user just authorized sits idle until
    /// the daemon's 30-second tick — long enough to read as "the button did
    /// nothing".
    func testAGrantStartsTheTriggerItWasBlocking() async throws {
        try settings.setTriggerEnabled(.location, true)
        let t = FakeContextTrigger(kind: .location, requiredPermission: .location)
        let gate = MutableFakePermissionGate(statuses: [.location: .undetermined])
        let c = makeCollector([t], gate: gate)
        await c.start()
        XCTAssertEqual(t.startCount, 0, "blocked on the permission")

        gate.answersRequest(.location, with: .granted)
        let result = await c.requestPermission(.location)
        XCTAssertEqual(result, .granted)
        XCTAssertEqual(t.startCount, 1, "the newly-granted trigger must start immediately")

        t.emit()
        XCTAssertEqual(try store.eventCount(kind: .location), 1)
    }

    /// `.none` is not a permission anything can be asked for; answering
    /// `.notNeeded` would make the five permission-free triggers look broken.
    func testTheNonePermissionIsGrantedWithoutAskingTheOS() async {
        let gate = MutableFakePermissionGate(statuses: [:])
        let c = makeCollector([FakeContextTrigger(kind: .session)], gate: gate)

        let result = await c.requestPermission(.none)
        XCTAssertEqual(result, .granted)
        XCTAssertEqual(gate.requestedPermissions, [])
    }
}
#endif
