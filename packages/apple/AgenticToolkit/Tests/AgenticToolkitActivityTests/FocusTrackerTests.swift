import XCTest
@testable import AgenticToolkitActivity

final class FocusTrackerTests: XCTestCase {
    private func focus(_ bundle: String, win: UInt32, title: String) -> WindowFocus {
        WindowFocus(app: AppInfo(bundleID: bundle, name: bundle, pid: 1), windowID: win, title: title, documentPath: nil)
    }
    private var t0: Date { Date(timeIntervalSince1970: 0) }

    func test_first_focus_opens_no_close() {
        let tr = FocusTracker()
        XCTAssertNil(tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0))
        XCTAssertNotNil(tr.current)
    }

    func test_app_change_closes_with_focus_change() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        let closed = tr.handle(.focus(focus("B", win: 2, title: "y")), now: t0.addingTimeInterval(5))
        XCTAssertEqual(closed?.endReason, .focusChange)
        XCTAssertEqual(closed?.durationMs, 5000)
    }

    func test_same_window_title_change_closes_with_title_change() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        let closed = tr.handle(.focus(focus("A", win: 1, title: "z")), now: t0.addingTimeInterval(1))
        XCTAssertEqual(closed?.endReason, .titleChange)
    }

    func test_identical_focus_is_deduped() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        XCTAssertNil(tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0.addingTimeInterval(1)))
    }

    func test_idle_closes_and_no_reopen() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        XCTAssertEqual(tr.handle(.idle, now: t0.addingTimeInterval(3))?.endReason, .idle)
        XCTAssertNil(tr.current)
    }

    func test_appQuit_only_closes_matching_pid() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(WindowFocus(app: AppInfo(bundleID: "A", name: "A", pid: 42),
            windowID: 1, title: "x", documentPath: nil)), now: t0)
        XCTAssertNil(tr.handle(.appQuit(pid: 99), now: t0))
        XCTAssertEqual(tr.handle(.appQuit(pid: 42), now: t0)?.endReason, .appQuit)
    }

    func test_stop_closes_with_collectorStop() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        XCTAssertEqual(tr.stop(now: t0.addingTimeInterval(9))?.endReason, .collectorStop)
    }

    func test_documentPath_only_change_closes_with_focus_change() {
        // Same app/window/title, only documentPath differs → title unchanged → .focusChange (NOT .titleChange).
        let tr = FocusTracker()
        let a = WindowFocus(app: AppInfo(bundleID: "A", name: "A", pid: 1), windowID: 1, title: "x", documentPath: "/tmp/a.txt")
        let b = WindowFocus(app: AppInfo(bundleID: "A", name: "A", pid: 1), windowID: 1, title: "x", documentPath: "/tmp/b.txt")
        _ = tr.handle(.focus(a), now: t0)
        XCTAssertEqual(tr.handle(.focus(b), now: t0.addingTimeInterval(1))?.endReason, .focusChange)
    }

    func test_lock_closes_with_lock_reason() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        XCTAssertEqual(tr.handle(.lock, now: t0.addingTimeInterval(2))?.endReason, .lock)
        XCTAssertNil(tr.current)
    }

    func test_sleep_closes_with_sleep_reason() {
        let tr = FocusTracker()
        _ = tr.handle(.focus(focus("A", win: 1, title: "x")), now: t0)
        XCTAssertEqual(tr.handle(.sleep, now: t0.addingTimeInterval(2))?.endReason, .sleep)
        XCTAssertNil(tr.current)
    }

    func test_close_events_on_empty_tracker_return_nil() {
        let tr = FocusTracker()
        XCTAssertNil(tr.handle(.idle, now: t0))
        XCTAssertNil(tr.handle(.lock, now: t0))
        XCTAssertNil(tr.handle(.sleep, now: t0))
        XCTAssertNil(tr.handle(.appQuit(pid: 1), now: t0))
        XCTAssertNil(tr.stop(now: t0))
    }
}
