#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity
import ApplicationServices

/// The one decision in `FrontmostElementObserver` that does not need a live
/// app to exercise: which notifications it subscribes to. The subscription
/// itself is AX plumbing and is covered by the running daemon, the same way
/// `BrowserAddressReader`'s subtree walk is.
final class FrontmostElementObserverTests: XCTestCase {

    func testItWatchesForFocusMovingBetweenAnAppsOwnWindows() {
        // Without this one, switching between two windows of the same app —
        // two iTerm2 windows, two Xcode windows — produces no reading: no app
        // becomes frontmost, so `didActivateApplicationNotification` is
        // silent, and the toolkit's window observer swallows this same
        // notification without telling its delegate.
        XCTAssertTrue(FrontmostElementObserver.notifications
            .contains(kAXFocusedWindowChangedNotification))
    }

    func testItWatchesForFocusMovingInsideOneWindow() {
        // A terminal tab and a split pane are neither windows nor titles, so
        // this is the only notification that describes switching between
        // them.
        XCTAssertTrue(FrontmostElementObserver.notifications
            .contains(kAXFocusedUIElementChangedNotification))
    }

    func testItWatchesTheOtherTwoWaysAFrontmostReadingCanGoStale() {
        XCTAssertTrue(FrontmostElementObserver.notifications
            .contains(kAXMainWindowChangedNotification))
        XCTAssertTrue(FrontmostElementObserver.notifications
            .contains(kAXTitleChangedNotification))
    }

    func testAFailedAttachIsRetriedWhileTheSameAppIsStillInFront() {
        // The launch race: an app becomes frontmost before its Accessibility
        // server answers. Nothing else asks again while the user stays in it,
        // so without this the app goes unobserved for its whole frontmost
        // stretch.
        XCTAssertTrue(FrontmostElementObserver.shouldRetry(
            failedPID: 42, frontmostPID: 42, observedPID: nil))
    }

    func testRetryingStopsOnceTheUserHasMovedOn() {
        // `retarget()` owns the new app; a retry still chasing the old one
        // would attach to an app that is no longer in front.
        XCTAssertFalse(FrontmostElementObserver.shouldRetry(
            failedPID: 42, frontmostPID: 99, observedPID: nil))
        XCTAssertFalse(FrontmostElementObserver.shouldRetry(
            failedPID: 42, frontmostPID: nil, observedPID: nil))
    }

    func testRetryingStopsOnceAnEarlierAttemptSucceeded() {
        XCTAssertFalse(FrontmostElementObserver.shouldRetry(
            failedPID: 42, frontmostPID: 42, observedPID: 42))
    }

    func testRetriesAreBoundedAndBackOff() {
        // Bounded so an app that has no AX server at all — or Accessibility
        // that was never granted — stops being asked instead of retrying for
        // as long as it stays in front.
        let delays = FrontmostElementObserver.retryDelays
        XCTAssertFalse(delays.isEmpty)
        XCTAssertEqual(delays, delays.sorted())
    }

    func testNothingIsSubscribedTwice() {
        // AX deduplicates by (element, notification), so a repeat would be
        // harmless — but it would also mean someone added a name believing it
        // was missing, which is worth catching here rather than in the log.
        XCTAssertEqual(Set(FrontmostElementObserver.notifications).count,
                       FrontmostElementObserver.notifications.count)
    }
}
#endif
