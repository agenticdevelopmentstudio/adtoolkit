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
/// What one attempt to subscribe to an app's notifications came to.
enum FrontmostElementSubscription {
    /// Subscribed; the handle is what `unsubscribe` takes back.
    case attached(AnyObject)
    /// Not this time — the app may simply have no AX server yet.
    case failed
    /// Accessibility is not granted. Asking again cannot succeed.
    case apiDisabled
}

/// The Accessibility calls the observer makes, behind one seam so a test can
/// count them. The live one is `SystemFrontmostElementAX`.
@MainActor
protocol FrontmostElementAX: AnyObject {
    var frontmostPID: pid_t? { get }
    func subscribe(pid: pid_t, notifications: [String], context: UnsafeMutableRawPointer)
        -> FrontmostElementSubscription
    func unsubscribe(_ handle: AnyObject)
}

@MainActor
final class SystemFrontmostElementAX: FrontmostElementAX {
    /// `AXObserverCreate`, as the error and the observer it made.
    typealias Create = (pid_t) -> (AXError, AnyObject?)
    /// `AXObserverAddNotification` for one notification name.
    typealias Add = (AnyObject, AXUIElement, String, UnsafeMutableRawPointer) -> AXError

    private let create: Create
    private let add: Add

    /// The two AX calls are injectable so a test can count them; the
    /// defaults are the real ones.
    init(create: @escaping Create = SystemFrontmostElementAX.liveCreate,
         add: @escaping Add = SystemFrontmostElementAX.liveAdd) {
        self.create = create
        self.add = add
    }

    nonisolated static func liveCreate(_ pid: pid_t) -> (AXError, AnyObject?) {
        var created: AXObserver?
        let made = AXObserverCreate(pid, axObserverCallback, &created)
        return (made, created)
    }

    nonisolated static func liveAdd(
        _ observer: AnyObject, _ app: AXUIElement, _ name: String, _ context: UnsafeMutableRawPointer
    ) -> AXError {
        // swiftlint:disable:next force_cast
        AXObserverAddNotification(observer as! AXObserver, app, name as CFString, context)
    }

    var frontmostPID: pid_t? { NSWorkspace.shared.frontmostApplication?.processIdentifier }

    /// A created observer carrying no registrations delivers nothing, so a
    /// subscription that fails wholesale counts as a failed attach and not as
    /// a silent success. A *partial* success is kept: three of four
    /// notifications still see more than none.
    ///
    /// The first `.apiDisabled` ends it: Accessibility is not granted, every
    /// further registration would be one more trip through `tccd` to learn
    /// the same thing, and a burst of those is what freezes the machine.
    func subscribe(pid: pid_t, notifications: [String], context: UnsafeMutableRawPointer)
        -> FrontmostElementSubscription {
        let (made, created) = create(pid)
        if made == .apiDisabled { return .apiDisabled }
        guard made == .success, let created else { return .failed }
        let app = AXUIElementCreateApplication(pid)
        var registered = false
        for name in notifications {
            let result = add(created, app, name, context)
            if result == .apiDisabled { return .apiDisabled }
            if result == .success { registered = true }
        }
        guard registered else { return .failed }
        // swiftlint:disable:next force_cast
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created as! AXObserver), .defaultMode)
        return .attached(created)
    }

    func unsubscribe(_ handle: AnyObject) {
        // swiftlint:disable:next force_cast
        let observer = handle as! AXObserver
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }
}

@MainActor
public final class FrontmostElementObserver {
    /// Called on the main run loop each time the frontmost app moves its own
    /// focus. Carries nothing: the point is to make the reader re-read, not to
    /// describe what changed.
    public var onChange: (() -> Void)?

    private var observer: AnyObject?
    private var observedPID: pid_t?
    private var retryTask: Task<Void, Never>?
    private let accessibility: any FrontmostElementAX
    private let delays: [Duration]

    /// True until `start()`, after `stop()`, and once Accessibility turns out
    /// not to be granted: no AX call is made while it holds. A queued
    /// activation or a retry already past its sleep would otherwise ask AX
    /// again after the owner stopped watching — and, without the grant, every
    /// ask costs a trip through `tccd`.
    private var stopped = true

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

    public convenience init() {
        self.init(accessibility: SystemFrontmostElementAX(), retryDelays: Self.retryDelays)
    }

    init(accessibility: any FrontmostElementAX, retryDelays: [Duration]) {
        self.accessibility = accessibility
        self.delays = retryDelays
    }

    public func start() {
        stopped = false
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(activated),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
        retarget()
    }

    public func stop() {
        stopped = true
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
    func retarget() {
        guard !stopped else { return }
        guard let pid = accessibility.frontmostPID,
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
            guard let delays = self?.delays else { return }
            for delay in delays {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled, let self, !self.stopped else { return }
                guard Self.shouldRetry(
                    failedPID: pid,
                    frontmostPID: self.accessibility.frontmostPID,
                    observedPID: self.observedPID)
                else { return }
                if self.attach(pid: pid) { return }
            }
        }
    }

    /// Subscribes to this app's notifications, reporting whether it worked.
    /// Accessibility not granted stops the observer outright: no retry, and
    /// no further AX call until the next `start()`.
    private func attach(pid: pid_t) -> Bool {
        let context = Unmanaged.passUnretained(self).toOpaque()
        switch accessibility.subscribe(pid: pid, notifications: Self.notifications, context: context) {
        case .attached(let handle):
            observer = handle
            observedPID = pid
            return true
        case .failed:
            return false
        case .apiDisabled:
            stopped = true
            return true
        }
    }

    private func detach() {
        retryTask?.cancel()
        retryTask = nil
        if let observer { accessibility.unsubscribe(observer) }
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
