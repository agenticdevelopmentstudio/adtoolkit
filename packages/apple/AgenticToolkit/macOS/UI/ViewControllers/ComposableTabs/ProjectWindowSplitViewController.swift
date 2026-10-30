import AppKit
import AgenticDeveloperToolkitUI
import AgenticToolkitCore
import AgenticToolkitCoreUI

/// A project window's content: an optional shelf down the leading edge, and the
/// window's own content — the tabs and their footer — beside it.
///
/// Both halves run the full height of the window, up behind a clear titlebar,
/// and each paints that strip in its own colour, which is what makes the
/// titlebar seamless: there is no band of a third colour across the top. What
/// each half *lays out* starts at the safe area, below the traffic lights and
/// the toolbar, so nothing clickable sits under them.
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

    private let content: NSViewController
    let shelf: ProjectShelfViewController?
    private var shelfItem: NSSplitViewItem?

    /// Keeps each half's strip behind the titlebar in the theme.
    private var themeObserver: ThemePaletteObserver?

    /// Raised while a collapse animates, so the shelf's shrinking width on the
    /// way to zero is not written down as the width the reader chose.
    private var isAnimatingShelf = false

    private var resizeObserver: NSObjectProtocol?

    /// - Parameters:
    ///   - content: The window's content. Laid out from the safe area down;
    ///     the strip above it is painted the project's pane backdrop.
    ///   - shelf: The shelf, or `nil` for a window with none — a host with no
    ///     projects to list. Laid out from the safe area down on the project's
    ///     pane backdrop, which its bordered card sits on.
    init(content: NSViewController, shelf: ProjectShelfViewController?) {
        self.content = content
        self.shelf = shelf
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        if let resizeObserver {
            NotificationCenter.default.removeObserver(resizeObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentHost = SafeAreaHostViewController(child: content)

        if let shelf {
            let shelfHost = SafeAreaHostViewController(child: shelf)
            // The width the shelf opens at, and the reason it is a constraint
            // rather than a divider position: it is what a split view asks the
            // pane for, and it loses to the reader's own drag the moment there
            // is one.
            let width = shelfHost.view.widthAnchor.constraint(
                equalToConstant: CGFloat(UserSettings.projectShelfWidth.value))
            width.priority = .defaultLow
            width.isActive = true

            let item = NSSplitViewItem(viewController: shelfHost)
            item.minimumThickness = 180
            item.maximumThickness = 480
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
            MainActor.assumeIsolated { self?.rememberShelfWidth() }
        }
        themeObserver = ThemePaletteObserver(host: view) { [weak contentHost, weak self] palette in
            contentHost?.backdropColor = NSColor(palette.projectPaneBackdrop)
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
        // The same animation as the Conversations shelf, for the same reason:
        // `item.animator()` alone moves the divider while everything laid out
        // against it jumps to its final place on the first frame.
        isAnimatingShelf = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            item.animator().isCollapsed = !visible
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.isAnimatingShelf = false
                self?.onShelfVisibilityChange?()
                completion?()
            }
        }
        onShelfVisibilityChange?()
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
        if item.isCollapsed == layout.isVisible {
            item.isCollapsed = !layout.isVisible
            onShelfVisibilityChange?()
        }
        guard layout.isVisible, layout.width >= item.minimumThickness else { return }
        splitView.layoutSubtreeIfNeeded()
        splitView.setPosition(layout.width, ofDividerAt: 0)
    }

    /// Writes down the shelf's width whenever the reader drags the divider.
    private func rememberShelfWidth() {
        guard !isAnimatingShelf, let item = shelfItem, !item.isCollapsed else { return }
        let width = item.viewController.view.frame.width
        // Zero while the window is still being put together, before the
        // first layout has given the shelf any room at all.
        guard width >= item.minimumThickness else { return }
        UserSettings.projectShelfWidth.value = Double(width)
    }
}

/// A shelf's visibility and width — what one project window hands the next.
public struct ProjectShelfLayout: Sendable, Equatable {
    public var isVisible: Bool
    public var width: CGFloat
}

/// Hosts one view controller below the window's safe area, over a backdrop that
/// fills the whole pane — the strip behind the clear titlebar included.
@MainActor
private final class SafeAreaHostViewController: NSViewController {

    private let child: NSViewController

    var backdropColor: NSColor = .clear {
        didSet { view.layer?.backgroundColor = backdropColor.cgColor }
    }

    init(child: NSViewController) {
        self.child = child
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
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
            childView.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor),
            childView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        self.view = container
    }
}
