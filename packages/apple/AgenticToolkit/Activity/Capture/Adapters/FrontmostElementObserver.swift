// Accessibility observation of the frontmost app — macOS only (c2).
#if os(macOS)
import AppKit
import ApplicationServices

/// Fires whenever the frontmost app moves focus *within itself* — to another
/// of its windows, to another tab, to another pane.
///
/// Nothing else was watching for this. `FrontmostFocusAdapter` re-reads on
/// `NSWorkspace.didActivateApplicationNotification`, which is an app becoming
/// frontmost and says nothing about what happens afterwards, and on the
/// toolkit's window-lifecycle title changes, which only arrive if a window's
/// title actually changed and only after a `listAllWindows()` geometry match
/// finds the window it belongs to. Between them, switching iTerm2 windows
/// produced no reading at all — the toolkit does subscribe to
/// `kAXFocusedWindowChangedNotification`, but uses it solely to attach title
/// observers to the newly focused window and never tells its delegate — and
/// switching iTerm2 *tabs* produced one only if the window title happened to
/// change as a side effect. The focus that was recorded was whatever had been
/// true at the last app switch, which reads as the log lagging by minutes when
/// it is really not observing at all.
///
/// Scoped to the frontmost app, and re-pointed as that changes, because that
/// is the only app whose internal focus can alter what the frontmost reading
/// is. Watching every running app would multiply the notification traffic by
/// the number of apps open to learn nothing more.
@MainActor
public final class FrontmostElementObserver {
    /// Called on the main run loop each time the frontmost app moves its own
    /// focus. Carries nothing: the point is to make the reader re-read, not to
    /// describe what changed.
    public var onChange: (() -> Void)?

    private var observer: AXObserver?
    private var observedPID: pid_t?
    private var retryTask: Task<Void, Never>?

    /// How long to wait before each re-attempt, and so how many are made.
    ///
    /// An app that has just launched routinely has no Accessibility server for
    /// the first moment of its life, and it is frequently frontmost during
    /// exactly that moment — the toolkit's `SystemWindowObserver` waits a flat
    /// second after a launch notification for the same reason. Without a
    /// retry, losing that race means the app is never observed for as long as
    /// the user stays in it, because nothing asks again until they switch away
    /// and back. The delays grow so a genuinely un-observable app (no AX
    /// server, or Accessibility not granted) stops being asked quickly.
    nonisolated static let retryDelays: [Duration] = [.seconds(1), .seconds(3), .seconds(10)]

    /// Registered on the *application* element, which is where AX delivers all
    /// four for the app's whole window set.
    ///
    /// `kAXFocusedUIElementChanged` is the one that catches a terminal tab or
    /// split pane, neither of which is a window and so neither of which any of
    /// the other three describe. It is also the chattiest — moving between
    /// controls inside one window fires it — which is affordable only because
    /// `AppFocusTrigger` compares the reading it produces against the last one
    /// emitted and writes nothing when they match.
    nonisolated static let notifications = [
        kAXFocusedWindowChangedNotification,
        kAXMainWindowChangedNotification,
        kAXFocusedUIElementChangedNotification,
        kAXTitleChangedNotification
    ]

    public init() {}

    public func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(activated),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
        retarget()
    }

    public func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        detach()
    }

    /// `NSWorkspace` delivers on the main thread, so the selector is
    /// `nonisolated` and its body asserts the isolation it is already in —
    /// the same shape as `FrontmostFocusAdapter.activated`.
    @objc private nonisolated func activated() {
        MainActor.assumeIsolated { self.retarget() }
    }

    /// Points the observation at whichever app is frontmost now.
    private func retarget() {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              pid != observedPID
        else { return }
        detach()
        guard !attach(pid: pid) else { return }
        scheduleRetry(for: pid)
    }

    /// Whether a failed attach is still worth re-attempting.
    ///
    /// Two ways it stops being worth it, and they are different: the user moved
    /// on, so `retarget()` has already taken over and this retry would fight
    /// it; or an earlier retry in this same series already succeeded.
    nonisolated static func shouldRetry(failedPID: pid_t,
                                        frontmostPID: pid_t?,
                                        observedPID: pid_t?) -> Bool {
        frontmostPID == failedPID && observedPID == nil
    }

    private func scheduleRetry(for pid: pid_t) {
        retryTask = Task { [weak self] in
            for delay in Self.retryDelays {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled, let self else { return }
                guard Self.shouldRetry(
                    failedPID: pid,
                    frontmostPID: NSWorkspace.shared.frontmostApplication?.processIdentifier,
                    observedPID: self.observedPID)
                else { return }
                if self.attach(pid: pid) { return }
            }
        }
    }

    /// Subscribes to this app's notifications, reporting whether it worked.
    ///
    /// A created observer carrying no registrations delivers nothing, so a
    /// subscription that fails wholesale counts as a failed attach and not as a
    /// silent success — otherwise the retry above would never run and the
    /// observer would sit attached to an app it cannot hear. A *partial*
    /// success is kept: three of four notifications still see more than none.
    private func attach(pid: pid_t) -> Bool {
        var created: AXObserver?
        guard AXObserverCreate(pid, axObserverCallback, &created) == .success,
              let created
        else { return false }
        let app = AXUIElementCreateApplication(pid)
        let context = Unmanaged.passUnretained(self).toOpaque()
        let subscribed = Self.notifications.filter {
            AXObserverAddNotification(created, app, $0 as CFString, context) == .success
        }
        guard !subscribed.isEmpty else { return false }
        CFRunLoopAddSource(CFRunLoopGetMain(),
                           AXObserverGetRunLoopSource(created), .defaultMode)
        observer = created
        observedPID = pid
        return true
    }

    private func detach() {
        retryTask?.cancel()
        retryTask = nil
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(),
                                  AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        observer = nil
        observedPID = nil
    }

    fileprivate func notifyChanged() { onChange?() }
}

/// The C callback AX requires. A free function because `AXObserverCreate`
/// takes a bare function pointer, which cannot carry a capture — the observer
/// travels through the refcon instead, unretained, because it owns the
/// registration it is passed to and so cannot outlive it.
///
/// Delivered on the run loop the observer's source was added to, which is the
/// main one, so asserting main-actor isolation here is a statement of the same
/// invariant `WindowLifecycleAdapter` documents for its delegate callbacks.
private func axObserverCallback(_ observer: AXObserver, _ element: AXUIElement,
                                _ notification: CFString,
                                _ context: UnsafeMutableRawPointer?) {
    guard let context else { return }
    let target = Unmanaged<FrontmostElementObserver>.fromOpaque(context).takeUnretainedValue()
    MainActor.assumeIsolated { target.notifyChanged() }
}
#endif
