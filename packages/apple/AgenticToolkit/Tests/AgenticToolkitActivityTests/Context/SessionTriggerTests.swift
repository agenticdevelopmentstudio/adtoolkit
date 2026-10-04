#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

@MainActor
private final class FakeLockSleepSource: SessionLockSleepSource {
    var onChange: ((SessionChange) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func emit(_ c: SessionChange) { onChange?(c) }
}

@MainActor
final class SessionTriggerTests: XCTestCase {
    private func makeTrigger()
    -> (SessionTrigger, FakeLockSleepSource, () -> [SessionChange]) {
        let lockSleep = FakeLockSleepSource()
        let t = SessionTrigger(lockSleep: lockSleep,
                               now: { Date(timeIntervalSince1970: 5_000) })
        let box = Recorder()
        t.onEvent = { d, _ in
            if case .session(let s) = d { box.changes.append(s.change) }
        }
        return (t, lockSleep, { box.changes })
    }

    private final class Recorder { var changes: [SessionChange] = [] }

    func testDeclaresItsKindAndNeedsNoPermission() {
        let (t, _, _) = makeTrigger()
        XCTAssertEqual(t.kind, ContextEventKind.session)
        XCTAssertEqual(t.requiredPermission, ContextPermission.none)
    }

    func testReportsLockUnlockSleepAndWakeSeparately() throws {
        // The existing PowerAdapter collapses unlock and wake into one
        // callback; these four must stay distinguishable in the data.
        let (t, lockSleep, changes) = makeTrigger()
        try t.start()
        for c in [SessionChange.lock, .unlock, .sleep, .wake] { lockSleep.emit(c) }
        XCTAssertEqual(changes(), [.lock, .unlock, .sleep, .wake])
    }

    func testDoesNotReportIdleOrActive() throws {
        // Absence is `InputActivityTrigger`'s to report, against the threshold
        // the user set. This trigger used to watch a second, hardcoded
        // 180-second idle timer as well, which wrote a duplicate absence
        // beside the configurable one — two rows for one departure, disagreeing
        // whenever the setting was not 180.
        let (t, lockSleep, changes) = makeTrigger()
        try t.start()
        for c in [SessionChange.lock, .unlock] { lockSleep.emit(c) }
        XCTAssertFalse(changes().contains(.idle))
        XCTAssertFalse(changes().contains(.active))
    }

    func testStartsAndStopsTheUnderlyingSource() throws {
        let (t, lockSleep, _) = makeTrigger()
        try t.start()
        XCTAssertEqual(lockSleep.startCount, 1)

        // A second start() must not re-install anything: a doubled
        // registration doubles every event.
        try t.start()
        XCTAssertEqual(lockSleep.startCount, 1)

        t.stop()
        XCTAssertEqual(lockSleep.stopCount, 1)
        XCTAssertNil(lockSleep.onChange, "stop() must detach, not merely stop")
    }

    func testStopEndsEmission() throws {
        let (t, lockSleep, changes) = makeTrigger()
        try t.start()
        lockSleep.emit(.lock)
        t.stop()
        lockSleep.emit(.unlock)
        XCTAssertEqual(changes(), [.lock])
    }

    /// A notification already dispatched when the owner switched the trigger
    /// off. As in `NetworkTriggerTests`, the test above cannot see the
    /// trigger's `isRunning` guard, because `stop()` clears `onChange` and
    /// the fake then has nothing to call. `NSWorkspace`'s notification centre
    /// does not recall a delivery that is already under way, so holding the
    /// closure across the stop is what reproduces it — and the guard is the
    /// only thing that keeps a lock the owner did not consent to recording
    /// out of the log.
    func testAChangeAlreadyInFlightWhenStoppedWritesNothing() throws {
        let (t, lockSleep, changes) = makeTrigger()
        try t.start()
        let inFlight = try XCTUnwrap(lockSleep.onChange, "start() must have subscribed")

        t.stop()
        inFlight(.unlock)

        XCTAssertEqual(changes(), [])
    }
}
#endif
