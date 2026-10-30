import AppKit
import AgenticDeveloperToolkitUI
import AgenticToolkitCore
import AgenticToolkitCoreUI

/// A window that carries a project shelf — what ⌘0 and ⌘1 act on. Both
/// halves of a project window group conform: the window of the project on
/// screen, and the empty window shown while the group has no project.
@MainActor
public protocol ProjectShelfWindow: AnyObject {
    var projectShelf: ProjectShelfViewController? { get }
    /// The shelf's visibility and width, carried from one window of a group to
    /// the next so a swap moves nothing.
    var shelfLayout: ProjectShelfLayout { get }
    func adoptShelfLayout(_ layout: ProjectShelfLayout)
    func toggleShelfPanel(_ panel: ProjectShelfPanel)
}

extension ComposableTabsWindowController: ProjectShelfWindow {
    public var projectShelf: ProjectShelfViewController? { shelf }
}

/// A project window with no project in it: a new window from File ▸ New
/// Project Window, or one whose last active project was closed.
///
/// It is a project window in every way that shows — the seamless titlebar,
/// the shelf and its toggle beside the traffic lights — with the project's
/// backdrop where the panes would be, so choosing a project in its shelf
/// swaps the project's window in without anything visibly moving.
@MainActor
public final class EmptyProjectWindowController: SingleWindowController {

    public let shelf: ProjectShelfViewController
    private let windowContent: ProjectWindowSplitViewController
    private var backdropObserver: ThemePaletteObserver?

    /// Stored for the reason `ComposableTabsWindowController.toolbarDelegate`
    /// is: `NSToolbar.delegate` is weak.
    private lazy var toolbarDelegate = WindowToolbarBuilder.Delegate(
        items: [
            .button(
                identifier: .projectToggleShelf,
                symbol: "sidebar.left",
                label: "Projects",
                action: #selector(EmptyProjectWindowController.toggleShelf)),
            .flexibleSpace
        ],
        target: self,
        navigationalItems: [.projectToggleShelf]
    )

    /// The window id an empty window of group `groupID` saves its frame
    /// under.
    public static func windowID(for groupID: UUID) -> String {
        "project.window.empty.\(groupID.uuidString)"
    }

    public init(groupID: UUID, shelf: ProjectShelfViewController) {
        self.shelf = shelf
        let windowContent = ProjectWindowSplitViewController(content: BlankProjectContentViewController(), shelf: shelf)
        self.windowContent = windowContent
        super.init(windowID: Self.windowID(for: groupID), contentViewController: windowContent)
        self.windowSpec = WindowSpec(
            defaultSize: NSSize(width: 800, height: 500),
            minSize: NSSize(width: 400, height: 300),
            defaultPosition: .center,
            persistsFrame: true
        )
        self.windowTitle = "Projects"
        self.windowStyleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        self.minSize = NSSize(width: 400, height: 300)
        windowContent.onShelfVisibilityChange = { [weak self] in
            self?.refreshShelfToggleAppearance()
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// The same chrome as a project window's — see
    /// `ComposableTabsWindowController.configureWindow(_:)`.
    public override func configureWindow(_ window: NSWindow) {
        super.configureWindow(window)
        window.toolbar = toolbarDelegate.makeToolbar(identifier: "project.empty.toolbar")
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.tabbingMode = .disallowed
        window.backgroundColor = NSColor(ThemePaletteObserver.currentPalette.projectPaneBackdrop)
        backdropObserver = ThemePaletteObserver(host: windowContent.view) { [weak self] palette in
            self?.window?.backgroundColor = NSColor(palette.projectPaneBackdrop)
            self?.refreshShelfToggleAppearance()
        }
    }

    public override func showWindow(_ sender: Any?) {
        if window == nil { loadWindow() }
        super.showWindow(sender)
        refreshShelfToggleAppearance()
    }

    // MARK: - Shelf

    public var shelfLayout: ProjectShelfLayout { windowContent.shelfLayout }

    public func adoptShelfLayout(_ layout: ProjectShelfLayout) {
        windowContent.adoptShelfLayout(layout)
    }

    @objc public func toggleShelf() {
        windowContent.toggleShelf()
    }

    /// Shows the shelf with the keyboard in its filter — a new window has
    /// nothing in it but the question of which project to load.
    public func showShelfForChoosing() {
        shelf.show(.browser)
        windowContent.setShelfVisible(true) { [weak shelf] in shelf?.focusFilter() }
    }

    private func refreshShelfToggleAppearance() {
        guard let button = toolbarDelegate.button(for: .projectToggleShelf) else { return }
        WindowToolbarBuilder.applyDisclosureAppearance(
            to: button,
            disclosed: windowContent.isShelfVisible,
            outlineSymbol: "sidebar.left",
            filledSymbol: "sidebar.left",
            showTooltip: "Show Projects",
            hideTooltip: "Hide Projects")
    }
}

extension EmptyProjectWindowController: ProjectShelfWindow {
    public var projectShelf: ProjectShelfViewController? { shelf }

    public func toggleShelfPanel(_ panel: ProjectShelfPanel) {
        windowContent.toggleShelfPanel(panel)
    }
}

/// Where a project's panes would be: the pane backdrop and one quiet line.
@MainActor
private final class BlankProjectContentViewController: NSViewController {

    private var observer: ThemePaletteObserver?

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        let label = ThemedLabel(role: .tertiaryText, textRole: .body)
        label.stringValue = "No project — choose one in the Project Browser."
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityID("project.empty.message")
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20)
        ])
        observer = ThemePaletteObserver(host: container) { [weak container] palette in
            container?.layer?.backgroundColor = NSColor(palette.projectPaneBackdrop).cgColor
        }
        self.view = container
    }
}
