import AppKit
import Combine
import os
import AgenticToolkitCore

/// Top-level coordinator for window infrastructure. Owns a
/// `WindowFrameManager` (frame persistence + screen-change handling),
/// a `WindowRegistry` (live `SingleWindowController` lookup), and the
/// recents/reopen-on-launch policy for both document and non-document
/// single windows.
///
/// Most callers go through one of the sub-services: e.g.
/// `WindowManager.shared.frames.restoreFrame(...)` or
/// `WindowManager.shared.registry.controller(forID:)`. Recents recording
/// happens automatically — `SingleWindowController` lifecycle hooks call
/// `windowDidInteract(_:kind:)` and the manager routes from there.
@MainActor
public final class WindowManager {

    public static let shared = WindowManager(screenManager: .shared)

    /// Frame persistence + screen-change handling.
    public let frames: WindowFrameManager

    /// Live `SingleWindowController` lookup by `windowID`.
    public let registry = WindowRegistry()

    /// Factories for the host's windows, keyed by `windowID`. The host registers
    /// every window it has via `register(id:make:)`; `restoreOnLaunch()` builds
    /// them (so they self-register) and re-shows the ones whose own `WindowSpec`
    /// persists visibility and that were visible last session.
    private var windowFactories: [String: @MainActor () -> Void] = [:]

    private static let logger = Logger(
        subsystem: "com.agenticdevelopmentstudio.agentictoolkit",
        category: "WindowManager"
    )

    /// `true` once `NSApplication.willTerminateNotification` has fired. Read
    /// by `SingleWindowController.windowWillClose(_:)`: AppKit sends
    /// `windowWillClose:` to still-visible windows while the app is quitting,
    /// and persisting `visible = false` there would stop a window the user
    /// left open from reopening next launch. See `WindowManagerTerminationTests`.
    public internal(set) var isTerminating = false

    public enum InteractionKind: Sendable {
        case show
        case close
    }

    /// AppKit's UserDefaults key for the recent-documents cap. Writing this
    /// adjusts `NSDocumentController.maximumRecentDocumentCount` (which is
    /// otherwise read-only) without subclassing `NSDocumentController`.
    private static let recentDocumentsLimitKey = "NSRecentDocumentsLimit"

    private var recentCountCancellable: AnyCancellable?

