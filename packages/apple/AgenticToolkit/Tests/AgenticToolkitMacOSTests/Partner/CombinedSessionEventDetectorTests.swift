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
    private var detector: CombinedSessionEventDetector!
    private var idles: [UUID] = []
    private var exits: [UUID] = []

    override func setUp() async throws {
        primary = ManualSessionEventDetector()
        fallback = ManualSessionEventDetector()
        detector = CombinedSessionEventDetector(primary: primary, fallback: fallback)
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

    func testNothingIsForwardedBeforeAnyInput() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.outputActivity.send()
        primary.onIdle?(session.id)
        XCTAssertEqual(idles, [])
    }

    func testBothFiringIsOneIdle() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.inputActivity.send()
        primary.onIdle?(session.id)
        fallback.onIdle?(session.id)
        XCTAssertEqual(idles, [session.id])
    }

    func testOutputAfterAnIdleIsNoSecondIdle() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.inputActivity.send()
        primary.onIdle?(session.id)
        session.terminal.outputActivity.send()  // Claude Code trickling at its prompt
        fallback.onIdle?(session.id)
        XCTAssertEqual(idles, [session.id])
    }

    func testInputThenIdleIsOneMore() {
        let session = makeDetachedPartnerSession()
        detector.watch(session)
        session.terminal.inputActivity.send()
        primary.onIdle?(session.id)
        session.terminal.inputActivity.send()
        fallback.onIdle?(session.id)
        XCTAssertEqual(idles, [session.id, session.id])
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
