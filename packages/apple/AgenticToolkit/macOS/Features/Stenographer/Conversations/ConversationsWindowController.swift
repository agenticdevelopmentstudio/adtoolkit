import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import AppKit

/// Singleton window controller for the Conversations window — every observed
/// session's dialogue with its human, interleaved on one timeline and read as a
/// group chat nobody in this process is a member of.
///
/// The window is the toolkit's ``ConversationsViewController``; what this adds
/// is the two things only the app can supply — the daemon feed and what a row
/// click points at — plus the floating/filter prefs, which follow the Sessions
/// window's recipe so both windows are configured in the same place and the same
/// way.
@MainActor
public final class ConversationsWindowController: SingleWindowController {
    public private(set) static var current: ConversationsWindowController?

    private let feed: ConversationsFeed
    private let conversations: ConversationsViewController
    private let split: ConversationsSplitViewController

    /// The window's contents, for the key commands that drive it. They are
    /// declared at launch and resolve this at the moment they run, so the
    /// Settings panel can list them before the window has ever been opened.
    public var splitViewController: ConversationsSplitViewController { split }
    /// Held so it outlives the assignment: the shelf keeps a reference too, but
    /// the poll behind it is this object's, and letting it go would stop the
    /// glyphs without stopping the shelf from asking.
    private let activitySource: StenographerSessionListSource
    private let configDialog: WindowOptionsDialog
    private var floatingObserver: UserSettingObserver<Bool>?
    private var workOutputObserver: UserSettingObserver<Bool>?

    public static func present(service: any StenographerDaemonService) {
        ensureCurrent(service: service)
        current?.showWindow()
    }

    /// How many conversations the window is showing, for the View menu and
    /// anything else outside the window that asks. The split controller owns the
    /// answer; this is the way in from a menu, which has no view to reach it
    /// through.
    public var selectionMode: ConversationsSelectionMode {
        get { split.selectionMode }
        set { split.selectionMode = newValue }
    }

    /// Constructs the singleton (registering it with `WindowManager.registry`)
    /// without showing it, so `restoreOnLaunch()` can reopen the window if it was
    /// visible last session — the `SessionsWindowController.ensureCurrent()`
    /// pattern, and the reason no visibility logic lives in the app.
    public static func ensureCurrent(service: any StenographerDaemonService) {
        if current == nil {
            current = ConversationsWindowController(service: service)
        }
    }

    public override func close() {
        // performClose NSBeeps on a window that isn't visible — guard, as the
        // sibling window controllers do.
        guard window?.isVisible == true else { return }
        window?.performClose(nil)
    }

    /// Applies the floating preference when the window is built and keeps it
    /// live, and puts the gear in the title bar where every other window's is.
    public override func configureWindow(_ window: NSWindow) {
        setFloating(UserSettings.stenographerConversationsAlwaysOnTop.value)
        floatingObserver = UserSettingObserver(
            UserSettings.stenographerConversationsAlwaysOnTop
        ) { [weak self] floating in
            self?.setFloating(floating)
        }
        // The toolbar and the clear titlebar belong to the split controller —
        // it is the thing the toggle discloses, and the sidebar whose inset the
        // transparent titlebar exists to let run full height.
        split.configureWindowChrome(window)
        window.addTitlebarAccessoryViewController(configDialog.makeTitlebarAccessory())
    }

    private init(service: any StenographerDaemonService) {
        let feed = ConversationsFeed(service: service)
        self.feed = feed
        let conversations = ConversationsViewController(
            pageLimit: ConversationsFeed.limit
        ) { includeWorkOutput, sourceID, limit in
            await feed.load(
                includeWorkOutput: includeWorkOutput, sessionID: sourceID, limit: limit)
        }
        conversations.includeWorkOutput =
            UserSettings.stenographerConversationsShowWorkOutput.value
        // The shelf's ticks, as they were left. Both directions go through the
        // setting — the same recipe as the work-output filter — so hiding a
        // session survives closing the window.
        conversations.hiddenSessions =
            UserSettings.stenographerConversationsHiddenSessions.value
        conversations.onHiddenSessionsChanged = { hidden in
            UserSettings.stenographerConversationsHiddenSessions.value = hidden
        }
        self.conversations = conversations
        let split = ConversationsSplitViewController(feed: conversations)
        self.split = split

        // The shelf's activity glyphs, from the same seam the Sessions window
        // reads — so a session that is working reads as working in both, rather
        // than each window deriving liveness from whatever it happens to hold.
        // Its own instance rather than the Sessions window's: `startObserving`
        // is one watcher per source, and a shared one would mean whichever
        // window opened second silently turned off the other's polling.
        //
        // No hours filter (`sinceHours: 0`). The Sessions window shows a time
        // slice because it is a list of sessions; this is answering "what is
        // *that* row doing", and a session old enough to fall outside the slice
        // would read as idle rather than as unknown.
        let activitySource = StenographerSessionListSource(service: service, sinceHours: 0)
        self.activitySource = activitySource
        split.shelf.activitySource = activitySource

        self.configDialog = WindowOptionsDialog(title: "Conversations Window") {
            [
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: "Show work output",
                        setting: UserSettings.stenographerConversationsShowWorkOutput
                    )
                ),
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: "Always show above other windows",
                        setting: UserSettings.stenographerConversationsAlwaysOnTop
                    )
                )
            ]
        }

        super.init(windowID: "conversations", contentViewController: self.split)

        // The pick, then the mode, as they were left — the pick first, so
        // single mode comes back on the conversation it was reading rather
        // than settling a new one. Both directions go through the settings,
        // the same recipe as the ticks above. Set after `super.init` because
        // switching to single mode reaches the shelf, which the split
        // controller only has once it is fully constructed.
        let solo = UserSettings.stenographerConversationsSoloSession.value
        split.soloSessionID = solo.isEmpty ? nil : solo
        split.onSoloSessionChanged = { id in
            UserSettings.stenographerConversationsSoloSession.value = id ?? ""
        }
        split.selectionMode =
            UserSettings.stenographerConversationsSingleMode.value ? .single : .multi
        split.onSelectionModeChanged = { mode in
            UserSettings.stenographerConversationsSingleMode.value = mode == .single
        }

        // The checkbox edits the pref; the pref drives the feed. Going through
        // the setting rather than wiring the checkbox straight to the view
        // controller is what makes the filter survive a window close.
        workOutputObserver = UserSettingObserver(
            UserSettings.stenographerConversationsShowWorkOutput
        ) { [weak conversations] show in
            conversations?.includeWorkOutput = show
        }

        // The overlay's composer, wired to the same mechanism the oversight
        // window uses to compact a session: there is one way to say something
        // to a running Claude from outside it, and that is to type it at its
        // terminal.
        conversations.onSendToSource = { sessionID, text in
            await feed.send(to: sessionID, text: text)
        }

        // A jump that can't be made says why, on the window it was asked from
        // — silently staying put reads as the gesture being broken.
        conversations.onGoToSource = { [weak conversations] message in
            guard let sessionID = message.attribution?.sourceID, !sessionID.isEmpty else { return }
            Task { @MainActor in
                guard let reason = await feed.activateSession(id: sessionID) else { return }
                guard let window = conversations?.view.window else {
                    NSSound.beep()
                    return
                }
                let alert = NSAlert()
                alert.messageText = "Couldn't go to that session"
                alert.informativeText = reason
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
        }

        self.windowTitle = "Stenographer — Conversations"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 560, height: 720),
            minSize: NSSize(width: 380, height: 300),
            defaultPosition: .topRight,
            persistsFrame: true
        )
    }
}
