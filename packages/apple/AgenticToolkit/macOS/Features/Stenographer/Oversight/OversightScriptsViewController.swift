import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// The Scripts tab of the AI Oversight window: the stored trigger→response scripts,
/// with enable toggles in-table and New / Edit / Delete / Reset actions. All writes
/// go through the daemon — the table always re-reads what was actually stored.
@MainActor
final class OversightScriptsViewController: NSViewController {

    private(set) var rows: [OversightScript] = []
    private let service: any StenographerDaemonService

    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let newButton = NSButton(title: "New", target: nil, action: nil)
    private let editButton = NSButton(title: "Edit", target: nil, action: nil)
    private let deleteButton = NSButton(title: "Delete", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset", target: nil, action: nil)
    private var isBusy = false

    private var themeObserver: ThemePaletteObserver?

    init(service: any StenographerDaemonService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private enum Column: String, CaseIterable {
        case enabled, name, trigger, action

        var title: String {
            switch self {
            case .enabled: return ""
            case .name: return "Name"
            case .trigger: return "Trigger"
            case .action: return "Action"
            }
        }

        var width: CGFloat {
            switch self {
            case .enabled: return 24
            case .name: return 140
            case .trigger: return 340
            case .action: return 160
            }
        }
    }

    // MARK: - Pure summaries (unit-tested)

    /// One-line rendering of a predicate tree: `field op value`, groups joined with
    /// AND/OR, nested groups parenthesized.
    nonisolated static func triggerSummary(_ predicate: ScriptPredicate) -> String {
        switch predicate {
        case .condition(let field, let operation, let value):
            return "\(field.rawValue) \(symbol(operation)) \(value)"
        case .all(let subs):
            return subs.map { parenthesized($0) }.joined(separator: " AND ")
        case .any(let subs):
            return subs.map { parenthesized($0) }.joined(separator: " OR ")
        }
    }

    private nonisolated static func parenthesized(_ predicate: ScriptPredicate) -> String {
        switch predicate {
        case .condition:
            return triggerSummary(predicate)
        case .all, .any:
            return "(\(triggerSummary(predicate)))"
        }
    }

    private nonisolated static func symbol(_ operation: ConditionOperator) -> String {
        switch operation {
        case .equals: return "="
        case .notEquals: return "≠"
        case .greaterThan: return ">"
        case .greaterOrEqual: return "≥"
        case .lessThan: return "<"
        case .lessOrEqual: return "≤"
        case .contains: return "contains"
        }
    }

    nonisolated static func actionSummary(_ script: OversightScript) -> String {
        switch script.response.action {
        case .injectText(let text): return "\(script.response.kind): type \(text)"
        case .none: return "\(script.response.kind): record only"
        }
    }

    // MARK: - Lifecycle

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 860, height: 420))
        root.wantsLayer = true

        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        for (button, action): (NSButton, Selector) in [
            (newButton, #selector(newTapped)), (editButton, #selector(editTapped)),
            (deleteButton, #selector(deleteTapped)), (resetButton, #selector(resetTapped))
        ] {
            button.bezelStyle = .rounded
            button.target = self
            button.action = action
            button.translatesAutoresizingMaskIntoConstraints = false
        }

        tableView.usesAlternatingRowBackgroundColors = false
        tableView.allowsColumnResizing = true
        tableView.dataSource = self
        tableView.delegate = self
        for col in Column.allCases {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(col.rawValue))
            column.title = col.title
            column.width = col.width
            column.minWidth = 24
            tableView.addTableColumn(column)
        }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        [statusLabel, newButton, editButton, deleteButton, resetButton, scrollView].forEach(root.addSubview)

        NSLayoutConstraint.activate([
            newButton.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            newButton.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            editButton.centerYAnchor.constraint(equalTo: newButton.centerYAnchor),
            editButton.leadingAnchor.constraint(equalTo: newButton.trailingAnchor, constant: 8),
            deleteButton.centerYAnchor.constraint(equalTo: newButton.centerYAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 8),
            resetButton.centerYAnchor.constraint(equalTo: newButton.centerYAnchor),
            resetButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: newButton.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: newButton.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        themeObserver = ThemePaletteObserver { [weak self] palette in
            self?.applyTheme(palette)
        }
        updateButtonState()
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
        statusLabel.textColor = palette.secondaryTextColor
        statusLabel.font = palette.font(.caption)
    }

    // MARK: - Data

    private func reload() {
        guard !isBusy else { return }
        isBusy = true
        Task { @MainActor in
            defer { isBusy = false }
            guard let scripts = await service.oversightScripts() else {
                statusLabel.stringValue = "Daemon unreachable"
                return
            }
            rows = scripts
            statusLabel.stringValue = "\(scripts.count) script(s)"
            tableView.reloadData()
            updateButtonState()
        }
    }

    private var selectedScript: OversightScript? {
        let row = tableView.selectedRow
        guard row >= 0, row < rows.count else { return nil }
        return rows[row]
    }

    private func updateButtonState() {
        let selected = selectedScript
        editButton.isEnabled = selected != nil
        deleteButton.isEnabled = selected.map { !$0.builtIn } ?? false
        resetButton.isEnabled = selected?.builtIn ?? false
    }

    // MARK: - Actions

    @objc private func newTapped() {
        let template = OversightScript(
            id: UUID().uuidString,
            name: "New Script",
            enabled: false,
            builtIn: false,
            version: 1,
            trigger: ScriptTrigger(
                predicate: .all([.condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "80")])
            ),
            response: ScriptResponse(kind: "attention", reasonTemplate: "Needs attention", action: .none)
        )
        presentEditor(for: template)
    }

    @objc private func editTapped() {
        guard let script = selectedScript else { return }
        presentEditor(for: script)
    }

    @objc private func deleteTapped() {
        guard let script = selectedScript, !script.builtIn else { return }
        let alert = NSAlert()
        alert.messageText = "Delete “\(script.name)”?"
        alert.informativeText = "Its pending findings go stale on the next oversight tick."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        guard let window = view.window else { return }
        let service = self.service
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            Task { @MainActor in
                _ = await service.deleteOversightScript(id: script.id)
                self?.reload()
            }
        }
    }

