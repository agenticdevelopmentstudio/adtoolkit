import Foundation

// Public: `olylod` constructs the real macOS adapters directly and passes
// them into `UsageCollector`'s public initializer (which is typed in terms
// of these protocols), and the iOS no-op adapters conform to them from the
// same `#if os(iOS)` compilation path (c2, c9).

@MainActor
public protocol FocusSource: AnyObject {
    var onFocus: ((WindowFocus) -> Void)? { get set }
    func start(); func stop()
    /// Re-emits the current focus immediately (used to re-open a segment on
    /// resume from idle/lock/sleep without waiting for the next app switch).
    func poll()
}
@MainActor
public protocol WindowLifecycleSource: AnyObject {
    var onEvent: ((WindowLifecycleKind, AppInfo, UInt32, String) -> Void)? { get set }
    /// Fires alongside a `.titleChanged` `onEvent`, for consumers that care
    /// only that *something* about the current window changed — switching a
    /// browser tab retitles the window without activating any application, so
    /// `NSWorkspace.didActivateApplicationNotification` never fires and a
    /// focus-only observer sees nothing at all.
    ///
    /// On the protocol rather than only on the concrete adapter (I-3) because
    /// both pipelines need it and each must wire its own: `AppFocusTrigger`
    /// (context) and `UsageCollector` (usage) each own a separate source
    /// instance, and this closure is how each turns a retitle into a fresh
    /// focus reading via `FocusSource.poll()`.
    var onTitleChange: (() -> Void)? { get set }
    func start(); func stop()
}
@MainActor
public protocol IdleSource: AnyObject {
    var onIdle: (() -> Void)? { get set }
    var onActive: (() -> Void)? { get set }
    func start(); func stop()
}
@MainActor
public protocol PowerSource: AnyObject {
    var onLock: (() -> Void)? { get set }
    var onSleep: (() -> Void)? { get set }
    var onAppQuit: ((Int32) -> Void)? { get set }
    /// Fires on wake-from-sleep and screen-unlock so the collector can re-emit
    /// focus and re-open a segment in the same app.
    var onResume: (() -> Void)? { get set }
    func start(); func stop()
}
