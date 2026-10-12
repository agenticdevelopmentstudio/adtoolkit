import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// The AI Log window's content: every LLM call the daemon made (summaries, oversight),
/// newest first. Data and row mapping live in `AILogListSource`; this class is the
/// AppKit chrome — a header (feature filter / count / Refresh) over a vertical split:
/// the table on top, a full-text detail panel (system prompt / user prompt /
/// response-or-error) below.
///
/// The table shows the resolved session **name** (not a raw GUID) and a "Result"
/// column with what each turn actually did; the last column grows with the window and
/// rows use the toolkit's themed selection, matching the Ingestion Errors window.
@MainActor
final class AILogViewController: NSViewController {

    private let service: any StenographerDaemonService
    private let source: AILogListSource
    private let splitView = NSSplitView()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let countLabel = NSTextField(labelWithString: "")
    private let refreshButton = NSButton(title: "Refresh", target: nil, action: nil)
    private let spinner = NSProgressIndicator()
    private let detailPane = AILogDetailPane()
    /// Feature filter: `nil` = all, otherwise the raw `feature` discriminator.
    private let featurePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    /// Guards against overlapping reloads.
    private var isBusy = false

    private var themeObserver: ThemePaletteObserver?

    /// Resolved `sessionId → name` (summary, else git branch); rebuilt each reload
    /// from the sessions list so the Session column reads as a human label.
    private var sessionNameById: [String: String] = [:]
    /// The currently selected feature filter (`nil` = all features).
    private var selectedFeature: String?
    /// `source.rows` narrowed by `selectedFeature`; what the table actually shows.
    private var filteredRows: [AIInteractionDTO] = []
    /// The last column is fitted to fill once, on first layout; afterwards
    /// `.lastColumnOnlyAutoresizingStyle` keeps it filling without re-fitting every
    /// layout pass (which would clobber the user's manual column resizes).
    private var didInitialColumnFit = false

    private enum Column: String, CaseIterable {
        case time, feature, session, provider, duration, result

        var title: String {
            switch self {
            case .time: return "Time"
            case .feature: return "Feature"
            case .session: return "Session"
            case .provider: return "Provider / Model"
            case .duration: return "Duration"
            case .result: return "Result"
            }
        }

        var width: CGFloat {
            switch self {
            case .time: return 155
            case .feature: return 90
            case .session: return 200
            case .provider: return 190
            case .duration: return 70
            case .result: return 260
            }
        }
    }

    init(service: any StenographerDaemonService) {
        self.service = service
        self.source = AILogListSource(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 940, height: 560))
        root.wantsLayer = true

        countLabel.translatesAutoresizingMaskIntoConstraints = false

        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        refreshButton.bezelStyle = .rounded
        refreshButton.target = self
        refreshButton.action = #selector(refreshTapped)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false

        configureFeaturePopup()
        configureTable()

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true

        splitView.isVertical = false
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(scrollView)
        splitView.addArrangedSubview(detailPane)

        [featurePopup, countLabel, spinner, refreshButton, splitView].forEach(root.addSubview)

        NSLayoutConstraint.activate([
            refreshButton.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            refreshButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),

            featurePopup.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            featurePopup.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),

