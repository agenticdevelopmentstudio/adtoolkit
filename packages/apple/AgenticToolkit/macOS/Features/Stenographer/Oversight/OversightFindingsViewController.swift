import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// Lists the AI-oversight findings the daemon's observers recorded. The data and row
/// mapping live in `OversightFindingsListSource`; this class is the AppKit chrome (table
/// + Refresh + busy state) plus the per-row **Compact** action: for a pending `compact`
/// finding it asks the daemon whether the session is at a safe breakpoint, confirms with
/// the user, injects `/compact` into the session's terminal (the toolkit's
/// `TerminalTextInjector`), and
/// records the act — only when the injection succeeds.
@MainActor
final class OversightFindingsViewController: NSViewController {

    private let service: any StenographerDaemonService
    private let source: OversightFindingsListSource
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let countLabel = NSTextField(labelWithString: "")
    private let refreshButton = NSButton(title: "Refresh", target: nil, action: nil)
    private let spinner = NSProgressIndicator()
    /// The header's gear dialog: the oversight switches + provider/model
    /// selection. The controls only edit prefs — `StenographerOversightPrefsPush`
    /// owns pushing them to the daemon.
    private let configDialog: WindowOptionsDialog
    /// Retained because it owns the selection observer and reloads the daemon's
    /// configurations when its menu opens; the dialog builds its rows afresh on every open.
    private let oversightPicker: DaemonProviderPickerView
    /// Guards against overlapping reloads.
    private var isBusy = false

    private var themeObserver: ThemePaletteObserver?

