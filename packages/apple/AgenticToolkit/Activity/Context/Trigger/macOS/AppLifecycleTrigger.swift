#if os(macOS)
import AppKit
import Foundation

/// Applications starting and ending.
///
/// A source of its own rather than an addition to `PowerAdapter`: that adapter
/// already observes `didTerminateApplicationNotification`, but it reports only
/// a pid — enough to close a focus segment, useless as a context event, which
/// needs the bundle id to say *which* app went away. It also has no launch
/// counterpart at all.
@MainActor
public protocol AppLifecycleSource: AnyObject {
    var onChange: ((AppLifecycleChange, AppInfo) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
public final class SystemAppLifecycleSource: AppLifecycleSource {
    public var onChange: ((AppLifecycleChange, AppInfo) -> Void)?
    public init() {}

    public func start() {
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(launched(_:)),
                              name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        workspace.addObserver(self, selector: #selector(terminated(_:)),
                              name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }

    public func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // Delivered on the main thread, but `@objc` selectors cannot be
    // main-actor isolated, so both are `nonisolated` and hand the
    // notification to `report(_:_:)`, which crosses back — the pattern
    // PowerAdapter, FrontmostFocusAdapter and SystemSessionLockSleepSource
    // all use.
    @objc private nonisolated func launched(_ note: Notification) {
        report(.launched, note)
    }

    @objc private nonisolated func terminated(_ note: Notification) {
        report(.terminated, note)
    }

    /// A notification that cannot identify its app is dropped rather than
    /// reported with invented identity: an event that cannot say which app it
    /// is about is worse than no event, because the timeline would clip a
    /// focus row against it. That covers both a missing
    /// `NSWorkspaceApplicationKey` and an application with no bundle id — see
    /// ``identity(bundleID:name:pid:)``, which decides the second.
    ///
    /// The `Sendable` fields are pulled out of `NSRunningApplication` here,
    /// before crossing into `MainActor.assumeIsolated`: capturing the
    /// non-`Sendable` `NSRunningApplication` (or `Notification`) in that
    /// closure trips Swift 6's region-isolation "sending risks causing data
    /// races" diagnostic — the same fix `PowerAdapter.quit(_:)` applies.
    private nonisolated func report(_ change: AppLifecycleChange, _ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else { return }
        guard let identity = Self.identity(bundleID: app.bundleIdentifier,
                                           name: app.localizedName,
                                           pid: app.processIdentifier) else { return }
        MainActor.assumeIsolated { self.onChange?(change, identity) }
    }

    /// What a workspace notification has to carry before it becomes an event,
    /// and `nil` when it does not carry it.
    ///
    /// The bundle id *is* the identity: it is what a later query groups by,
    /// and what the timeline matches a focus row against when it clips at a
    /// quit. Without it there is nothing to say which app the row is about, so
    /// the notification is dropped — the rule the doc on ``report(_:_:)`` has
    /// always stated, now also applied to the second way identity can be
    /// absent. An empty string is not a weaker identity, it is a row that
    /// silently joins every other nameless row.
    ///
    /// A missing *name* is a different matter: the app is still identified, so
    /// the event is worth keeping, and it falls back to the bundle id rather
    /// than to `""` or an invented `"unknown"`. The summary drops a detail
    /// that merely repeats the subject, so this reads as the bundle id once,
    /// not twice.
    ///
    /// Deliberately a value-in, value-out function rather than four lines
    /// inside `report(_:_:)`: `NSRunningApplication` cannot be constructed
    /// with a missing bundle id, so a rule written there could never be
    /// tested, and `AgenticToolkitActivityTests` is where this module is tested.
    nonisolated static func identity(bundleID: String?, name: String?,
                                    pid: Int32) -> AppInfo? {
        guard let bundleID, !bundleID.isEmpty else { return nil }
        let name = name.flatMap { $0.isEmpty ? nil : $0 } ?? bundleID
        return AppInfo(bundleID: bundleID, name: name, pid: pid)
    }
}

/// Emits an `app_lifecycle` event when any application launches or quits.
@MainActor
public final class AppLifecycleTrigger: ContextTrigger {
    public let kind: ContextEventKind = .appLifecycle
    /// NSWorkspace application notifications are not behind TCC — no
    /// Accessibility grant, no prompt. The trigger's own opt-in checkbox is
    /// the only gate, which is exactly the `session` and `power` shape.
    public let requiredPermission: ContextPermission = .none
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let source: any AppLifecycleSource
    private let now: () -> Date
    private var isRunning = false

    public init(source: any AppLifecycleSource = SystemAppLifecycleSource(),
                now: @escaping () -> Date = { Date() }) {
        self.source = source
        self.now = now
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        source.onChange = { [weak self] change, app in self?.emit(change, app) }
        source.start()
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        source.onChange = nil
        source.stop()
    }

    private func emit(_ change: AppLifecycleChange, _ app: AppInfo) {
        guard isRunning else { return }
        onEvent?(.appLifecycle(AppLifecycleDetail(
            change: change, bundleID: app.bundleID,
            appName: app.name, pid: app.pid)), now())
    }
}
#endif
