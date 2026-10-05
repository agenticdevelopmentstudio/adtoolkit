#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

@MainActor
private final class ScriptedInputSource: InputStatisticsSource {
    var samples: [InputSample] = []
    private var index = 0
    func sample() -> InputSample {
        defer { index = min(index + 1, samples.count - 1) }
        return samples[min(index, samples.count - 1)]
    }
}

/// Silence measured from a settable moment of last input against a shared clock.
@MainActor
private final class ClockedInputSource: InputStatisticsSource {
    var clock: InputActivityTriggerTests.Box?
    var lastInputAt: TimeInterval = 0
    func sample() -> InputSample {
        let silence = max(0, (clock?.now ?? 0) - lastInputAt)
        return InputSample(secondsSinceKey: silence, secondsSinceMouseMove: silence,
                           secondsSinceClick: silence, secondsSinceScroll: silence,
                           keyCount: 0, mouseCount: 0)
    }
}

@MainActor
final class InputActivityTriggerTests: XCTestCase {
    /// Every reading the same, so a test that only cares about presence says
    /// so in one number instead of four.
    private func quiet(for seconds: Double, keys: Int64 = 0, mice: Int64 = 0) -> InputSample {
        InputSample(secondsSinceKey: seconds, secondsSinceMouseMove: seconds,
                    secondsSinceClick: seconds, secondsSinceScroll: seconds,
                    keyCount: keys, mouseCount: mice)
    }

    private func trigger(_ samples: [InputSample],
                         threshold: TimeInterval = 180,
                         startAt t: TimeInterval = 0)
    -> (InputActivityTrigger, ScriptedInputSource, Box) {
        let source = ScriptedInputSource()
        source.samples = samples
        let clock = Box(now: t)
        let trig = InputActivityTrigger(interval: 10, idleThreshold: threshold,
                                        source: source, now: { clock.date })
        return (trig, source, clock)
    }

    final class Box { var now: TimeInterval; init(now: TimeInterval) { self.now = now }
                      var date: Date { Date(timeIntervalSince1970: now) } }

    func testRequiresNoPermission() {
        let (t, _, _) = trigger([quiet(for: 1)])
        XCTAssertEqual(t.requiredPermission, ContextPermission.none)
        XCTAssertEqual(t.kind, ContextEventKind.input)
    }

    // MARK: - The first reading of a run

