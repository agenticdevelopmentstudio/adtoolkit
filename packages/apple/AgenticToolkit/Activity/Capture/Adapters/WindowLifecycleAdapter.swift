// AppKit/AgenticToolkit observation — macOS only (c2). iOS compiles
// `NoOpObservationAdapters.swift` instead.
#if os(macOS)
import AppKit
import AgenticToolkitCore        // SystemWindowInfo
import AgenticToolkitCoreMacOS   // SystemWindowObserver / SystemWindowObserverDelegate / SystemWindowManager

/// Wraps the toolkit's `SystemWindowObserver` (AX + NSWorkspace based window
/// lifecycle tracking) as a `WindowLifecycleSource`.
///
/// `SystemWindowObserver`'s own doc comment guarantees every delegate callback
/// arrives on the main run loop (AX observers are added to `CFRunLoopGetMain()`,
/// NSWorkspace observers use the `.main` queue, internal hops go through
/// `DispatchQueue.main`) — it is `@unchecked Sendable` specifically because of
/// that invariant. `SystemWindowObserverDelegate` itself is a plain
/// (non-`@MainActor`) `AnyObject` protocol, so this `@MainActor` class must
/// implement its requirements as `nonisolated` and hop into MainActor
/// isolation with `MainActor.assumeIsolated`, matching the main-thread
/// guarantee documented above.
// Public, and its `WindowLifecycleSource`/`SystemWindowObserverDelegate`
// witnesses are public too: `olylod` constructs this directly and hands it
// to `UsageCollector`'s public initializer as a `WindowLifecycleSource`, and
// also assigns `onTitleChange` directly — a public type's public conformance
// to a public protocol requires its witnesses be public as well.
@MainActor
public final class WindowLifecycleAdapter: NSObject, WindowLifecycleSource, SystemWindowObserverDelegate {
    public var onEvent: ((WindowLifecycleKind, AppInfo, UInt32, String) -> Void)?
    public var onTitleChange: (() -> Void)?     // nudges the focus adapter to re-emit
    private var observer: SystemWindowObserver?

    /// The owning app of every window seen created, so `titleChanged` and
    /// `destroyed` can name it.
    ///
    /// `SystemWindowObserver` reports those two by window id alone — it has no
    /// pid to resolve, and for `destroyed` the process may already be gone, so
    /// there is nothing left to ask. Without this the adapter emitted
    /// `AppInfo(bundleID: "", name: "", pid: 0)`, and every window row but
    /// `created` landed in the log attributed to no application at all: a
    /// `window` event whose summary read "Window" and which no per-app query
    /// could ever find.
    ///
    /// Bounded by the windows this observation has seen open and not yet seen
    /// close. A window created before `start()` is not in the map, so its
    /// events still fall back to the empty `AppInfo` — the same "we don't
    /// know" as before, now the exception rather than the rule.
    private var owners: [UInt32: AppInfo] = [:]

    public override init() { super.init() }

    public func start() {
        let obs = SystemWindowObserver(windowManager: SystemWindowManager())
        obs.delegate = self
        obs.startObserving()
        observer = obs
    }
    public func stop() {
        observer?.stopObserving()
        observer = nil
        // Dropped with the observation: the next `start()` re-walks the
        // windows that exist then, and stale entries would otherwise
        // accumulate for windows closed while we were not looking.
        owners.removeAll()
    }

    // MARK: - SystemWindowObserverDelegate (nonisolated; see class doc comment)

    public nonisolated func windowCreated(window: SystemWindowInfo) {
        MainActor.assumeIsolated {
            // SystemWindowInfo exposes only the CGWindowList owner display name
            // ("Xcode"), not a bundle id. For `created` events the owning app is
            // alive, so resolve its real bundleIdentifier from the pid (fallback to
            // the display name). `name` keeps the display name. destroyed and
            // titleChanged carry no pid, so they read the app back out of `owners`.
            let bundleID = NSRunningApplication(processIdentifier: window.pid)?.bundleIdentifier ?? window.app
            let app = AppInfo(bundleID: bundleID, name: window.app, pid: window.pid)
            self.owners[window.id] = app
            self.onEvent?(.created, app, window.id, window.title)
        }
    }
    public nonisolated func windowDestroyed(windowID: UInt32) {
        MainActor.assumeIsolated {
            // Removed as it is read: a destroyed window's id is never used
            // again, and leaving it would grow the map for the daemon's life.
            let app = self.owners.removeValue(forKey: windowID) ?? Self.unknownApp
            self.onEvent?(.destroyed, app, windowID, "")
        }
    }
    public nonisolated func windowTitleChanged(windowID: UInt32, newTitle: String) {
        MainActor.assumeIsolated {
            self.onEvent?(.titleChanged, self.owners[windowID] ?? Self.unknownApp,
                windowID, newTitle)
            self.onTitleChange?()
        }
    }

    /// What is emitted for a window this observation never saw open — the
    /// same empty `AppInfo` the schema stores as "no application recorded".
    private static let unknownApp = AppInfo(bundleID: "", name: "", pid: 0)
    public nonisolated func appLaunched(appName: String, pid: Int32) {}
    public nonisolated func appTerminated(appName: String, pid: Int32) {}
}
#endif
