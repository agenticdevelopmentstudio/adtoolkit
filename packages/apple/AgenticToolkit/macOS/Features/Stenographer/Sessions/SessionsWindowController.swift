import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

import AppKit
import Combine

/// Singleton window controller for the Sessions window. Hosts the toolkit's
/// `SessionListViewController` fed from the daemon from the daemon, and — like the toolkit's
/// own session panel — sizes the window's height to the session list's content, capped
/// to the screen (the list scrolls beyond that).
@MainActor
public final class SessionsWindowController: SingleWindowController {
    public private(set) static var current: SessionsWindowController?

    private var floatingObserver: UserSettingObserver<Bool>?
    private var transparencyCancellable: AnyCancellable?
    /// Mirrors the hours-filter pref into the list source (which polls off the
    /// main actor and so can't watch UserSettings itself).
    private var filterHoursObserver: UserSettingObserver<Int>?
    /// Rebuilds the rows when summaries are switched on or off — the summary line
    /// is built into each row, so the list has to be re-laid out, not just redrawn.
    private var summariesEnabledObserver: UserSettingObserver<Bool>?

    /// The list-plus-header content; held so `fitToContent` can size the
    /// window to the header height plus the list's intrinsic content height.
    private let sessionsContent: SessionsContentViewController
    /// The header's gear dialog: summaries on/off, the AI-summaries provider/model
    /// selection, and the window appearance. The controls only edit prefs —
    /// `StenographerAIConfigPush` owns pushing them to the daemon; this controller
    /// applies the appearance prefs via its own observers below.
    private let configDialog: WindowOptionsDialog
    /// Retained because it owns the selection observer and reloads the daemon's
    /// configurations each time its menu opens (same story as the AI Summaries
    /// settings panel's picker). The dialog builds its content afresh on every
    /// open, so a property — not just the closure capture — keeps it alive.
    private let aiSummariesPicker: DaemonProviderPickerView
    private let listSource: StenographerSessionListSource

    public static func present(service: any StenographerDaemonService) {
        ensureCurrent(service: service)
        current?.showWindow()
        // Fit once the window exists + has laid out; the observer handles later changes.
        DispatchQueue.main.async { current?.fitToContent() }
    }

    /// Constructs the singleton controller (registering it with
    /// `WindowManager.registry`) without showing the window. `main.swift` calls
    /// this at launch so the toolkit's `restoreOnLaunch()` can reopen the
    /// Sessions window if it was visible last session — no app-side visibility
    /// logic, matching the `UsageHUDWindowController.ensureCurrent()` pattern.
    public static func ensureCurrent(service: any StenographerDaemonService) {
        if current == nil {
            current = SessionsWindowController(service: service)
        }
    }

    public override func close() {
        // performClose NSBeeps on a window that isn't visible — guard, like the
        // sibling UsageWindowController.close() does.
        guard window?.isVisible == true else { return }
        window?.performClose(nil)
    }

    /// Applies the "always on top" and transparency preferences when the window is
    /// built, and keeps them live as the user changes them in settings.
    public override func configureWindow(_ window: NSWindow) {
        setFloating(UserSettings.stenographerSessionsWindowAlwaysOnTop.value)
        setTransparency(UserSettings.stenographerSessionsWindowTransparency.value)
        floatingObserver = UserSettingObserver(
            UserSettings.stenographerSessionsWindowAlwaysOnTop
        ) { [weak self] floating in
            self?.setFloating(floating)
        }
        transparencyCancellable = UserSettings.stenographerSessionsWindowTransparency.$currentValue
            .dropFirst()
            .sink { [weak self] alpha in self?.setTransparency(alpha) }

        // The gear lives in the title bar (the Usage Details pattern) so every
        // window's config button is in the same place; the "last X hours" filter
        // stays in the content header as a list control.
        window.addTitlebarAccessoryViewController(configDialog.makeTitlebarAccessory())
    }

