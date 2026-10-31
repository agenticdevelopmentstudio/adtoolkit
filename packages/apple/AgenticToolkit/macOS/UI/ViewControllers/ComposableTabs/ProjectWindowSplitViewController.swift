import AppKit
import AgenticDeveloperToolkitUI
import AgenticToolkitCore
import AgenticToolkitCoreUI

/// A project window's content: an optional shelf down the leading edge, and the
/// window's own content — the tabs and their footer — beside it.
///
/// Both halves run the full height of the window, up behind a clear titlebar,
/// and each paints that strip in its own colour, which is what makes the
/// titlebar seamless: there is no band of a third colour across the top. The
/// content is laid out from the safe area, below the toolbar; the shelf is
/// given the whole height, because its card encloses the traffic lights and
/// lays out its own controls from the safe area.
///
/// The shelf is the Conversations shelf's shape, for the same reasons: a plain
/// split item rather than a sidebar one, because sidebar material is drawn by
/// the appearance and reaches no theme; and a plain `NSSplitView`, because the
/// themed one's divider colour is what trapped Conversations at launch.
@MainActor
final class ProjectWindowSplitViewController: NSSplitViewController {

    /// Called after the shelf has finished showing or hiding, so the window can
    /// repaint the toggle as the state it reached.
    var onShelfVisibilityChange: (() -> Void)?

    /// Called as the shelf's width is about to change beside the content —
    /// sliding out or away, a divider drag — and once it has finished: at the
    /// end of a slide, or once a drag has rested. Not called for a window
    /// resize, which moves the content's edge without moving the shelf's. The
    /// window uses the pair to hold each pane at its share of the width (see
    /// `ComposableTabsViewController.holdThicknessFractions()`).
    var onShelfWillMove: (() -> Void)?
    var onShelfDidMove: (() -> Void)?

    /// How long a drag must rest before it counts as finished. AppKit has no
    /// "the user let go" notification for a divider.
    private static let dragSettleDelay: Duration = .milliseconds(250)
    private var dragSettle: Task<Void, Never>?

    /// The split's width at the last resize, which is what tells a shelf move
    /// (same width, divider moved) from a window resize (width changed).
    private var lastSplitWidth: CGFloat = 0
    private var isShelfMoving = false

    /// Raised while the shelf slides in or out, or is adopted, so the steps
    /// along the way neither start nor end the hold its caller took before
    /// it started. Sliding *out*, AppKit lays the content out at its final
    /// width before the first step, so shares read at a step would already be
    /// the lopsided ones.
    private var holdsSharesFromBeforeSlide = false

    private let content: NSViewController
    let shelf: ProjectShelfViewController?
    private var shelfItem: NSSplitViewItem?

    /// The shelf host's width: the width it opens at, at a priority any drag
    /// beats; and, raised above everything the split view holds, what walks
    /// the shelf in and out during a slide.
    private var shelfWidth: NSLayoutConstraint?

    /// Keeps each half's strip behind the titlebar in the theme.
    private var themeObserver: ThemePaletteObserver?

    /// Raised while a collapse animates, so the shelf's shrinking width on the
    /// way to zero is not written down as the width the reader chose.
    private var isAnimatingShelf = false

    private var resizeObserver: NSObjectProtocol?
    private var willResizeObserver: NSObjectProtocol?