    public init(
        screenProvider: ScreenProvider = RealScreenProvider(),
        storage: WindowStateStorage = SettingsStoreWindowStateStorage(settings: UserSettings.shared),
        screenManager: ScreenManager? = nil
    ) {
        // Exactly one ScreenManager owns the persisted screen-set list and the
        // screen-change observer. Production shares `.shared`; tests inject an
        // isolated one. Never let this default to a fresh orphan — a second
        // ScreenManager on the same persistence key would clobber the real
        // one's state and double-register the notification observer.
        self.frames = WindowFrameManager(
            screenProvider: screenProvider,
            storage: storage,
            screenManager: screenManager ?? .shared
        )
        applyRecentDocumentCountFromSettings()
        // Mirror future setting changes through to AppKit.
        recentCountCancellable = UserSettings.recentWindowsCount.$currentValue
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyRecentDocumentCountFromSettings() }
        // Latch app termination so window teardown can tell a user-initiated
        // close (persist hidden) apart from windows closing only because the
        // app is quitting (must not clobber persisted visibility).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func handleAppWillTerminate() {
        isTerminating = true
    }

    // MARK: - Recents recording

    /// Lifecycle event from `SingleWindowController`. The manager owns the
    /// policy: spec lookup, behavior gating, OS-level recents call for
    /// document windows. AppKit auto-discovers the Open Recent submenu by
    /// finding any menu item whose action is `clearRecentDocuments:` — no
    /// explicit binding is needed here.
    public func windowDidInteract(_ controller: SingleWindowController, kind: InteractionKind) {
        guard kind == .show else { return }
        guard let spec = controller.windowSpec, spec.behavior.contains(.includeInRecents) else { return }

        if let url = controller.documentURL {
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        }
        // Single-window (non-document) tracking is intentionally a no-op
        // here; it lands in a follow-up slice with `WindowRecentsTracker`.
    }

    // MARK: - Eviction count

    /// Mirrors `UserSettings.recentWindowsCount` into AppKit's recent-
    /// documents limit. Writing the `NSRecentDocumentsLimit` user default
    /// is the public knob — `maximumRecentDocumentCount` itself is
    /// read-only. AppKit honors the new limit on the next
    /// `noteNewRecentDocumentURL` call.
    public func applyRecentDocumentCountFromSettings() {
        let count = UserSettings.recentWindowsCount.currentValue
        UserDefaults.standard.set(count, forKey: Self.recentDocumentsLimitKey)
    }

    // MARK: - Launch restore

    /// Tells the manager how to build the window `id`: `make` constructs its
    /// controller (which self-registers with `registry`) **without** showing it.
    /// The host registers every window it has, once, before `restoreOnLaunch()`.
    ///
    /// The host does not decide, and does not need to know, whether a window
    /// comes back at launch. That is the window's own `WindowSpec.behavior`,
    /// chosen where the window is built — `.canReopenOnLaunch` and
    /// `.persistsVisibility` are on by default, and a window that should not
    /// reopen turns them off there.
    public func register(id: String, make: @escaping @MainActor () -> Void) {
        windowFactories[id] = make
    }

    @available(*, deprecated, renamed: "register(id:make:)",
               message: "Register every window; whether it reopens is its WindowSpec's call.")
    public func registerRestorable(id: String, make: @escaping @MainActor () -> Void) {
        register(id: id, make: make)
    }

    /// One-shot restore for everything window-related. Hosts call this once
    /// from `applicationDidFinishLaunching`, after `register(id:make:)`-ing
    /// their windows. Every window saved as visible is built and handed to its
    /// controller's `restoreVisibilityIfNeeded()`, which re-shows it if its
    /// spec opts in. Windows saved as closed are not built at all. Then routes
    /// through `reopenRecentsOnLaunch()` to repopulate document windows.
    ///
    /// **Unconditional.** A window the user left open comes back — after a
    /// quit, an update, a crash or a restart — whatever macOS's "Close windows
    /// when quitting an application" says. That preference and
    /// `reopenOnLaunchPolicy` govern document windows only
    /// (`reopenRecentsOnLaunch()`); a window that should never come back says
    /// so in its own `WindowSpec` (drop `.canReopenOnLaunch`).
    ///
    /// A visible flag that no registered window and no live controller claims
    /// cannot be restored: it is logged as a host wiring gap and cleared, so
    /// it is reported once rather than on every launch.
    ///
    /// Re-invoke on reactivation (e.g. a second-launch
    /// `DistributedNotification`) so persisted-visible windows reappear
    /// when an LSUIElement app is re-frontmost.
    public func restoreOnLaunch() {
        restoreSavedVisibleWindows()
        reopenRecentsOnLaunch()
    }

    private func restoreSavedVisibleWindows() {
        for (id, make) in windowFactories
        where registry.controller(forID: id) == nil && frames.savedVisibility(for: id) == true {
            make()
        }

        for id in registry.registeredIDs {
            registry.controller(forID: id)?.restoreVisibilityIfNeeded()
        }

        for id in frames.visibleWindowIDs()
        where windowFactories[id] == nil && registry.controller(forID: id) == nil {
            Self.logger.error(
                "restoreOnLaunch: visible window '\(id, privacy: .public)' has no registered factory; clearing its flag"
            )
            frames.clearVisibility(for: id)
        }
    }

    // MARK: - Reopen on launch

    /// Decides whether to re-show document windows from
    /// `NSDocumentController.recentDocumentURLs` based on the user's
    /// `reopenOnLaunchPolicy`. Called by `restoreOnLaunch()`; hosts should
    /// not normally invoke this directly.
    public func reopenRecentsOnLaunch() {
        // No running application (e.g. a headless unit test) → nothing to reopen.
        // `NSApp` is an implicitly-unwrapped optional that's nil until NSApplication
        // is initialized, so guard it rather than crashing on `NSApp.windows`.
        guard let app = NSApp else { return }

        let policy = UserSettings.reopenOnLaunchPolicy.currentValue
        let shouldReopen = policy.shouldReopen(systemDefault: ReopenOnLaunchPolicy.systemDefault)

        if !shouldReopen {
            // Override AppKit's own state restoration: close any document
            // windows it auto-restored. Iterate windowControllers so we
            // close the controller (not just the window).
            for window in app.windows {
                guard let controller = window.windowController, controller.document != nil else { continue }
                controller.close()
            }
            return
        }

        // Skip URLs AppKit has already restored to avoid duplicate windows.
        let alreadyOpen: Set<URL> = Set(
            app.windows.compactMap {
                ($0.windowController?.document as? NSDocument)?.fileURL
            }
        )
        for url in NSDocumentController.shared.recentDocumentURLs where !alreadyOpen.contains(url) {
            NSDocumentController.shared.openDocument(
                withContentsOf: url,
                display: true
            ) { _, _, _ in }
        }
    }
}

extension SingleWindowController {

    /// URL of this controller's `NSDocument`, if any. Used by
    /// `WindowManager.windowDidInteract(_:kind:)` to route document windows
    /// through `NSDocumentController.shared.noteNewRecentDocumentURL(_:)`.
    public var documentURL: URL? {
        (document as? NSDocument)?.fileURL
    }
}