            countLabel.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: featurePopup.trailingAnchor, constant: 10),
            spinner.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            spinner.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 8),

            splitView.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 10),
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            // The table keeps a usable minimum; the detail pane absorbs the rest.
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),
            detailPane.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        themeObserver = ThemePaletteObserver { [weak self] palette in
            self?.applyTheme(palette)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        reload()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        // Fit the last ("Result") column to fill exactly once, when the table first
        // has a real width. Ongoing resizes are handled by
        // `.lastColumnOnlyAutoresizingStyle`; re-fitting every layout would undo a
        // user's manual column resize on the next tick.
        guard !didInitialColumnFit, tableView.bounds.width > 0 else { return }
        didInitialColumnFit = true
        tableView.sizeLastColumnToFit()
    }

    private func applyTheme(_ palette: SemanticPalette) {
        view.layer?.backgroundColor = palette.windowBackgroundColor.cgColor

        scrollView.backgroundColor = palette.windowBackgroundColor
        scrollView.drawsBackground = true
        tableView.backgroundColor = palette.windowBackgroundColor

        countLabel.textColor = palette.secondaryTextColor
        countLabel.font = palette.font(.caption)

        detailPane.applyTheme(palette)
        // Cells and rows are self-themed (`ThemedLabel` / `ThemedTableRowView`) —
        // no reload on theme change.
    }

    private func configureFeaturePopup() {
        featurePopup.translatesAutoresizingMaskIntoConstraints = false
        featurePopup.target = self
        featurePopup.action = #selector(featureChanged(_:))
        featurePopup.addItem(withTitle: "All features")
        featurePopup.item(at: 0)?.representedObject = nil
        // Friendly label → the raw `feature` discriminator stored on each row.
        for (title, value) in [("Summaries", "summarize"), ("Oversight", "oversight")] {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.representedObject = value
            featurePopup.menu?.addItem(item)
        }
    }

    private func configureTable() {
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.allowsColumnResizing = true
        // The last column (Result) absorbs extra width when the window widens.
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.dataSource = self
        tableView.delegate = self
        for col in Column.allCases {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(col.rawValue))
            column.title = col.title
            column.width = col.width
            column.minWidth = 50
            tableView.addTableColumn(column)
        }
    }

    // MARK: - Actions

    @objc private func refreshTapped() {
        reload()
    }

    @objc private func featureChanged(_ sender: NSPopUpButton) {
        selectedFeature = sender.selectedItem?.representedObject as? String
        applyFilter()
    }

    private func reload() {
        guard !isBusy else { return }
        setBusy(true)
        Task { @MainActor in
            // The interaction list and the session-name lookup are independent
            // round-trips, so fetch them concurrently. Names are re-resolved each
            // reload on purpose — a session's summary can land after the first load.
            async let sessionsFetch = service.sessions(status: nil, project: nil, sinceHours: 0, includeCounts: false)
            // Newest first (the daemon's order); list rows carry truncated text.
            await source.reload()
            // Resolve session names for the Session column (summary → git branch).
            let fetched = await sessionsFetch ?? []
            sessionNameById = Dictionary(
                fetched.map { ($0.sessionId, Self.sessionName($0)) },
                uniquingKeysWith: { first, _ in first }
            )
            applyFilter()
            setBusy(false)
        }
    }

    /// Narrows `source.rows` by the selected feature and refreshes the table.
    private func applyFilter() {
        if let feature = selectedFeature {
            filteredRows = source.rows.filter { $0.feature == feature }
        } else {
            filteredRows = source.rows
        }
        reloadTable()
    }

    private func reloadTable() {
        tableView.reloadData()
        let count = filteredRows.count
        countLabel.stringValue = count == 0 ? "No AI interactions" : "\(count) interaction(s)"
        // `reloadData` keeps the selected *index*, but after a filter change or a
        // refresh that index can map to a different interaction — so re-render the
        // detail for whatever is selected now (showDetail clears if it's out of
        // bounds) instead of leaving a stale panel under a different highlighted row.
        showDetail(for: tableView.selectedRow)
    }

    private func setBusy(_ busy: Bool) {
        isBusy = busy
        if busy { spinner.startAnimation(nil) } else { spinner.stopAnimation(nil) }
        refreshButton.isEnabled = !busy
    }

    /// Loads the selected row's full text into the detail pane. List rows are
    /// truncated, so this re-fetches by id; a stale reply (selection moved on) is
    /// dropped rather than rendered.
    private func showDetail(for row: Int) {
        guard row >= 0, row < filteredRows.count else {
            detailPane.clear()
            return
        }
        let dto = filteredRows[row]
        let name = sessionNameById[dto.sessionId] ?? ""
        let id = dto.id
        Task { @MainActor in
            guard let full = await source.detail(id: id) else { return }
            guard tableView.selectedRow >= 0,
                  tableView.selectedRow < filteredRows.count,
                  filteredRows[tableView.selectedRow].id == id else { return }
            detailPane.render(full, sessionName: name)
        }
    }

    /// Human-friendly session label — prefers the model-generated summary, falls back
    /// to git branch (mirrors the Log window). Empty means "no name available".
    private static func sessionName(_ session: SessionDTO) -> String {
        if !session.summary.isEmpty { return session.summary }
        if !session.gitBranch.isEmpty { return session.gitBranch }
        return ""
    }
}

extension AILogViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { filteredRows.count }
}

