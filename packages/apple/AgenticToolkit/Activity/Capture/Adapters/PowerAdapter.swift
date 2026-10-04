// AppKit/NSWorkspace observation — macOS only (c2). iOS compiles
// `NoOpObservationAdapters.swift` instead.
#if os(macOS)
import AppKit

/// Observes screen-lock/-unlock (`DistributedNotificationCenter`),
/// sleep/wake (`NSWorkspace`), and app-termination (`NSWorkspace`) events.
///
/// All notification centers deliver on the main thread for these
/// notification names (workspace notifications are always posted on `.main`;
/// `com.apple.screenIsLocked`/`com.apple.screenIsUnlocked` are posted by
/// `loginwindow` and observed via `DistributedNotificationCenter.default()`,
/// which — like `NotificationCenter` — delivers synchronously on the poster's
/// thread, and the poster here is the main run loop's Mach-port listener).
/// Same `nonisolated` + `MainActor.assumeIsolated` pattern as the other
/// adapters — see `WindowLifecycleAdapter` for the shared rationale.
///
/// `onResume` fires on both wake-from-sleep and screen-unlock so the collector
/// can re-emit focus and re-open a segment in the same app (existing `stop()`
/// `removeObserver` calls on both centers already cover the new observers).
// Public, and its `PowerSource` witnesses are public too: `olylod`
// constructs this directly and hands it to `UsageCollector`'s public
// initializer as a `PowerSource` — a public type's public conformance to a
// public protocol requires its witnesses be public as well.
@MainActor
public final class PowerAdapter: PowerSource {
    public var onLock: (() -> Void)?
    public var onSleep: (() -> Void)?
    public var onAppQuit: ((Int32) -> Void)?
    public var onResume: (() -> Void)?

    public init() {}

    public func start() {
        let wsnc = NSWorkspace.shared.notificationCenter
        wsnc.addObserver(self, selector: #selector(sleep), name: NSWorkspace.willSleepNotification, object: nil)
        wsnc.addObserver(self, selector: #selector(quit(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        wsnc.addObserver(self, selector: #selector(resume), name: NSWorkspace.didWakeNotification, object: nil)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(lock), name: .init("com.apple.screenIsLocked"), object: nil)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(resume), name: .init("com.apple.screenIsUnlocked"), object: nil)
    }
    public func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private nonisolated func sleep() {
        MainActor.assumeIsolated { self.onSleep?() }
    }
    @objc private nonisolated func lock() {
        MainActor.assumeIsolated { self.onLock?() }
    }
    @objc private nonisolated func resume() {
        MainActor.assumeIsolated { self.onResume?() }
    }
    @objc private nonisolated func quit(_ n: Notification) {
        // Extract the Sendable payload (pid_t) before crossing into
        // MainActor.assumeIsolated: capturing the whole (non-Sendable)
        // Notification in that closure trips Swift 6's region-isolation
        // "sending risks causing data races" diagnostic.
        let pid = (n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
        MainActor.assumeIsolated {
            if let pid { self.onAppQuit?(pid) }
        }
    }
}
#endif
