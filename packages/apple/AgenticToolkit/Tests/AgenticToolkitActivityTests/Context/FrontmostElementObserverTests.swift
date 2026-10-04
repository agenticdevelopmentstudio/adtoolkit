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

    // MARK: - No AX call once stopped or denied

    private static let quickRetries: [Duration] = [.milliseconds(5), .milliseconds(5), .milliseconds(5)]

    @MainActor
    func testNoAXCallIsMadeAfterStop() async throws {
        let accessibility = CountingAccessibility(result: .failed)
        let observer = FrontmostElementObserver(accessibility: accessibility, retryDelays: Self.quickRetries)
        observer.start()
        XCTAssertEqual(accessibility.subscribes, 1)
        observer.stop()

        // A queued activation delivered after stop, and the retries' window.
        observer.retarget()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(accessibility.subscribes, 1, "stopped means no AX call at all")
    }

    @MainActor
    func testAccessibilityDeniedStopsAskingAtOnce() async throws {
        let accessibility = CountingAccessibility(result: .apiDisabled)
        let observer = FrontmostElementObserver(accessibility: accessibility, retryDelays: Self.quickRetries)
        defer { observer.stop() }
        observer.start()
        try await Task.sleep(for: .milliseconds(100))
        observer.retarget()
        XCTAssertEqual(accessibility.subscribes, 1, "no retry, and no re-ask on the next activation")
    }

    // MARK: - Inside one subscribe

    @MainActor
    func testADeniedRegistrationEndsTheSubscribeAtTheFirstCall() {
        // Four registrations, each its own trip through `tccd` without the
        // grant. The first denial answers for all of them.
        let adds = CallCounter()
        let accessibility = SystemFrontmostElementAX(
            create: { _ in (.success, NSObject()) },
            add: { _, _, _, _ in adds.count += 1; return .apiDisabled }
        )
        let result = accessibility.subscribe(
            pid: 4242, notifications: FrontmostElementObserver.notifications, context: Self.context)
        guard case .apiDisabled = result else { return XCTFail("expected .apiDisabled, got \(result)") }
        XCTAssertEqual(adds.count, 1, "no registration is attempted after the first denial")
    }

    @MainActor
    func testADeniedCreateMakesNoRegistrationAtAll() {
        let adds = CallCounter()
        let accessibility = SystemFrontmostElementAX(
            create: { _ in (.apiDisabled, nil) },
            add: { _, _, _, _ in adds.count += 1; return .success }
        )
        let result = accessibility.subscribe(
            pid: 4242, notifications: FrontmostElementObserver.notifications, context: Self.context)
        guard case .apiDisabled = result else { return XCTFail("expected .apiDisabled, got \(result)") }
        XCTAssertEqual(adds.count, 0)
    }

    @MainActor
    func testRegistrationsThatAllFailAreAFailedAttach() {
        let adds = CallCounter()
        let accessibility = SystemFrontmostElementAX(
            create: { _ in (.success, NSObject()) },
            add: { _, _, _, _ in adds.count += 1; return .failure }
        )
        let result = accessibility.subscribe(
            pid: 4242, notifications: FrontmostElementObserver.notifications, context: Self.context)
        guard case .failed = result else { return XCTFail("expected .failed, got \(result)") }
        XCTAssertEqual(adds.count, FrontmostElementObserver.notifications.count)
    }

    private static var context: UnsafeMutableRawPointer { UnsafeMutableRawPointer(bitPattern: 0x1)! }
}

/// Counts the AX calls made inside one `subscribe`.
@MainActor
private final class CallCounter {
    var count = 0
}

/// Counts every subscription attempt; the frontmost app never changes.
@MainActor
private final class CountingAccessibility: FrontmostElementAX {
    let result: FrontmostElementSubscription
    private(set) var subscribes = 0
    var frontmostPID: pid_t? { 4242 }

    init(result: FrontmostElementSubscription) { self.result = result }

    func subscribe(pid: pid_t, notifications: [String], context: UnsafeMutableRawPointer)
        -> FrontmostElementSubscription {
        subscribes += 1
        return result
    }

    func unsubscribe(_ handle: AnyObject) {}
}
#endif
