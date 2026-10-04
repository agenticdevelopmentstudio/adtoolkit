import XCTest
@testable import AgenticToolkitActivity

final class ActivitySpanBuilderTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_000), t1 = Date(timeIntervalSince1970: 1_060)
    let xcodeApp = SpanAttribution(bundleId: "x", appName: "Xcode", windowTitle: "a.swift",
                                   workingPath: "/r/a.swift", repoRoot: "/r", branch: "main")

    func testFirstFocusOpens() {
        var b = ActivitySpanBuilder()
        XCTAssertEqual(b.focus(xcodeApp, at: t0), [.open(xcodeApp, at: t0)])
    }
    func testSameRepoDifferentFileKeepsSpan() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        let other = SpanAttribution(bundleId: "x", appName: "Xcode", windowTitle: "b.swift",
                                    workingPath: "/r/b.swift", repoRoot: "/r", branch: "main")
        XCTAssertEqual(b.focus(other, at: t1), [.retitle("b.swift")])
    }
    func testBranchChangeSplits() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        let dev = SpanAttribution(bundleId: "x", appName: "Xcode", workingPath: "/r/a.swift", repoRoot: "/r", branch: "dev")
        XCTAssertEqual(b.focus(dev, at: t1), [.close(at: t1), .open(dev, at: t1)])
    }
    func testAppSwitchSplits() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        let term = SpanAttribution(bundleId: "t", appName: "Terminal", workingPath: "/r", repoRoot: "/r", branch: "main")
        XCTAssertEqual(b.focus(term, at: t1), [.close(at: t1), .open(term, at: t1)])
    }
    func testNonAllowedAppCloses() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        XCTAssertEqual(b.focus(nil, at: t1), [.close(at: t1)])
        XCTAssertEqual(b.focus(nil, at: t1), [])
    }
    func testQuitClosesOnlyItsOwnSpan() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        XCTAssertEqual(b.appTerminated(bundleId: "other", at: t1), [])
        XCTAssertEqual(b.appTerminated(bundleId: "x", at: t1), [.close(at: t1)])
    }
    func testLockClosesAndUnlockReopensOnTheLastFocus() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        XCTAssertEqual(b.suspend(.locked, at: t1), [.close(at: t1)])
        let t2 = Date(timeIntervalSince1970: 2_000)
        XCTAssertEqual(b.resume(.locked, at: t2), [.open(xcodeApp, at: t2)])
    }
    func testWakeWhileStillLockedDoesNotReopen() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0)
        _ = b.suspend(.locked, at: t1); _ = b.suspend(.asleep, at: t1)
        XCTAssertEqual(b.resume(.asleep, at: t1), [])
        XCTAssertEqual(b.resume(.locked, at: t1), [.open(xcodeApp, at: t1)])
    }
    func testFocusWhileLockedIsRememberedNotOpened() {
        var b = ActivitySpanBuilder(); _ = b.suspend(.locked, at: t0)
        XCTAssertEqual(b.focus(xcodeApp, at: t0), [])
        XCTAssertEqual(b.resume(.locked, at: t1), [.open(xcodeApp, at: t1)])
    }
    func testQuitWhileLockedForgetsTheFocus() {
        var b = ActivitySpanBuilder(); _ = b.focus(xcodeApp, at: t0); _ = b.suspend(.locked, at: t1)
        _ = b.appTerminated(bundleId: "x", at: t1)
        XCTAssertEqual(b.resume(.locked, at: t1), [])
    }
    func testNoRepoKeysByPath() {
        var b = ActivitySpanBuilder()
        let a = SpanAttribution(bundleId: "t", appName: "T", workingPath: "/tmp/a")
        let c = SpanAttribution(bundleId: "t", appName: "T", workingPath: "/tmp/c")
        _ = b.focus(a, at: t0)
        XCTAssertEqual(b.focus(c, at: t1), [.close(at: t1), .open(c, at: t1)])
    }
}