    /// - Parameters:
    ///   - content: The window's content. Laid out from the safe area down;
    ///     the strip above it is painted the window background.
    ///   - shelf: The shelf, or `nil` for a window with none — a host with no
    ///     projects to list. Given the full height on the project's pane
    ///     backdrop, which its bordered card sits on.
    init(content: NSViewController, shelf: ProjectShelfViewController?) {
        self.content = content
        self.shelf = shelf
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        dragSettle?.cancel()
        shelfSlide?.link.invalidate()
        for observer in [resizeObserver, willResizeObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentHost = SafeAreaHostViewController(child: content)

        if let shelf {
            let shelfHost = SafeAreaHostViewController(child: shelf, pinsToSafeArea: false)
            // The width the shelf opens at, and the reason it is a constraint
            // rather than a divider position: it is what a split view asks the
            // pane for, and it loses to the reader's own drag the moment there
            // is one.
            let width = shelfHost.view.widthAnchor.constraint(
                equalToConstant: CGFloat(UserSettings.projectShelfWidth.value))
            width.priority = .defaultLow
            width.isActive = true
            shelfWidth = width

            let item = NSSplitViewItem(viewController: shelfHost)
            item.minimumThickness = Self.shelfMinimumWidth
            item.maximumThickness = Self.shelfMaximumWidth
            item.canCollapse = true
            // The window keeps its size and the tabs give up the room, which
            // is what a navigator does in Xcode.
            item.collapseBehavior = .preferResizingSiblingsWithFixedSplitView
            // Below the content's, so resizing the window resizes the tabs and
            // leaves the shelf the width the reader gave it.
            item.holdingPriority = .defaultLow + 1
            item.isCollapsed = !UserSettings.projectShelfVisible.value
            addSplitViewItem(item)
            shelfItem = item
        }

        let contentItem = NSSplitViewItem(viewController: contentHost)
        contentItem.minimumThickness = 300
        addSplitViewItem(contentItem)

        splitView.dividerStyle = .thin
        // A notification rather than the delegate method: the split view's
        // delegate is this controller's superclass, which does not offer
        // `splitViewDidResizeSubviews(_:)` up for overriding.
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSSplitView.didResizeSubviewsNotification,
            object: splitView,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rememberShelfWidth()
                self?.shelfDidMove()
            }
        }
        willResizeObserver = NotificationCenter.default.addObserver(
            forName: NSSplitView.willResizeSubviewsNotification,
            object: splitView,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.shelfWillMove() }
        }
        themeObserver = ThemePaletteObserver(host: view) { [weak contentHost, weak self] palette in
            // The window background, the shelf card's and the tab list's
            // fill, so the strip behind the title reads as the same window
            // rather than as a titlebar laid across it.
            contentHost?.backdropColor = palette.nsColor(.windowBackground)
            if let shelfHost = self?.shelfItem?.viewController as? SafeAreaHostViewController {
                shelfHost.backdropColor = NSColor(palette.projectPaneBackdrop)
            }
        }
    }

    // MARK: - Shelf

    var hasShelf: Bool { shelfItem != nil }

    var isShelfVisible: Bool {
        guard let shelfItem else { return false }
        return !shelfItem.isCollapsed
    }

    @objc func toggleShelf() { setShelfVisible(!isShelfVisible) }

    /// Slides the shelf out or away, doing nothing if it is already there. The
    /// choice is remembered for every project window — see
    /// `UserSettings.projectShelfVisible`.
    ///
    /// - Parameter completion: Run once the shelf has reached `visible` — at
    ///   once if it was already there. Focus waits for it: a field still
    ///   sliding in from zero width takes the keyboard and then loses it.
    func setShelfVisible(_ visible: Bool, completion: (@MainActor () -> Void)? = nil) {
        guard let item = shelfItem else { return }
        guard item.isCollapsed == visible else {
            completion?()
            return
        }
        UserSettings.projectShelfVisible.value = visible
        if !visible { shelf?.resignFocus() }
        guard view.window != nil else {
            item.isCollapsed = !visible
            onShelfVisibilityChange?()
            completion?()
            return
        }
        finishShelfSlide()
        isAnimatingShelf = true
        onShelfWillMove?()
        holdsSharesFromBeforeSlide = true

        // Down to nothing on the way, so the divider can be walked to and from
        // zero; put back when the slide ends.
        item.minimumThickness = 0
        let from = visible ? 0 : item.viewController.view.frame.width
        shelfWidth?.constant = from
        shelfWidth?.priority = Self.slidingWidthPriority
        if visible {
            // Uncollapsed at zero width, held there by the raised width, so
            // the shelf never shows at its full width before the slide begins.
            //
            // The first uncollapse after a launch that began collapsed grows
            // the window by the shelf's remembered width, as if the shelf were
            // being added beside the content rather than into it; the shelf
            // takes its room from the panes, so the window is put back.
            let windowFrame = view.window?.frame
            item.isCollapsed = false
            if let window = view.window, let windowFrame, window.frame != windowFrame {
                window.setFrame(windowFrame, display: false)
            }
            splitView.layoutSubtreeIfNeeded()
        }
        let target = visible ? Self.openShelfWidth : 0
        let link = view.displayLink(target: self, selector: #selector(stepShelfSlide(_:)))
        shelfSlide = ShelfSlide(
            link: link,
            start: CACurrentMediaTime(),
            origin: from,
            target: target,
            completion: completion)
        // The content gives up what the shelf gains, point for point. The
        // slide starts once the panes have drawn for it.
        content.view.beginAnimatedResize(widthChange: from - target) { [weak self] in
            // Landed already, by a second toggle, if this is not its slide.
            guard let self, shelfSlide?.link === link else { return }
            shelfSlide?.start = CACurrentMediaTime()
            link.add(to: .main, forMode: .common)
        }
        onShelfVisibilityChange?()
    }

    // MARK: - Sliding

    /// A slide in progress: the shelf's width walked from `origin` to `target`
    /// one frame at a time.
    ///
    /// Walked by hand rather than by `item.animator().isCollapsed`, because
    /// that animates the panes' frames on Core Animation's clock while laying
    /// everything inside them out once, at the final size — so a web view
    /// jumps to its end width on the first frame and its pane slides to meet
    /// it, with its trailing edge nowhere near the pane's on the way. A real
    /// layout pass per frame gives every view inside the panes the frame its
    /// constraints say, on every frame, as a live window resize does.
    ///
    /// The width is walked through the shelf host's own width constraint, not
    /// `setPosition(_:ofDividerAt:)`. A divider set near zero collapses a
    /// collapsible item, and a divider set anywhere is undone by the next
    /// layout pass in favour of that constraint, so a walked divider fought
    /// the layout on every frame and the shelf jumped rather than slid.
    private struct ShelfSlide {
        let link: CADisplayLink
        /// Reset when the slide actually starts, once the panes are ready.
        var start: CFTimeInterval
        let origin: CGFloat
        let target: CGFloat
        let completion: (@MainActor () -> Void)?
    }

    private static let shelfSlideDuration: CFTimeInterval = 0.2

    /// Above every holding priority and the reader's drag, below required so
    /// the content's minimum width still wins.
    private static let slidingWidthPriority = NSLayoutConstraint.Priority(999)
    private var shelfSlide: ShelfSlide?

    /// The width the shelf opens to: the one the reader last gave it, within
    /// the item's bounds.
    private static var openShelfWidth: CGFloat {
        min(max(CGFloat(UserSettings.projectShelfWidth.value), shelfMinimumWidth), shelfMaximumWidth)
    }

    private static let shelfMinimumWidth: CGFloat = 180
    private static let shelfMaximumWidth: CGFloat = 480

    @objc private func stepShelfSlide(_ link: CADisplayLink) {
        guard let slide = shelfSlide else {
            link.invalidate()
            return
        }
        let elapsed = (link.targetTimestamp - slide.start) / Self.shelfSlideDuration
        let progress = CGFloat(min(max(elapsed, 0), 1))
        // Ease in and out, as the animation it replaces did.
        let eased = progress * progress * (3 - 2 * progress)
        shelfWidth?.constant = slide.origin + (slide.target - slide.origin) * eased
        splitView.layoutSubtreeIfNeeded()
        if progress >= 1 { finishShelfSlide() }
    }

    /// Ends the slide in progress, at its destination, if there is one. A
    /// second toggle mid-slide lands the first before it starts its own.
    private func finishShelfSlide() {
        guard let slide = shelfSlide, let item = shelfItem else { return }
        shelfSlide = nil
        slide.link.invalidate()
        shelfWidth?.constant = slide.target
        splitView.layoutSubtreeIfNeeded()
        if slide.target == 0 { item.isCollapsed = true }
        item.minimumThickness = Self.shelfMinimumWidth
        // Back to the width the shelf opens at, at the priority a drag beats.
        shelfWidth?.constant = Self.openShelfWidth
        shelfWidth?.priority = .defaultLow
        splitView.layoutSubtreeIfNeeded()
        content.view.endAnimatedResize()
        content.view.layoutSubtreeIfNeeded()
        isAnimatingShelf = false
        holdsSharesFromBeforeSlide = false
        onShelfDidMove?()
        onShelfVisibilityChange?()
        slide.completion?()
    }

    /// ⌘0 and ⌘1: show the shelf on `panel` with the keyboard in its filter,
    /// or — when it is already showing that panel — put the shelf away.
    func toggleShelfPanel(_ panel: ProjectShelfPanel) {
        guard let shelf else { return }
        if isShelfVisible, shelf.group.panel == panel {
            setShelfVisible(false)
            return
        }
        shelf.show(panel)
        setShelfVisible(true) { [weak shelf] in shelf?.focusFilter() }
    }

    /// What the shelf looks like now, for a window about to take this one's
    /// place. Each active project's window has a shelf of its own, and the
    /// swap must not visibly move one.
    var shelfLayout: ProjectShelfLayout {
        ProjectShelfLayout(
            isVisible: isShelfVisible,
            width: shelfItem.map { $0.viewController.view.frame.width } ?? 0
        )
    }

    /// Takes on `layout` at once, without animating — this window is about to
    /// be ordered in where another stood.
    func adoptShelfLayout(_ layout: ProjectShelfLayout) {
        guard let item = shelfItem else { return }
        // The panes keep their shares through this too, read before the shelf
        // moves for the same reason a slide's are.
        onShelfWillMove?()
        holdsSharesFromBeforeSlide = true
        defer {
            // Laid out while the shares still hold, or the pass after the
            // release would be AppKit's own lopsided one.
            splitView.layoutSubtreeIfNeeded()
            holdsSharesFromBeforeSlide = false
            onShelfDidMove?()
        }
        if item.isCollapsed == layout.isVisible {
            item.isCollapsed = !layout.isVisible
            onShelfVisibilityChange?()
        }
        guard layout.isVisible, layout.width >= item.minimumThickness else { return }
        shelfWidth?.constant = layout.width
        splitView.layoutSubtreeIfNeeded()
        splitView.setPosition(layout.width, ofDividerAt: 0)
    }

    /// The split's own width has not changed, so what is about to move is the
    /// divider: the shelf, not the window.
    private func shelfWillMove() {
        guard shelfItem != nil else { return }
        let width = splitView.bounds.width
        defer { lastSplitWidth = width }
        isShelfMoving = width > 0 && width == lastSplitWidth
        if isShelfMoving, !holdsSharesFromBeforeSlide { onShelfWillMove?() }
    }

    /// A drag's steps each come through here; it is finished once they stop.
    private func shelfDidMove() {
        guard isShelfMoving else { return }
        isShelfMoving = false
        guard !holdsSharesFromBeforeSlide else { return }
        dragSettle?.cancel()
        dragSettle = Task { [weak self] in
            try? await Task.sleep(for: Self.dragSettleDelay)
            guard !Task.isCancelled, let self, !self.holdsSharesFromBeforeSlide else { return }
            self.onShelfDidMove?()
        }
    }

    /// Writes down the shelf's width whenever the reader drags the divider.
    private func rememberShelfWidth() {
        guard !isAnimatingShelf, let item = shelfItem, !item.isCollapsed else { return }
        let width = item.viewController.view.frame.width
        // Zero while the window is still being put together, before the
        // first layout has given the shelf any room at all.
        guard width >= item.minimumThickness else { return }
        UserSettings.projectShelfWidth.value = Double(width)
        // Kept in step, so the next layout pass does not pull the shelf back
        // to the width it had before the drag.
        shelfWidth?.constant = width
    }
}