    private init(service: any StenographerDaemonService) {
        let source = StenographerSessionListSource(
            service: service, sinceHours: UserSettings.stenographerSessionsFilterHours.value
        )
        self.listSource = source
        let viewController = Self.makeListViewController(source: source)
        // `claude -p` runs synchronously inside the daemon (up to a 60s budget), so the
        // manual Summarize call must outwait it — StenographerSummarizing's daemon call uses a
        // matching long timeout rather than the short read timeout used for the session list.
        viewController.viewModel.sessionSummarizer = StenographerSummarizing(service: service)
        // The summary line only appears when summaries are switched on. Stenographer's
        // toggle is its own (the daemon does the summarizing), not the toolkit's
        // in-app one, so the window is told where to look.
        viewController.viewModel.summariesEnabled = {
            UserSettings.stenographerAISummariesEnabled.value
        }

        // Header row: the time filter (which sessions to show) plus the gear
        // dialog holding the window's config — summaries on/off with the same
        // provider/model picker as Settings → AI Summaries (both edit the same
        // prefs; `StenographerAIConfigPush` pushes them), then the appearance
        // controls.
        let picker = AISummariesPluginControls.makePicker(service: service)
        self.aiSummariesPicker = picker
        // Wider than the default: the provider picker's row is a popup, a model
        // name and a trailing Choose button, which a checkbox-width dialog crams.
        let dialog = WindowOptionsDialog(title: "Sessions Window", width: 380) {
            [
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: AISummariesPluginControls.enableToggleTitle,
                        setting: UserSettings.stenographerAISummariesEnabled
                    )
                ),
                picker,
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: "Always show above other windows",
                        setting: UserSettings.stenographerSessionsWindowAlwaysOnTop
                    )
                ),
                ComposableSettings.CaptionedSliderView(
                    viewModel: ComposableSettings.RangeViewModel<Double>(
                        title: "Transparency",
                        setting: UserSettings.stenographerSessionsWindowTransparency,
                        minValue: 0.3, maxValue: 1.0
                    ),
                    formatter: { "\(Int((1.0 - $0) * 100))% transparent" }
                ),
                // The two appearance settings this window has, and only those:
                // it draws a list at the app's own type size, so there is no
                // text-size slider here to put back. The summaries switch and
                // its provider picker are not appearance and are left alone.
                WindowOptionsResetButton {
                    let onTop = UserSettings.stenographerSessionsWindowAlwaysOnTop
                    let transparency = UserSettings.stenographerSessionsWindowTransparency
                    onTop.value = onTop.defaultValue
                    transparency.value = transparency.defaultValue
                }
            ]
        }
        self.configDialog = dialog

        let header = Self.makeHeaderView(filter: Self.makeFilterPopup())
        let content = SessionsContentViewController(
            listViewController: viewController,
            headerView: header
        )
        self.sessionsContent = content

        super.init(
            windowID: "sessions",
            contentViewController: content
        )

        // Feed hours-filter changes (from the header popup or anywhere else that
        // edits the pref) into the polling source.
        filterHoursObserver = UserSettingObserver(
            UserSettings.stenographerSessionsFilterHours
        ) { [weak source] hours in
            source?.setSinceHours(hours)
        }

        summariesEnabledObserver = UserSettingObserver(
            UserSettings.stenographerAISummariesEnabled
        ) { [weak viewController] _ in
            viewController?.viewModel.loadSessions()
        }

        self.windowTitle = "Stenographer — Sessions"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 360, height: 300),
            minSize: NSSize(width: Self.minimumWidth, height: 140),
            // The frame persists like every other window's, so the Sessions
            // window comes back where it was left. Only the position and width
            // are the user's: `fitToContent()` re-derives the height from the
            // list once it loads.
            defaultPosition: .topRight
        )

        // SessionListView reports its content height as intrinsic size and posts this
        // when the list changes; mirror the toolkit panel and fit the window to it.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeChanged),
            name: SessionWatcher.SessionListView.contentSizeDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func contentSizeChanged() {
        fitToContent()
    }

    /// The toolkit's session list, told in so many words not to use
    /// Accessibility. Stenographer never asks for that grant, and an app
    /// without it that so much as checks for it (`AXIsProcessTrusted()`) stalls
    /// tccd — and the whole machine — for ~10s. Said here rather than left to
    /// the toolkit's default, so a toolkit bump that flips it can't quietly
    /// bring the freeze back; `SessionsWindowAccessibilityTests` holds it.
    static func makeListViewController(
        source: SessionWatcher.SessionListSource
    ) -> SessionWatcher.SessionListViewController {
        SessionWatcher.SessionListViewController(source: source, usesAccessibility: false)
    }

    /// The narrowest the window may be when no row needs more — `windowSpec.minSize`'s
    /// width, restated because the width fit replaces `minSize.width` outright.
    private static let minimumWidth: CGFloat = 300

    /// Sizes the window to its content: never narrower than the widest row's whole
    /// breadcrumb (`SessionListView.minimumContentWidth`), and as tall as the header
    /// plus the session list's content via the toolkit's shared
    /// `NSWindow.fitHeight(toContentHeight:)` (same helper the toolkit's own panel
    /// uses). Width comes first because the rows' heights don't depend on it — the
    /// output and summary are a fixed number of lines — but a narrower window can't
    /// have been what the list measured. The header is fixed-height; the list drives
    /// the rest and scrolls once the window is capped to the screen.
    private func fitToContent() {
        guard let window else { return }
        window.ensureMinimumContentWidth(
            max(Self.minimumWidth, sessionsContent.listViewController.contentView.minimumContentWidth)
        )
        // The list reports its content height as an intrinsic size. If it hasn't
        // vended one yet (noIntrinsicMetric), there's nothing meaningful to fit to —
        // leave the window at its current size and let the list scroll, rather than
        // collapsing it to just the header height.
        let rawListHeight = sessionsContent.listViewController.view.intrinsicContentSize.height
        guard rawListHeight != NSView.noIntrinsicMetric else { return }
        let headerHeight = sessionsContent.headerView.fittingSize.height
        window.fitHeight(toContentHeight: headerHeight + max(0, rawListHeight))
    }

    /// This window hugs its content the other way round from the usage windows —
    /// the user owns the width, the list owns the height — so it opts into the
    /// move-driven refit explicitly rather than through a `contentSizeProvider`.
    public override var wantsRefitAfterMove: Bool { true }

    /// The height fit is capped to the screen the window is on, so moving it
    /// between displays of different heights changes the answer: dragged to a
    /// shorter screen it has to come down to fit, and to a taller one it can
    /// show the rows the old cap was hiding.
    public override func refitContentAfterMove() {
        fitToContent()
    }

    /// The time-filter popup, bound to `stenographerSessionsFilterHours` so the
    /// selection persists and any other editor of the pref stays in sync.
    private static func makeFilterPopup() -> NSView {
        ComposableSettings.PopupMenuChoiceView(
            viewModel: ComposableSettings.ChoiceViewModel<Int>(
                title: "Show",
                setting: UserSettings.stenographerSessionsFilterHours,
                choices: [
                    .init(label: "Last 6 hours", value: 6),
                    .init(label: "Last 12 hours", value: 12),
                    .init(label: "Last 24 hours", value: 24),
                    .init(label: "Last 48 hours", value: 48),
                    .init(label: "Last 7 days", value: 7 * 24),
                    .init(label: "All sessions", value: 0)
                ]
            )
        )
    }

    /// Lays out the header row: the time filter on the left, padded and full-width
    /// above the session list. The gear now lives in the title bar (added in
    /// `configureWindow`), matching the Usage Details window.
    private static func makeHeaderView(filter: NSView) -> NSView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let stack = NSStackView(views: [filter, spacer])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        // The same 14pt side margin as the session rows, so the filter lines up
        // with the app icons beneath it.
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        // Hug vertically so the header keeps its natural height and the session list
        // below absorbs the remaining vertical space.
        stack.setHuggingPriority(.defaultHigh, for: .vertical)
        return stack
    }
}