    @objc private func resetTapped() {
        guard let script = selectedScript, script.builtIn else { return }
        Task { @MainActor in
            _ = await service.resetOversightScript(id: script.id)
            reload()
        }
    }

    @objc private func enabledToggled(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        guard row >= 0, row < rows.count else { return }
        var script = rows[row]
        script.enabled = sender.state == .on
        Task { @MainActor in
            _ = await service.saveOversightScript(script)
            reload()
        }
    }

    private func presentEditor(for script: OversightScript) {
        let editor = ScriptEditorViewController(script: script) { [weak self] edited in
            guard let self else { return false }
            let saved = await service.saveOversightScript(edited)
            self.reload()
            return saved != nil
        }
        presentAsSheet(editor)
    }
}

extension OversightScriptsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
}

extension OversightScriptsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, row < rows.count,
              let column = Column(rawValue: tableColumn.identifier.rawValue) else { return nil }
        let script = rows[row]
        if column == .enabled {
            let checkbox = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSButton
                ?? {
                    let new = NSButton(checkboxWithTitle: "", target: self, action: #selector(enabledToggled(_:)))
                    new.identifier = tableColumn.identifier
                    return new
                }()
            checkbox.state = script.enabled ? .on : .off
            return checkbox
        }
        let text: String
        switch column {
        case .name: text = script.name + (script.builtIn ? "  (built-in)" : "")
        case .trigger: text = Self.triggerSummary(script.trigger.predicate)
        case .action: text = Self.actionSummary(script)
        case .enabled: text = ""   // handled above
        }
        let field = tableView.makeView(
            withIdentifier: tableColumn.identifier, owner: self
        ) as? NSTextField ?? {
            let new = ThemedLabel(role: .primaryText, textRole: .caption)
            new.identifier = tableColumn.identifier
            new.lineBreakMode = .byTruncatingTail
            return new
        }()
        field.stringValue = text
        return field
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonState()
    }
}
