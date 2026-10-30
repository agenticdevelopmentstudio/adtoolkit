import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// A detector the test fires by hand.
@MainActor
final class ManualSessionEventDetector: PartnerSessionEventDetecting {
    var onIdle: ((UUID) -> Void)?
    var onExit: ((UUID) -> Void)?
    private(set) var watched: Set<UUID> = []
    func watch(_ session: PartnerSession) { watched.insert(session.id) }
    func unwatch(id: UUID) { watched.remove(id) }
}

@MainActor
final class CombinedSessionEventDetectorTests: XCTestCase {

    private var primary: ManualSessionEventDetector!
    private var fallback: ManualSessionEventDetector!
    private var clock = Date(timeIntervalSince1970: 1_000_000)
    private var detector: CombinedSessionEventDetector!
    private var idles: [UUID] = []
    private var exits: [UUID] = []

    override func setUp() async throws {
        primary = ManualSessionEventDetector()
        fallback = ManualSessionEventDetector()
        detector = CombinedSessionEventDetector(primary: primary, fallback: fallback,
                                                now: { [unowned self] in clock })
        idles = []
        exits = []
        detector.onIdle = { [unowned self] in idles.append($0) }
        detector.onExit = { [unowned self] in exits.append($0) }
    }

    func testWatchAndUnwatchReachBoth() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        XCTAssertEqual(primary.watched, [session.id])
        XCTAssertEqual(fallback.watched, [session.id])
        detector.unwatch(id: session.id)
        XCTAssertEqual(primary.watched, [])
        XCTAssertEqual(fallback.watched, [])
    }

    func testBothFiringIsOneIdle() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        primary.onIdle?(session.id)
        fallback.onIdle?(session.id)
        XCTAssertEqual(idles, [session.id])
    }

    func testActivityThenFallbackIsOneMore() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        primary.onIdle?(session.id)
        clock += 30
        session.terminal.outputActivity.send()
        fallback.onIdle?(session.id)
        XCTAssertEqual(idles, [session.id, session.id])
    }

    func testOutputRightAfterAnIdleDoesNotRearm() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        primary.onIdle?(session.id)
        clock += 0.5
        session.terminal.outputActivity.send()  // the prompt settling after Stop
        clock += 60
        fallback.onIdle?(session.id)
        XCTAssertEqual(idles, [session.id])
    }

    func testOneExitPerSession() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        primary.onExit?(session.id)
        fallback.onExit?(session.id)
        XCTAssertEqual(exits, [session.id])
    }

    func testConstructibleAsTheAppWill() {
        _ = CombinedSessionEventDetector(
            primary: AdkdStopEventDetector(source: DaemonSessionActivitySource(service: StubDaemonService())),
            fallback: QuietPeriodDetector(settle: { 60 }))
    }
}