/// Wraps the toolkit's session-list VC under a Stenographer header row. The header
/// hugs its content height; the list fills the remaining space and scrolls when the
/// window is capped to the screen.
@MainActor
private final class SessionsContentViewController: NSViewController {
    let listViewController: SessionWatcher.SessionListViewController
    let headerView: NSView

    init(listViewController: SessionWatcher.SessionListViewController, headerView: NSView) {
        self.listViewController = listViewController
        self.headerView = headerView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        // A hairline divider separates the config header strip from the session list —
        // the list's own divider, so it takes the theme's divider colour like the ones
        // between rows (an `NSBox` separator stays system grey whatever the theme).
        let separator = SessionWatcher.SessionWatcherListSeparator()

        // Plain constraints rather than an NSStackView: the list's height has to be
        // *exactly* whatever is left under the header, and a stack decides that from
        // hugging and compression priorities against an intrinsic size that is the
        // list's full content height. Both packings got it wrong — gravity areas left
        // the list at 80pt under a 1300pt window, and `.fill` did the same — because
        // the answer isn't a priority negotiation at all. Pinning the list's bottom to
        // the container says it directly.
        // Autoresizing stays ON for the container: this view becomes the window's
        // content view, and AppKit sizes a content view by its frame. Turning it off
        // leaves nothing tying the view to the window, so it settles at its own
        // fitting size — which is why the header used to float in the middle of a
        // window taller than the list's content.
        let container = NSView()
        let list = listViewController.view
        list.translatesAutoresizingMaskIntoConstraints = false
        addChild(listViewController)
        container.addSubview(headerView)
        container.addSubview(separator)
        container.addSubview(list)

        // The header keeps its natural height; the list is what shrinks, so its own
        // intrinsic content height loses to the pinned bottom edge and the rows past
        // the window's cap scroll instead of being clipped away.
        headerView.setContentHuggingPriority(.required, for: .vertical)
        headerView.setContentCompressionResistancePriority(.required, for: .vertical)
        list.setContentHuggingPriority(.init(rawValue: 1), for: .vertical)
        list.setContentCompressionResistancePriority(.init(rawValue: 1), for: .vertical)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            separator.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            list.topAnchor.constraint(equalTo: separator.bottomAnchor),
            list.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            list.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        self.view = container
    }
}