/// A shelf's visibility and width — what one project window hands the next.
public struct ProjectShelfLayout: Sendable, Equatable {
    public var isVisible: Bool
    public var width: CGFloat
}

/// Hosts one view controller — below the window's safe area, or over the whole
/// height — on a backdrop that fills the whole pane, the strip behind the clear
/// titlebar included.
@MainActor
private final class SafeAreaHostViewController: NSViewController {

    private let child: NSViewController
    private let pinsToSafeArea: Bool

    var backdropColor: NSColor = .clear {
        didSet { view.layer?.backgroundColor = backdropColor.cgColor }
    }

    /// - Parameter pinsToSafeArea: Whether the child starts below the
    ///   titlebar, or is given the whole height to place things itself.
    init(child: NSViewController, pinsToSafeArea: Bool = true) {
        self.child = child
        self.pinsToSafeArea = pinsToSafeArea
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        // A shelf sliding in is narrower than its contents; show the part
        // that fits rather than letting the rest spill over the panes.
        container.clipsToBounds = true
        addChild(child)
        let childView = child.view
        childView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(childView)

        // The leading and trailing edges give below required, as the
        // Conversations shelf's do: a collapsing pane animates to zero width,
        // and a required edge is one AppKit has to break, loudly, to get there.
        let horizontal = [
            childView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ]
        for constraint in horizontal { constraint.priority = .defaultHigh }

        NSLayoutConstraint.activate(horizontal + [
            childView.topAnchor.constraint(
                equalTo: pinsToSafeArea ? container.safeAreaLayoutGuide.topAnchor : container.topAnchor),
            childView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        self.view = container
    }
}
