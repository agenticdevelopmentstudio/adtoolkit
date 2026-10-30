import Combine
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

private final class FakeActivitySource: AdkdSessionActivitySource, @unchecked Sendable {
    private let lock = NSLock()
    private var _rows: [AdkdSessionActivity]? = []
    var rows: [AdkdSessionActivity]? {
        get { lock.withLock { _rows } }
        set { lock.withLock { _rows = newValue } }
    }
    func recentSessions() async -> [AdkdSessionActivity]? { rows }
}

@MainActor
final class AdkdStopEventDetectorTests: XCTestCase {

    private var source: FakeActivitySource!
    private var scheduler: FakeTimerScheduler!
    private var detector: AdkdStopEventDetector!
    private var idles: [UUID] = []
    private var exits: [UUID] = []

    override func setUp() async throws {
        source = FakeActivitySource()
        scheduler = FakeTimerScheduler()
        detector = AdkdStopEventDetector(source: source, scheduler: scheduler)
        idles = []
        exits = []
        detector.onIdle = { [unowned self] in idles.append($0) }
        detector.onExit = { [unowned self] in exits.append($0) }
    }

    private func row(_ event: String, at turnStateAt: String = "", directory: String = "/tmp/project",
                     pane: String = "", session: String = "claude-1") -> AdkdSessionActivity {
        AdkdSessionActivity(sessionID: session, directory: directory, termSessionID: pane,
                            lastEventType: event, turnStateAt: turnStateAt)
    }

    func testWatchingSchedulesAFiveSecondPoll() {
        detector.watch(makeDetachedPartnerSession())
        XCTAssertEqual(scheduler.lastDelay, 5)
    }

    func testEachPollSchedulesTheNextAndUnwatchingStopsThem() async throws {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        XCTAssertEqual(scheduler.pending, 1)
        scheduler.fireAll()
        for _ in 0..<100 where scheduler.pending == 0 {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(scheduler.pending, 1, "the poll re-arms itself")
        XCTAssertEqual(scheduler.lastDelay, 5)
        detector.unwatch(id: session.id)
        XCTAssertEqual(scheduler.pending, 0, "nothing left to watch, nothing left to poll")
    }

    func testATurnEndingIsOneIdleAndTheSameStateAgainIsNone() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        source.rows = [row("PreToolUse", at: "2026-10-30 10:00:00")]
        await detector.poll()
        XCTAssertEqual(idles, [])

        source.rows = [row("Stop", at: "2026-10-30 10:00:05")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])

        await detector.poll()
        XCTAssertEqual(idles, [session.id], "the same Stop is not a new turn")

        source.rows = [row("Stop", at: "2026-10-30 10:01:00")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id, session.id], "a Stop with a new turn clock is")
    }

    func testActivityAfterAStopWithoutANewTurnIsNoSecondIdle() async {
        // The idle-prompt Notification a minute after Stop advances
        // last_activity_at, never turn_state_at, so the row reads the same.
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        source.rows = [row("UserPromptSubmit", at: "2026-10-30 10:00:00")]
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05")]
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05")]
        await detector.poll()
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
    }

    func testWithoutATurnClockOnlyATransitionIntoStopCounts() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        source.rows = [row("PreToolUse")]
        await detector.poll()
        source.rows = [row("Stop")]
        await detector.poll()
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
        source.rows = [row("UserPromptSubmit")]
        await detector.poll()
        source.rows = [row("Stop")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id, session.id])
    }

    func testStopFailureEndsATurnToo() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        source.rows = [row("PreToolUse", at: "2026-10-30 10:00:00")]
        await detector.poll()
        source.rows = [row("StopFailure", at: "2026-10-30 10:00:05")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
    }

    func testAStopAlreadyOnRecordAtWatchIsThePast() async {
        source.rows = [row("Stop", at: "2026-10-30 09:00:00")]
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        await detector.poll()
        XCTAssertEqual(idles, [])
    }

    func testANewClaudeSessionAfterTheBaselineThatStopsIsAnIdle() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05", session: "claude-2")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
    }

    func testAStopInAnotherDirectoryIsNotThisSession() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05", directory: "/tmp/elsewhere")]
        await detector.poll()
        XCTAssertEqual(idles, [])
    }

    func testAnotherPaneInTheSameDirectoryIsNotThisSession() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05", pane: UUID().uuidString)]
        await detector.poll()
        XCTAssertEqual(idles, [], "a pane id that is not ours wins over a matching directory")
    }

    func testThisPaneIsMatchedByIdWhereverItsClaudeRuns() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05", directory: "/tmp/elsewhere",
                           pane: session.id.uuidString)]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
    }

    func testARowWithNoPaneIdFallsBackToTheDirectory() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05", pane: "")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
    }

    func testAnUnreadableDaemonChangesNothing() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = nil
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])
    }

    func testTerminatedIsOneExit() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.state = .terminated
        XCTAssertEqual(exits, [session.id])
    }
}
