import AppKit
import Combine
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// The projects a project window has open — its shelf's second panel.
///
/// Every row is a project whose window is built and running, shown or not, so
/// choosing one is a swap rather than a load. The list follows the window's
/// `ProjectWindowGroup`; it owns nothing but the highlight.
///
/// Moving the highlight is choosing: an arrow key, a click, or — while the
/// list or the shelf's filter has the keyboard — the pointer moving onto a
/// row puts that project on screen at once, with no Return needed. That is
/// only affordable because every project here is already running.
@MainActor
public final class ActiveProjectsViewController: NSViewController {

    /// Called to put a project on screen: the user moved the highlight onto
    /// it, or pressed Return or Enter.
    public var onChoose: ((UUID) -> Void)?
    /// Called by a row's close box: close the project and drop it from the
    /// list.
    public var onClose: ((UUID) -> Void)?

    private let coordinator: ProjectsCoordinator
    private let group: ProjectWindowGroup
    private let table = HoverTableView(role: .windowBackground)
    private let scrollView = ThemedScrollView()
    private let emptyLabel = ThemedLabel(role: .tertiaryText, textRole: .body)
    private var rows: [GitRepo] = []
    private var query = ""
    private var hoveredRow = -1
    /// Raised while the list moves its own highlight to follow the window —
    /// the shown project, a reload — so that move is not taken for the user
    /// choosing a project.
    private var isFollowingWindow = false
    private var cancellables: Set<AnyCancellable> = []
    private var changeObserver: NSObjectProtocol?

    public init(coordinator: ProjectsCoordinator, group: ProjectWindowGroup) {
        self.coordinator = coordinator
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    /// The highlighted project.
    public var highlightedRepoID: UUID? {
        let row = table.selectedRow
        return rows.indices.contains(row) ? rows[row].id : nil
    }

    // MARK: - View

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("project"))
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 44
        table.style = .inset
        table.allowsEmptySelection = true
        table.allowsMultipleSelection = false
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(rowClicked(_:))
        table.onHover = { [weak self] row in self?.hover(row: row) }
        table.onReturn = { [weak self] in self?.chooseHighlighted() }
        table.accessibilityID("active-projects.table")

        scrollView.documentView = table
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.alignment = .center
        emptyLabel.maximumNumberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        emptyLabel.accessibilityID("active-projects.empty")

        container.addSubview(scrollView)
        container.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        self.view = container
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        reload()
        // `receive(on:)` because `@Published` emits from `willSet`: reading
        // the group back in the sink would see the value it is leaving.
        group.$activeRepoIDs
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)
        group.$selectedRepoID
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] id in
                guard let self, let id else { return }
                self.highlight(repoID: id)
            }
            .store(in: &cancellables)
        // A rename shows up here as it does in the browser.
        changeObserver = NotificationCenter.default.addObserver(
            forName: ProjectsCoordinator.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
    }

    // MARK: - From the shelf

    /// Puts the keyboard in the list.
    public func focusList() {
        view.window?.makeFirstResponder(table)
    }

    /// Filters the list by `text`, typed into the shelf's field.
    public func setFilterQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed != query else { return }
        query = trimmed
        if isViewLoaded { reload() }
    }

    /// The list's half of the shelf filter's keys: ↑ and ↓ move the
    /// highlight, Return chooses it. There are no folders here, so ← and →
    /// stay the field's.
    public func handleFilterCommand(_ commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            chooseHighlighted()
            return true
        case #selector(NSResponder.moveDown(_:)):
            moveHighlight(by: 1)
            return true
        case #selector(NSResponder.moveUp(_:)):
            moveHighlight(by: -1)
            return true
        default:
            return false
        }
    }

    /// Highlights `repoID` without choosing it — the window saying "this is
    /// the project you are looking at".
    public func highlight(repoID: UUID) {
        guard let row = rows.firstIndex(where: { $0.id == repoID }) else { return }
        follow(row: row)
    }

    // MARK: - Rows

    private func reload() {
        let previous = highlightedRepoID ?? group.selectedRepoID
        let active = group.activeRepoIDs.compactMap { coordinator.repo(id: $0) }
        rows = active.filter { ProjectFilter.matches($0, query: query) }
        hoveredRow = -1
        table.reloadData()

        emptyLabel.isHidden = !rows.isEmpty
        emptyLabel.stringValue = active.isEmpty
            ? "No active projects — choose one in the Project Browser."
            : "No active projects match “\(query)”."

        if let previous, let row = rows.firstIndex(where: { $0.id == previous }) {
            follow(row: row)
        } else if !query.isEmpty, !rows.isEmpty {
            follow(row: 0)
        }
    }

    /// Moves the highlight without choosing anything.
    private func follow(row: Int) {
        isFollowingWindow = true
        defer { isFollowingWindow = false }
        select(row: row)
    }

    /// Moves the highlight, which chooses that project — see the type's note.
    private func select(row: Int) {
        guard rows.indices.contains(row) else { return }
        table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        table.scrollRowToVisible(row)
    }

    private func moveHighlight(by delta: Int) {
        guard !rows.isEmpty else { return }
        let current = table.selectedRow < 0 ? -1 : table.selectedRow
        select(row: min(max(current + delta, 0), rows.count - 1))
    }

    private func chooseHighlighted() {
        guard let id = highlightedRepoID else { return }
        onChoose?(id)
    }

    @objc private func rowClicked(_ sender: Any?) {
        let row = table.clickedRow
        guard rows.indices.contains(row) else { return }
        onChoose?(rows[row].id)
    }

    /// The user moved the highlight: show that project, unless it is the one
    /// already on screen.
    private func chooseAfterUserMove() {
        guard !isFollowingWindow, let id = highlightedRepoID, id != group.selectedRepoID else { return }
        onChoose?(id)
    }

    /// The pointer moved onto `row` (`-1`: off every row). Only the close box
    /// follows the pointer: moving the highlight shows that project, so a
    /// highlight that tracked the pointer would swap projects as it crossed
    /// the list (principle-of-least-astonishment).
    private func hover(row: Int) {
        guard row != hoveredRow else { return }
        let previous = hoveredRow
        hoveredRow = row
        refreshCloseBox(row: previous)
        refreshCloseBox(row: row)
    }

    private func refreshCloseBox(row: Int) {
        guard rows.indices.contains(row),
              let cell = table.view(atColumn: 0, row: row, makeIfNecessary: false) as? ActiveProjectRowView
        else { return }
        cell.showsCloseBox = row == hoveredRow || table.isRowSelected(row)
    }

    fileprivate func close(repoID: UUID) {
        onClose?(repoID)
    }
}

