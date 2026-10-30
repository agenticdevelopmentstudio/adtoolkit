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

    private func row(_ event: String, at time: String, directory: String = "/tmp/project",
                     session: String = "claude-1") -> AdkdSessionActivity {
        AdkdSessionActivity(sessionID: session, directory: directory, lastEventType: event, lastActivityAt: time)
    }

    func testWatchingSchedulesAFiveSecondPoll() {
        detector.watch(makeDetachedPartnerSession())
        XCTAssertEqual(scheduler.lastDelay, 5)
    }

    func testANewStopRowIsOneIdleAndTheSameRowAgainIsNone() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        source.rows = [row("PreToolUse", at: "2026-10-30 10:00:00")]
        await detector.poll()
        XCTAssertEqual(idles, [])

        source.rows = [row("Stop", at: "2026-10-30 10:00:05")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id])

        await detector.poll()
        XCTAssertEqual(idles, [session.id], "the same Stop row is not a new turn")

        source.rows = [row("Stop", at: "2026-10-30 10:01:00")]
        await detector.poll()
        XCTAssertEqual(idles, [session.id, session.id], "a later Stop is")
    }

    func testAStopAlreadyOnRecordAtWatchIsThePast() async {
        source.rows = [row("Stop", at: "2026-10-30 09:00:00")]
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        await detector.poll()
        XCTAssertEqual(idles, [])
    }

    func testAStopInAnotherDirectoryIsNotThisSession() async {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        await detector.poll()
        source.rows = [row("Stop", at: "2026-10-30 10:00:05", directory: "/tmp/elsewhere")]
        await detector.poll()
        XCTAssertEqual(idles, [])
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
