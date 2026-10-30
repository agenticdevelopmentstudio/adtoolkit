import AppKit
import Combine
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// Where the keyboard was in a shelf, so it can be put back in the same place
/// in the shelf of the window swapped in for this one.
public enum ProjectShelfFocus: Sendable {
    case filter
    case list
    case elsewhere
}

/// A project window's shelf, shaped like Xcode's navigator: a bordered card
/// with a full-width bar of panel buttons along its top, the chosen panel
/// beneath, and one filter field along the bottom that filters whichever
/// panel is up.
///
/// The panels are the project browser and the window's active projects; more
/// join by adding a `ProjectShelfPanel` case and a child here. Which panel is
/// up and what each filter holds live on the window's `ProjectWindowGroup`, not
/// here, because every project window in the group has a shelf of its own and
/// all of them show the same state (`dry`).
@MainActor
public final class ProjectShelfViewController: NSViewController {

    /// Called when a project is chosen in the browser: load it into the window.
    public var onLoadProject: ((GitRepo) -> Void)?
    /// Called when an active project is chosen: put it on screen.
    public var onShowActiveProject: ((UUID) -> Void)?
    /// Called by an active project's close box.
    public var onCloseActiveProject: ((UUID) -> Void)?

    public let group: ProjectWindowGroup

    private let browser: ProjectBrowserViewController
    private let activeProjects: ActiveProjectsViewController
    private let searchField = ThemedSearchField()
    /// One button per panel — Xcode's navigator bar, shared (`dry`).
    private let panelBar = IconTabBar(
        items: ProjectShelfPanel.allCases.map { .init(id: $0.rawValue, symbol: $0.symbol, title: $0.title) },
        accessibilityPrefix: "project-shelf.panel.")
    private var cancellables: Set<AnyCancellable> = []

    public init(coordinator: ProjectsCoordinator, group: ProjectWindowGroup) {
        self.group = group
        self.browser = ProjectBrowserViewController(coordinator: coordinator, mode: .browser, showsFilterField: false)
        self.activeProjects = ActiveProjectsViewController(coordinator: coordinator, group: group)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - View

    public override func loadView() {
        let container = PointerFocusRegionView()
        let backdrop = ThemedBackgroundView(role: .windowBackground)
        backdrop.setAccessibilityElement(false)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(backdrop)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: container.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Inset from the pane and drawn on the project backdrop the split view
        // paints behind it — the border is what makes it read as a navigator
        // rather than as more window. It runs the full height of the window,
        // up behind the clear titlebar, so the traffic lights and the shelf
        // toggle sit inside it, as they do in Xcode's navigator; what is laid
        // out in it starts below them, at the safe area.
        // `outline`, the stronger stroke: `border` is a hairline meant to sit
        // between two things and vanished against the pane backdrop.
        let card = ThemedBox(fill: .windowBackground, stroke: .outline, cornerRadius: 12)
        card.layer?.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        let bar = panelBar
        bar.onSelect = { [weak self] raw in
            guard let panel = ProjectShelfPanel(rawValue: raw) else { return }
            self?.choosePanel(panel)
        }
        let topRule = ThemedSeparatorView(role: .border)
        let bottomRule = ThemedSeparatorView(role: .border)

        let panelHost = NSView()
        panelHost.translatesAutoresizingMaskIntoConstraints = false
        for child in [browser as NSViewController, activeProjects] {
            addChild(child)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            panelHost.addSubview(child.view)
            NSLayoutConstraint.activate([
                child.view.topAnchor.constraint(equalTo: panelHost.topAnchor),
                child.view.leadingAnchor.constraint(equalTo: panelHost.leadingAnchor),
                child.view.trailingAnchor.constraint(equalTo: panelHost.trailingAnchor),
                child.view.bottomAnchor.constraint(equalTo: panelHost.bottomAnchor)
            ])
        }

        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(filterChanged(_:))
        searchField.sendsWholeSearchString = false
        searchField.sendsSearchStringImmediately = true
        searchField.controlSize = .small
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.accessibilityID("project-shelf.filter")

        for view in [bar, topRule, panelHost, bottomRule, searchField] {
            card.addSubview(view)
        }

        // The leading and trailing edges give below required for the reason
        // `SafeAreaHostViewController`'s do: the shelf animates to zero width
        // on its way out.
        let edges = [
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ]
        for constraint in edges { constraint.priority = .defaultHigh }

        NSLayoutConstraint.activate(edges + [
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),

            bar.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 2),
            bar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            bar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),

            topRule.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 6),
            topRule.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            topRule.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            panelHost.topAnchor.constraint(equalTo: topRule.bottomAnchor),
            panelHost.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            panelHost.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            panelHost.bottomAnchor.constraint(equalTo: bottomRule.topAnchor),

