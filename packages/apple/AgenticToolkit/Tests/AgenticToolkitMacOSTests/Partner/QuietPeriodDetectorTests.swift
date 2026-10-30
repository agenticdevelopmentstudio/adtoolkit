import Combine
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Records what was scheduled and fires it when the test says.
@MainActor
final class FakeTimerScheduler: TimerScheduling {

    private final class Entry {
        let delay: TimeInterval
        let body: @MainActor () -> Void
        var cancelled = false
        init(delay: TimeInterval, body: @escaping @MainActor () -> Void) {
            self.delay = delay
            self.body = body
        }
    }

    private var entries: [Entry] = []

    var pending: Int { entries.filter { !$0.cancelled }.count }
    var lastDelay: TimeInterval? { entries.last { !$0.cancelled }?.delay }

    func schedule(after seconds: TimeInterval, _ body: @escaping @MainActor () -> Void) -> AnyCancellable {
        let entry = Entry(delay: seconds, body: body)
        entries.append(entry)
        return AnyCancellable { entry.cancelled = true }
    }

    /// Fires every timer not cancelled, once.
    func fireAll() {
        let due = entries.filter { !$0.cancelled }
        entries.removeAll()
        for entry in due { entry.body() }
    }
}

/// Builds a `PartnerSession` around a terminal whose shell never starts, so
/// output and exit can be driven by hand.
@MainActor
func makeDetachedPartnerSession(directory: String = "/tmp/project") -> PartnerSession {
    let manager = TerminalSessionManager(workingDirectory: directory)
    let terminal = TerminalSession(name: "test", workingDirectory: directory, isPrivate: true)
    let chat = TerminalChatSession()
    let viewController = TerminalSessionContentViewController(sessionManager: manager)
    return PartnerSession(id: UUID(), title: "test", directory: directory, manager: manager, terminal: terminal,
                          chat: chat, viewController: viewController, now: Date.init)
}

@MainActor
final class QuietPeriodDetectorTests: XCTestCase {

    private var scheduler: FakeTimerScheduler!
    private var detector: QuietPeriodDetector!
    private var idles: [UUID] = []
    private var exits: [UUID] = []

    override func setUp() async throws {
        scheduler = FakeTimerScheduler()
        detector = QuietPeriodDetector(settle: { 60 }, scheduler: scheduler)
        idles = []
        exits = []
        detector.onIdle = { [unowned self] in idles.append($0) }
        detector.onExit = { [unowned self] in exits.append($0) }
    }

    func testActivityThenSettleIsOneIdle() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        XCTAssertEqual(scheduler.lastDelay, 60)
        scheduler.fireAll()
        XCTAssertEqual(idles, [session.id])
    }

    func testTwoActivitiesThenSettleIsOneIdle() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        session.terminal.outputActivity.send()
        XCTAssertEqual(scheduler.pending, 1, "each burst reschedules rather than adding a timer")
        scheduler.fireAll()
        XCTAssertEqual(idles, [session.id])
    }

    func testNoActivityAfterTheLastIdleFiresNothing() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        scheduler.fireAll()
        scheduler.fireAll()
        XCTAssertEqual(idles, [session.id])
    }

    func testTerminatedIsOneExit() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.state = .terminated
        session.terminal.state = .terminated
        XCTAssertEqual(exits, [session.id])
    }

    func testUnwatchedSessionReportsNothing() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        detector.unwatch(id: session.id)
        scheduler.fireAll()
        session.terminal.state = .terminated
        XCTAssertEqual(idles, [])
        XCTAssertEqual(exits, [])
    }
}