// MARK: - Table

extension ActiveProjectsViewController: NSTableViewDataSource, NSTableViewDelegate {

    public func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        ThemedTableRowView()
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let repo = rows[row]
        let cell = ActiveProjectRowView(repo: repo, query: query) { [weak self] in
            self?.close(repoID: repo.id)
        }
        cell.showsCloseBox = row == hoveredRow || tableView.isRowSelected(row)
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        for row in 0..<rows.count { refreshCloseBox(row: row) }
        chooseAfterUserMove()
    }
}

/// A table that reports which row the pointer is over, and Return.
@MainActor
private final class HoverTableView: NSTableView {

    var onHover: ((Int) -> Void)?
    var onReturn: (() -> Void)?

    private let role: ThemeRole
    private var observer: ThemePaletteObserver?
    private var tracking: NSTrackingArea?

    init(role: ThemeRole) {
        self.role = role
        super.init(frame: .zero)
        usesAlternatingRowBackgroundColors = false
        observer = ThemePaletteObserver(host: self) { [weak self] palette in
            guard let self else { return }
            self.backgroundColor = palette.nsColor(self.role)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        tracking = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        onHover?(row(at: convert(event.locationInWindow, from: nil)))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        onHover?(-1)
    }

    override func keyDown(with event: NSEvent) {
        // 36 is Return, 76 the keypad's Enter.
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            .subtracting([.numericPad, .function])
        if [36, 76].contains(event.keyCode), modifiers.isEmpty {
            onReturn?()
        } else {
            super.keyDown(with: event)
        }
    }
}

/// One active project: its name with an activity indicator after it, the
/// summary line beneath, and a close box at the trailing edge that shows
/// while the row is highlighted or under the pointer.
///
/// The activity indicator and the summary are placeholders the project's AI
/// summaries will drive; until then the indicator is idle and the summary
/// says there is none.
@MainActor
private final class ActiveProjectRowView: NSView {

    var showsCloseBox: Bool = false {
        didSet { closeButton.isHidden = !showsCloseBox }
    }

    private let closeButton: NSButton
    private let onClose: () -> Void

    init(repo: GitRepo, query: String, onClose: @escaping () -> Void) {
        self.onClose = onClose
        self.closeButton = NSButton(
            image: NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close Project")
                ?? NSImage(),
            target: nil,
            action: nil
        )
        super.init(frame: .zero)

        let palette = resolvedThemeScope.palette

        let name = ThemedHighlightLabel(
            string: repo.name,
            highlighting: ProjectFilter.ranges(of: query, in: repo.name),
            role: .primaryText,
            textRole: .body
        )
        name.lineBreakMode = .byTruncatingTail
        name.cell?.usesSingleLineMode = true
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let activity = NSImageView(image: NSImage(
            systemSymbolName: "circle.dotted",
            accessibilityDescription: "Activity"
        ) ?? NSImage())
        activity.contentTintColor = palette.nsColor(.tertiaryText)
        activity.toolTip = "No activity"
        activity.setContentHuggingPriority(.required, for: .horizontal)
        activity.setContentCompressionResistancePriority(.required, for: .horizontal)
        activity.accessibilityID("active-projects.row.activity")

        let titleRow = NSStackView(views: [name, activity])
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 5

        let summary = ThemedLabel(role: .tertiaryText, textRole: .caption)
        summary.stringValue = "No summary yet"
        summary.lineBreakMode = .byTruncatingTail
        summary.cell?.usesSingleLineMode = true
        summary.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        summary.accessibilityID("active-projects.row.summary")

        let text = NSStackView(views: [titleRow, summary])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 1
        text.translatesAutoresizingMaskIntoConstraints = false

        closeButton.isBordered = false
        closeButton.imageScaling = .scaleProportionallyDown
        closeButton.contentTintColor = palette.nsColor(.secondaryText)
        closeButton.toolTip = "Close Project"
        closeButton.target = self
        closeButton.action = #selector(closeClicked(_:))
        closeButton.isHidden = true
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.accessibilityID("active-projects.row.close")

        addSubview(text)
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            text.centerYAnchor.constraint(equalTo: centerYAnchor),
            text.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -6),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
            activity.widthAnchor.constraint(equalToConstant: 12),
            activity.heightAnchor.constraint(equalToConstant: 12)
        ])
        setAccessibilityLabel(repo.name)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func closeClicked(_ sender: Any?) {
        onClose()
    }
}