            bottomRule.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            bottomRule.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            searchField.topAnchor.constraint(equalTo: bottomRule.bottomAnchor, constant: 6),
            searchField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            searchField.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -6)
        ])

        self.view = container
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Choosing from the browser makes the project active, so the shelf
        // moves to where it now is: the active list, with it highlighted. Its
        // filter is cleared so nothing typed there earlier can hide it.
        browser.onChoose = { [weak self] repo in
            guard let self else { return }
            self.onLoadProject?(repo)
            self.group.filterText[.activeProjects] = ""
            self.group.panel = .activeProjects
        }
        activeProjects.onChoose = { [weak self] id in self?.onShowActiveProject?(id) }
        activeProjects.onClose = { [weak self] id in self?.onCloseActiveProject?(id) }

        applyPanel(group.panel)
        applyFilterText(group.filterText)
        // `receive(on:)` because `@Published` emits from `willSet`.
        group.$panel
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] panel in self?.applyPanel(panel) }
            .store(in: &cancellables)
        group.$filterText
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] text in self?.applyFilterText(text) }
            .store(in: &cancellables)
    }

    // MARK: - Panels

    /// A click on the panel's button. The keyboard goes with it: a button does
    /// not take the keyboard, so without this the arrow keys stayed wherever
    /// they were — a pane — and beeped instead of moving through the panel
    /// the user had just picked (principle-of-least-astonishment).
    private func choosePanel(_ panel: ProjectShelfPanel) {
        show(panel)
        focusList()
    }

    /// Shows `panel`. The group is what is changed, so every shelf in it
    /// follows.
    public func show(_ panel: ProjectShelfPanel) {
        group.panel = panel
        applyPanel(panel)
    }

    private func applyPanel(_ panel: ProjectShelfPanel) {
        guard isViewLoaded else { return }
        // A list the keyboard is in is about to be hidden; the keys follow to
        // the list taking its place rather than going on into one nobody can
        // see. Choosing in the browser lands here, on its way to Active
        // Projects.
        let keysInList = focus == .list
        browser.view.isHidden = panel != .browser
        activeProjects.view.isHidden = panel != .activeProjects
        searchField.placeholderString = panel.filterPlaceholder
        // `ThemedSearchField` themes the placeholder it was given; a new one
        // needs the palette applied again.
        searchField.applyTheme(view.resolvedThemeScope.palette)
        let text = group.filterText[panel] ?? ""
        if searchField.stringValue != text { searchField.stringValue = text }
        panelBar.selectedID = panel.rawValue
        if keysInList { focusList() }
    }

    // MARK: - Filter

    private func applyFilterText(_ text: [ProjectShelfPanel: String]) {
        guard isViewLoaded else { return }
        browser.setFilterQuery(text[.browser] ?? "")
        activeProjects.setFilterQuery(text[.activeProjects] ?? "")
        let current = text[group.panel] ?? ""
        if searchField.stringValue != current { searchField.stringValue = current }
    }

    @objc private func filterChanged(_ sender: Any?) {
        typed(searchField.stringValue)
    }

    private func typed(_ text: String) {
        guard group.filterText[group.panel] != text else { return }
        group.filterText[group.panel] = text
    }

    /// The panel on screen's handling of a key typed in the filter field.
    private func handleFilterCommand(_ commandSelector: Selector) -> Bool {
        switch group.panel {
        case .browser: browser.handleFilterCommand(commandSelector)
        case .activeProjects: activeProjects.handleFilterCommand(commandSelector)
        }
    }

    // MARK: - Focus

    /// Where the keyboard is, as far as this shelf is concerned.
    public var focus: ProjectShelfFocus {
        guard isViewLoaded, let responder = view.window?.firstResponder else { return .elsewhere }
        if let editor = responder as? NSTextView, editor.isFieldEditor,
           (editor.delegate as? NSSearchField) === searchField {
            return .filter
        }
        if let responderView = responder as? NSView, responderView.isDescendant(of: view) {
            return .list
        }
        return .elsewhere
    }

    /// Puts the keyboard back where `focus` says, in this shelf.
    public func restore(focus: ProjectShelfFocus) {
        switch focus {
        case .filter: focusFilter()
        case .list: focusList()
        case .elsewhere: break
        }
    }

    public func focusFilter() {
        view.window?.makeFirstResponder(searchField)
    }

    public func focusList() {
        switch group.panel {
        case .browser: browser.focusList()
        case .activeProjects: activeProjects.focusList()
        }
    }

    /// Gives the keyboard up if the shelf holds it — for a shelf about to
    /// collapse, which must not keep typing going into a list nobody can see.
    public func resignFocus() {
        guard focus != .elsewhere, let window = view.window else { return }
        window.makeFirstResponder(nil)
    }

    /// Highlights `repoID` in both panels without choosing it: the window
    /// saying which project it is showing.
    public func reveal(repoID: UUID) {
        browser.selectRepo(id: repoID)
        activeProjects.highlight(repoID: repoID)
    }
}

extension ProjectShelfViewController: NSSearchFieldDelegate {

    public func controlTextDidChange(_ notification: Notification) {
        typed(searchField.stringValue)
    }

    public func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        handleFilterCommand(commandSelector)
    }
}