extension AILogViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, row < filteredRows.count,
              let column = Column(rawValue: tableColumn.identifier.rawValue) else { return nil }
        let dto = filteredRows[row]
        let name = sessionNameById[dto.sessionId] ?? ""
        let cells = AILogListSource.cells(for: dto, sessionName: name)
        let text: String
        switch column {
        case .time: text = cells.time
        case .feature: text = cells.feature
        case .session: text = cells.session
        case .provider: text = cells.provider
        case .duration: text = cells.duration
        case .result: text = cells.result
        }
        let field = tableView.makeView(
            withIdentifier: tableColumn.identifier, owner: self
        ) as? NSTextField ?? makeCell(identifier: tableColumn.identifier)
        field.stringValue = text
        return field
    }

    /// A themed row so selection uses the palette's `.selection` role (rounded fill),
    /// matching the rest of the app instead of the default system highlight.
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let identifier = NSUserInterfaceItemIdentifier("ai-log-row")
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? ThemedTableRowView {
            return reused
        }
        let rowView = ThemedTableRowView(frame: .zero)
        rowView.identifier = identifier
        return rowView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showDetail(for: tableView.selectedRow)
    }

    private func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTextField {
        let field = ThemedLabel(role: .primaryText, textRole: .caption)
        field.identifier = identifier
        field.lineBreakMode = .byTruncatingTail
        return field
    }
}

/// The read-only full-text pane under the table — an elevated surface (like the
/// Ingestion Errors window) holding a scrolling stack of selectable sections: a
/// summary line, then System prompt / User prompt / Response (or Error).
@MainActor
private final class AILogDetailPane: NSView {

    private let scrollView = NSScrollView()
    private let contentStack = NSStackView()
    private let placeholder = ThemedLabel(
        string: "Select an interaction to see its full prompts and response.",
        role: .secondaryText, textRole: .body
    )

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 6
        contentStack.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let flipped = TopAnchoredFlippedView()
        flipped.translatesAutoresizingMaskIntoConstraints = false
        flipped.addSubview(contentStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = flipped

        contentStack.addArrangedSubview(placeholder)

        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: flipped.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: flipped.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: flipped.trailingAnchor),
            flipped.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func applyTheme(_ palette: SemanticPalette) {
        // A distinct elevated panel under the table — the surface role reads as a
        // separate card, matching the Ingestion window's clean chrome.
        layer?.backgroundColor = palette.surfaceColor.cgColor
        scrollView.backgroundColor = palette.surfaceColor
        scrollView.drawsBackground = true
        // Labels are self-themed (ThemedLabel) and recolor in place.
    }

    func clear() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStack.addArrangedSubview(placeholder)
    }

    func render(_ dto: AIInteractionDTO, sessionName: String) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let cells = AILogListSource.cells(for: dto, sessionName: sessionName)
        // `cells.session` already resolves name → short id → "—"
        // (AILogListSource.sessionLabel); reuse it and drop the fragment only when
        // there's no session at all.
        let sessionPart = cells.session == "—" ? "" : "  ·  \(cells.session)"
        let summary = "\(cells.feature)  ·  \(cells.provider)  ·  \(cells.duration)"
            + "  ·  \(dto.outcome)\(sessionPart)"
        let header = ThemedLabel(string: summary, role: .primaryText, textRole: .heading)
        header.isSelectable = true
        contentStack.addArrangedSubview(header)

        appendSection(title: "System prompt", text: dto.systemPrompt)
        appendSection(title: "User prompt", text: dto.userPrompt)
        if dto.isFailure {
            appendSection(title: dto.outcome == "error" ? "Error" : "Reason", text: dto.error)
        } else {
            appendSection(title: "Response", text: dto.response)
        }
    }

    private func appendSection(title: String, text: String) {
        contentStack.addArrangedSubview(divider())
        let header = ThemedLabel(string: title, role: .secondaryText, textRole: .caption)
        contentStack.addArrangedSubview(header)

        let body = ThemedLabel(string: text.isEmpty ? "—" : text, role: .primaryText, textRole: .code)
        body.isSelectable = true
        body.lineBreakMode = .byWordWrapping
        body.maximumNumberOfLines = 0
        body.preferredMaxLayoutWidth = 800
        contentStack.addArrangedSubview(body)
    }

    private func divider() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        box.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return box
    }
}