    func testFirstTickWhilePresentReportsActivityWithNoDeltas() throws {
        let (t, _, _) = trigger([InputSample(secondsSinceKey: 2.5, secondsSinceMouseMove: 0.5,
                                             secondsSinceClick: 30, secondsSinceScroll: nil,
                                             keyCount: 100, mouseCount: 900)])
        var captured: [(ContextEventDetail, Date)] = []
        t.onEvent = { captured.append(($0, $1)) }
        try t.start()
        t.tick()

        XCTAssertEqual(captured.count, 1)
        guard case .input(let d) = captured[0].0 else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.change, .active)
        // Nothing was measured: the trigger did not witness this activity
        // start, it merely found it already happening.
        XCTAssertNil(d.idleSeconds)
        XCTAssertEqual(d.secondsSinceKey, 2.5)
        XCTAssertEqual(d.secondsSinceMouseMove, 0.5)
        XCTAssertEqual(d.secondsSinceClick, 30)
        XCTAssertNil(d.secondsSinceScroll)
        // No previous emitted row exists, so a "delta" would be a raw lifetime
        // counter masquerading as activity.
        XCTAssertNil(d.keyCountDelta)
        XCTAssertNil(d.mouseCountDelta)
        XCTAssertNil(d.intervalMs)
    }

    func testFirstTickWhileAlreadyQuietSaysHowLongAndIsNotBackdated() throws {
        let (t, _, _) = trigger([quiet(for: 600)], threshold: 180, startAt: 1_000)
        var captured: [(ContextEventDetail, Date)] = []
        t.onEvent = { captured.append(($0, $1)) }
        try t.start()
        t.tick()

        XCTAssertEqual(captured.count, 1)
        guard case .input(let d) = captured[0].0 else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.change, .inactive)
        XCTAssertEqual(d.idleSeconds, 600)
        // Dated now, not 600 seconds ago: the silence predates this run, and a
        // row placed before the trigger started would claim to have watched
        // something nobody watched.
        XCTAssertEqual(captured[0].1, Date(timeIntervalSince1970: 1_000))
    }

    // MARK: - Transitions, and only transitions

    func testTicksWithNoChangeEmitNothing() throws {
        let (t, _, clock) = trigger([quiet(for: 1), quiet(for: 2), quiet(for: 3)])
        var count = 0
        t.onEvent = { _, _ in count += 1 }
        try t.start()
        t.tick()
        clock.now = 10
        t.tick()
        clock.now = 20
        t.tick()
        // One row for the state it found, then silence — the whole point of
        // the redesign. The polling version wrote three.
        XCTAssertEqual(count, 1)
    }

    func testInactivityIsBackdatedToTheMomentInputStopped() throws {
        let (t, _, clock) = trigger([quiet(for: 1), quiet(for: 240)], threshold: 180)
        var captured: [(ContextEventDetail, Date)] = []
        t.onEvent = { captured.append(($0, $1)) }
        try t.start()
        t.tick()
        clock.now = 300
        t.tick()

        XCTAssertEqual(captured.count, 2)
        guard case .input(let d) = captured[1].0 else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.change, .inactive)
        // Noticed at 300 with 240 seconds of silence behind it, so input
        // stopped at 60. Dating the row at 300 would lose four minutes of
        // every absence — the under-measurement `TimelineBuilder` used to
        // document and accept.
        XCTAssertEqual(captured[1].1, Date(timeIntervalSince1970: 60))
        // The row marks where activity stopped; how long the absence lasted is
        // the resuming row's to report, because only it knows.
        XCTAssertNil(d.idleSeconds)
    }

    func testResumptionMeasuresTheWholeAbsenceNotThePolledPart() throws {
        let (t, _, clock) = trigger([quiet(for: 1), quiet(for: 240), quiet(for: 5)],
                                    threshold: 180)
        var captured: [(ContextEventDetail, Date)] = []
        t.onEvent = { captured.append(($0, $1)) }
        try t.start()
        t.tick()          // active, t=0
        clock.now = 300
        t.tick()          // inactive, backdated to t=60
        clock.now = 1_000
        t.tick()          // active, backdated to t=995

        XCTAssertEqual(captured.count, 3)
        guard case .input(let d) = captured[2].0 else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.change, .active)
        XCTAssertEqual(captured[2].1, Date(timeIntervalSince1970: 995))
        // 995 − 60. Not 815 (the poll's view of it), and not 700 (the gap
        // between the two ticks that noticed).
        XCTAssertEqual(try XCTUnwrap(d.idleSeconds), 935, accuracy: 0.001)
    }

    func testAReturnIsDatedAtTheFirstInputEvenWhenTypingNeverStops() throws {
        // The user is away, comes back at t=1000 and types straight through, so
        // every reading after the return shows (almost) no silence. The trigger
        // is driven at whatever cadence it asks for; the resumption must land
        // within that cadence of the real return, not one presence interval late.
        let source = ClockedInputSource()
        let clock = Box(now: 0)
        source.clock = clock
        source.lastInputAt = -900
        let t = InputActivityTrigger(interval: 30, awayInterval: 1, idleThreshold: 180,
                                     source: source, now: { clock.date })
        var captured: [(ContextEventDetail, Date)] = []
        t.onEvent = { captured.append(($0, $1)) }
        try t.start()
        defer { t.stop() }
        t.tick()                                       // inactive, found at t=0
        XCTAssertEqual(t.pollInterval, 1, "away, so polling fast")
        while captured.count < 2, clock.now < 2_000 {
            clock.now += t.pollInterval
            if clock.now >= 1_000 { source.lastInputAt = clock.now }   // typing continuously
            t.tick()
        }
        XCTAssertEqual(captured.count, 2)
        guard case .input(let d) = captured[1].0 else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.change, .active)
        XCTAssertLessThanOrEqual(captured[1].1.timeIntervalSince1970, 1_001,
                                 "the return was dated a whole poll interval late")
        XCTAssertEqual(t.pollInterval, 30, "back to the presence cadence once the user is here")
    }

    func testInputOfAnyKindCountsAsPresence() throws {
        // A long drag or a right click moves none of the four named readings.
        let (t, _, _) = trigger([InputSample(secondsSinceKey: 900, secondsSinceMouseMove: 900,
                                             secondsSinceClick: 900, secondsSinceScroll: 900,
                                             keyCount: 0, mouseCount: 0, secondsSinceAnyInput: 2)],
                                threshold: 180)
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        t.tick()
        guard case .input(let d) = captured[0] else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.change, .active)
        XCTAssertEqual(t.samplePresence(), true)
    }

    func testThresholdAppliesAtTheNextTickWithoutRestarting() throws {
        let (t, _, clock) = trigger([quiet(for: 100), quiet(for: 100)], threshold: 180)
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        t.tick()

        // Same silence, lower bar: the user is now absent without the source
        // reporting anything new, and without the trigger being stopped — a
        // restart would drop the opt-in and lose the presence state.
        t.idleThreshold = 60
        clock.now = 10
        t.tick()

        XCTAssertEqual(captured.count, 2)
        guard case .input(let first) = captured[0], case .input(let second) = captured[1] else {
            return XCTFail("wrong detail kind")
        }
        XCTAssertEqual(first.change, .active)
        XCTAssertEqual(second.change, .inactive)
    }

    func testNoReadingsAtAllCountsAsAbsenceNotPresence() throws {
        let (t, _, _) = trigger([InputSample(secondsSinceKey: nil, secondsSinceMouseMove: nil,
                                             secondsSinceClick: nil, secondsSinceScroll: nil,
                                             keyCount: nil, mouseCount: nil)])
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        t.tick()

        guard case .input(let d) = captured[0] else { return XCTFail("wrong detail kind") }
        // A source that tells us nothing must not be able to assert that
        // somebody is present.
        XCTAssertEqual(d.change, .inactive)
    }

    // MARK: - Counters

    func testDeltasAreMeasuredBetweenEmittedRowsNotTicks() throws {
        let (t, _, clock) = trigger([
            quiet(for: 1, keys: 100, mice: 900),      // emitted: active at t=0
            quiet(for: 2, keys: 120, mice: 1_000),    // no change, emits nothing
            quiet(for: 240, keys: 137, mice: 1_400)   // emitted: inactive
        ], threshold: 180)
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        t.tick()
        clock.now = 10
        t.tick()
        clock.now = 300
        t.tick()

        XCTAssertEqual(captured.count, 2)
        guard case .input(let d) = captured[1] else { return XCTFail("wrong detail kind") }
        // Against the last row written (t=0), not the last tick taken (t=10):
        // most ticks write nothing, and a delta against one of those would
        // silently drop the activity in between.
        XCTAssertEqual(d.keyCountDelta, 37)
        XCTAssertEqual(d.mouseCountDelta, 500)
        // The row is backdated to t=60, so the interval it spans is 60s.
        XCTAssertEqual(d.intervalMs, 60_000)
    }

    func testCounterResetIsReportedAsZeroNotNegative() throws {
        // The counters reset when the window server restarts; a negative
        // "delta" would read as impossible activity in the data.
        let (t, _, clock) = trigger([
            quiet(for: 1, keys: 500, mice: 500),
            quiet(for: 240, keys: 3, mice: 2)
        ], threshold: 180)
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        t.tick()
        clock.now = 300
        t.tick()
        guard case .input(let d) = captured[1] else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(d.keyCountDelta, 0)
        XCTAssertEqual(d.mouseCountDelta, 0)
    }

    func testStopEndsEmission() throws {
        let (t, _, clock) = trigger([quiet(for: 1), quiet(for: 240)], threshold: 180)
        var count = 0
        t.onEvent = { _, _ in count += 1 }
        try t.start()
        t.tick()
        t.stop()
        clock.now = 300
        t.tick()
        XCTAssertEqual(count, 1)
    }

    func testRestartReportsTheStateItFindsRatherThanAStaleTransition() throws {
        let (t, _, clock) = trigger([quiet(for: 1), quiet(for: 2)])
        var captured: [ContextEventDetail] = []
        t.onEvent = { d, _ in captured.append(d) }
        try t.start()
        t.tick()
        t.stop()
        try t.start()
        clock.now = 10
        t.tick()

        // Two `active` rows in a row, which is correct: a restart is a new
        // run, and the second row is that run's "here is what I found", not a
        // transition claiming input resumed.
        XCTAssertEqual(captured.count, 2)
        guard case .input(let second) = captured[1] else { return XCTFail("wrong detail kind") }
        XCTAssertEqual(second.change, .active)
        // The previous run's counters are gone too, so nothing is measured
        // across the gap the trigger was not watching.
        XCTAssertNil(second.keyCountDelta)
        XCTAssertNil(second.intervalMs)
    }

    func testSystemSourceReadsRealCounters() throws {
        // The only test that touches the real CGEventSource API. It cannot
        // assert particular values — they depend on what the machine's user is
        // doing — so it asserts the invariants the API guarantees instead.
        //
        // Every field is widened from a non-optional CFTimeInterval/UInt32, so
        // nil is unreachable here and an assertion about nil could never fail.
        // `XCTUnwrap` therefore carries no weight of its own; it is only how
        // the value stops being optional, so that what follows is asserted
        // about the reading itself rather than about a `?? -1` fallback that
        // would keep the test green either way.
        let source = SystemInputStatisticsSource()
        let first = source.sample()

        for (name, seconds) in [("key", first.secondsSinceKey),
                                ("mouse move", first.secondsSinceMouseMove),
                                ("click", first.secondsSinceClick),
                                ("scroll", first.secondsSinceScroll),
                                ("any input", first.secondsSinceAnyInput)] {
            let value = try XCTUnwrap(seconds, "\(name) idle time")
            XCTAssertGreaterThanOrEqual(value, 0, "\(name) idle time cannot run backwards")
            XCTAssertTrue(value.isFinite, "\(name) idle time must be a real reading")
            // The machine has not been idle since before CGEventSource existed:
            // this catches an uninitialised or sentinel reading, which the
            // bounds above would let through.
            XCTAssertLessThan(value, 60 * 60 * 24 * 365,
                              "\(name) idle time of \(value)s is not a reading, it is a sentinel")
        }

        // Monotonic lifetime counters: a second reading can only be >= the
        // first. This is what catches a stubbed or wrongly-wired source, which
        // a nil-check cannot.
        let second = source.sample()
        XCTAssertGreaterThanOrEqual(second.keyCount ?? -1, first.keyCount ?? 0)
        XCTAssertGreaterThanOrEqual(second.mouseCount ?? -1, first.mouseCount ?? 0)
    }
}
#endif