    init(service: any StenographerDaemonService) {
        self.service = service
        self.source = OversightFindingsListSource(service: service)
        // Built once and held in a property: the picker owns the observers that
        // rebuild it live, so it must outlive dialog opens.
        let picker = AIOversightProviderControls.makePicker(service: service)
        self.oversightPicker = picker
        // Wider than the default: the provider picker's row is a popup, a model
        // name and a trailing Choose button, which a checkbox-width dialog crams.
        self.configDialog = WindowOptionsDialog(title: "AI Oversight", width: 380) {
            [
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: AIOversightProviderControls.enableToggleTitle,
                        setting: UserSettings.stenographerAIOversightEnabled
                    )
                ),
                ComposableSettings.CheckboxView(
                    with: ComposableSettings.ViewModel<Bool>(
                        title: AIOversightProviderControls.llmToggleTitle,
                        setting: UserSettings.stenographerAIOversightLLMEnabled
                    )
                ),
                picker,
                ComposableSettings.ExplanationView(
                    withText: "The daemon watches live sessions and records findings here. "
                        + "AI judgment asks the selected provider whether now is a good "
                        + "moment to act; off, the deterministic rules run alone."
                )
            ]
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private enum Column: String, CaseIterable {
        case session, observer, kind, severity, status, action, reason

        var title: String {
            switch self {
            case .session: return "Session"
            case .observer: return "Observer"
            case .kind: return "Kind"
            case .severity: return "Severity"
            case .status: return "Status"
            case .action: return "Action"
            case .reason: return "Reason"
            }
        }

        var width: CGFloat {
            switch self {
            case .session: return 80
            case .observer: return 90
            case .kind: return 90
            case .severity: return 70
            case .status: return 90
            case .action: return 96
            case .reason: return 320
            }
        }
    }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 860, height: 460))
        root.wantsLayer = true

        countLabel.translatesAutoresizingMaskIntoConstraints = false

        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        configureButton(refreshButton, action: #selector(refreshTapped))
        configureTable()

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // The gear (oversight config) is hoisted into the window title bar via
        // `makeTitlebarAccessory()` — matching Usage Details — so only the
        // findings-specific count/spinner/refresh remain in this content header.
        [countLabel, spinner, refreshButton, scrollView].forEach(root.addSubview)

        NSLayoutConstraint.activate([
            refreshButton.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            refreshButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            countLabel.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            countLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            spinner.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            spinner.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 8),

            scrollView.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        view = root
    }

    /// The window title-bar accessory holding this window's config gear (the
    /// oversight switches + provider/model). Placed in the title bar so the gear
    /// is in the same spot as every other window (Usage Details pattern); it applies
    /// window-wide, so it stays put across the Findings/Scripts tabs.
    func makeTitlebarAccessory() -> NSTitlebarAccessoryViewController {
        loadViewIfNeeded()
        return configDialog.makeTitlebarAccessory()
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

    private func applyTheme(_ palette: SemanticPalette) {
        view.layer?.backgroundColor = palette.windowBackgroundColor.cgColor

        scrollView.backgroundColor = palette.windowBackgroundColor
        scrollView.drawsBackground = true
        tableView.backgroundColor = palette.windowBackgroundColor

        countLabel.textColor = palette.secondaryTextColor
        countLabel.font = palette.font(.caption)

        // Cells are self-themed `ThemedLabel`s, so they recolor in place on a theme
        // change — no full `reloadData()` here (that runs only on data change).
    }

    private func configureButton(_ button: NSButton, action: Selector) {
        button.bezelStyle = .rounded
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureTable() {
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.allowsColumnResizing = true
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

    private func reload() {
        guard !isBusy else { return }
        setBusy(true)
        Task { @MainActor in
            await source.reload()
            reloadTable()
            setBusy(false)
        }
    }

    private func reloadTable() {
        tableView.reloadData()
        let count = source.rows.count
        countLabel.stringValue = count == 0 ? "No findings" : "\(count) finding(s)"
    }

    private func setBusy(_ busy: Bool) {
        isBusy = busy
        if busy { spinner.startAnimation(nil) } else { spinner.stopAnimation(nil) }
        refreshButton.isEnabled = !busy
    }

    // MARK: - Compact action

    @objc private func compactTapped(_ sender: NSButton) {
        // Resolve the row now (not at render time) so it's correct after reloads/sorting.
        let row = tableView.row(for: sender)
        guard row >= 0, row < source.rows.count else { return }
        performCompact(finding: source.rows[row])
    }

    /// Gate → confirm → inject `/compact` → record. Each step surfaces a clear reason on
    /// failure and stops; the finding is marked `acted` only after a *successful* injection,
    /// so a permission/pane error leaves it `pending` to retry.
    private func performCompact(finding: OversightFindingDTO) {
        guard !isBusy else { return }
        setBusy(true)
        Task { @MainActor in
            defer { setBusy(false) }

            // 1. The daemon decides whether the session is at a safe breakpoint and, if so,
            //    hands back the terminal pane to inject into.
            guard let target = await service.oversightActionTarget(findingId: finding.id) else {
                presentInfo(title: "Couldn't reach the daemon",
                            text: "The oversight daemon didn't respond. Try again in a moment.")
                return
            }
            guard target.actionable else {
                presentInfo(title: "Not ready to compact", text: target.reason)
                return
            }
            guard TerminalTextInjector.isSupported(termProgram: target.termProgram) else {
                let term = target.termProgram.isEmpty ? "an unknown terminal" : target.termProgram
                presentInfo(title: "Unsupported terminal",
                            text: "Injecting \(target.injectText) needs iTerm2 or Terminal.app; "
                                + "this session runs in \(term).")
                return
            }

            // 2. Confirm — typing into a live session is irreversible.
            guard await confirmCompact(finding: finding, target: target) else { return }

            // 3. Inject into the pane — quietly, on the default `raising: false`.
            // Compacting is housekeeping ordered from this list, and the reader
            // is working down the rest of it; a terminal thrown in front of that
            // list takes it away to show them a session they did not ask to go
            // to. Going there is the row's own click action.
            let result = TerminalTextInjector.inject(
                target.injectText, termProgram: target.termProgram,
                termSessionId: target.termSessionId, pid: target.pid
            )
            if case .failure(let error) = result {
                presentInfo(title: "Compact failed", text: error.localizedDescription)
                return
            }

            // 4. Record it — only now that the injection landed.
            _ = await service.actOnOversightFinding(findingId: finding.id)
            await source.reload()
            reloadTable()
        }
    }

    private func confirmCompact(finding: OversightFindingDTO, target: OversightActionTargetDTO) async -> Bool {
        let sessionLabel = finding.sessionId.isEmpty ? "this session" : "session \(finding.sessionId.prefix(8))"
        let verb = finding.observer == "compact" ? "Compact" : "Act on"
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\(verb) \(sessionLabel) now?"
        alert.informativeText = "This types \(target.injectText) into its \(target.termProgram) terminal. "
            + "It runs immediately in the live session."
        alert.addButton(withTitle: finding.observer == "compact" ? "Compact" : "Send")
        alert.addButton(withTitle: "Cancel")
        guard let window = view.window else {
            return alert.runModal() == .alertFirstButtonReturn
        }
        return await withCheckedContinuation { continuation in
            alert.beginSheetModal(for: window) { response in
                continuation.resume(returning: response == .alertFirstButtonReturn)
            }
        }
    }

    private func presentInfo(title: String, text: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}

extension OversightFindingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { source.rows.count }
}

extension OversightFindingsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, row < source.rows.count,
              let column = Column(rawValue: tableColumn.identifier.rawValue) else { return nil }
        if column == .action {
            return actionCell(for: source.rows[row], identifier: tableColumn.identifier)
        }
        let cells = OversightFindingsListSource.cells(for: source.rows[row])
        let text: String
        switch column {
        case .session: text = cells.session
        case .observer: text = cells.observer
        case .kind: text = cells.kind
        case .severity: text = cells.severity
        case .status: text = cells.status
        case .reason: text = cells.reason
        case .action: text = ""  // handled above
        }
        let field = tableView.makeView(
            withIdentifier: tableColumn.identifier, owner: self
        ) as? NSTextField ?? makeCell(identifier: tableColumn.identifier)
        // Color + font are owned by the self-themed cell; set only the data here.
        field.stringValue = text
        return field
    }

    /// An action button for a pending finding — "Compact" for the built-in compact
    /// script (keyed on its stable `observer` id, not the free-form, user-editable
    /// `kind`), "Act" for any other script's finding; nothing once resolved. Whether
    /// the action can
    /// actually run now stays the daemon's call (`target()`), so a record-only script's
    /// button surfaces the daemon's "no action" reason rather than silently hiding.
    /// The button's row is resolved at click time via `tableView.row(for:)`, so it
    /// survives reloads.
    private func actionCell(for finding: OversightFindingDTO, identifier: NSUserInterfaceItemIdentifier) -> NSView? {
        guard finding.status == "pending" else { return nil }
        let button = tableView.makeView(withIdentifier: identifier, owner: self) as? NSButton
            ?? {
                let new = NSButton(title: "", target: self, action: #selector(compactTapped(_:)))
                new.bezelStyle = .rounded
                new.controlSize = .small
                new.identifier = identifier
                return new
            }()
        button.title = finding.observer == "compact" ? "Compact" : "Act"
        button.isEnabled = !isBusy
        return button
    }

    private func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTextField {
        // ThemedLabel observes the palette and recolors itself, so reused cells stay
        // correct across theme changes without a table reload.
        let field = ThemedLabel(role: .primaryText, textRole: .caption)
        field.identifier = identifier
        field.lineBreakMode = .byTruncatingTail
        return field
    }
}
