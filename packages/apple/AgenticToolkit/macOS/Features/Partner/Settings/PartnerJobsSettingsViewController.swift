import AppKit
import Combine

import AgenticToolkitCore
import os

/// Jobs tab: the jobs on the left, and the selected job's settings, guidelines and steps on the right.
@MainActor
public final class PartnerJobsSettingsViewController: ComposableSettings.SettingsPanelViewController,
    NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate {

    private static let logger = Logger(subsystem: "com.agenticdevelopertoolkit", category: "PartnerJobsSettings")
    private static let stepColumns = ["name", "environment", "command", "condition"]

    private let controller: PartnerController
    private let model: PartnerJobsEditorModel

    private let jobsTable = NSTableView()
    private let stepsTable = NSTableView()
    private let enabledBox = NSButton(checkboxWithTitle: "Enabled", target: nil, action: nil)
    private let scheduleField = NSTextField()
    private let guidelinesView = NSTextView()
    private let addButton = NSButton(title: "Add step", target: nil, action: nil)
    private let removeButton = NSButton(title: "Remove", target: nil, action: nil)
    private let upButton = NSButton(title: "Up", target: nil, action: nil)
    private let downButton = NSButton(title: "Down", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset to default", target: nil, action: nil)
    private let applyButton = NSButton(title: "Apply (restart partner)", target: nil, action: nil)
    private let errorLine = NSTextField(labelWithString: "")
    private var detail: NSStackView!
    private var jobsChanges: AnyCancellable?
    /// Whether the guidelines view holds typing not yet saved. Programmatic `string` writes do not set it.
    private var guidelinesEdited = false

    public init(controller: PartnerController, model: PartnerJobsEditorModel) {
        self.controller = controller
        self.model = model
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Jobs", icon: NSImage(systemSymbolName: "list.bullet.rectangle", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var hostsOwnScroll: Bool { true }

    public override var searchKeywords: [String] {
        ["jobs", "guidelines", "steps", "schedule", "code reviews", "general", "apply", "restart"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Jobs",
                  body: "A job is a standing piece of work: guidelines the partner follows and the steps it "
                      + "takes. A schedule in minutes makes it run on a timer; empty means only on request."),
            .init(title: "Guidelines and steps",
                  body: "Guidelines are saved to the job's file under the partner folder. A step is typed "
                      + "into a terminal or into Claude Code when its condition holds. Reset to default "
                      + "restores a built-in job, deleting your edited guidelines file."),
            .init(title: "Apply",
                  body: "The partner reads guidelines when it starts. Apply restarts it so edits take effect.")
        ])
    }

    public override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 520).isActive = true

        configureJobsTable()
        configureStepsTable()
        let jobsScroll = Self.scroll(jobsTable)
        jobsScroll.widthAnchor.constraint(equalToConstant: 170).isActive = true

        scheduleField.placeholderString = "minutes (empty = on request)"
        scheduleField.target = self
        scheduleField.action = #selector(scheduleChanged)
        enabledBox.target = self
        enabledBox.action = #selector(enabledChanged)
        _ = enabledBox.accessibilityID("settings.partner.job.enabled")
        _ = scheduleField.accessibilityID("settings.partner.job.schedule")
        _ = resetButton.accessibilityID("settings.partner.job.reset")
        _ = applyButton.accessibilityID("settings.partner.job.apply")

        guidelinesView.isRichText = false
        guidelinesView.isAutomaticQuoteSubstitutionEnabled = false
        guidelinesView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        guidelinesView.isVerticallyResizable = true
        guidelinesView.autoresizingMask = [.width]
        guidelinesView.delegate = self
        _ = guidelinesView.accessibilityID("settings.partner.job.guidelines")
        let guidelinesScroll = NSScrollView()
        guidelinesScroll.documentView = guidelinesView
        guidelinesScroll.hasVerticalScroller = true
        guidelinesScroll.borderType = .bezelBorder
        guidelinesScroll.heightAnchor.constraint(equalToConstant: 150).isActive = true

        let stepsScroll = Self.scroll(stepsTable)
        stepsScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true

        for (button, action) in [(addButton, #selector(addStep)), (removeButton, #selector(removeStep)),
                                 (upButton, #selector(moveStepUp)), (downButton, #selector(moveStepDown)),
                                 (resetButton, #selector(resetJob)), (applyButton, #selector(apply))] {
            button.target = self
            button.action = action
        }
        errorLine.textColor = .systemRed
        errorLine.lineBreakMode = .byTruncatingTail

        let stepButtons = NSStackView(views: [addButton, removeButton, upButton, downButton])
        let bottom = NSStackView(views: [resetButton, applyButton])
        detail = NSStackView(views: [
            enabledBox, Self.labelled("Schedule", scheduleField), NSTextField(labelWithString: "Guidelines"),
            guidelinesScroll, NSTextField(labelWithString: "Steps"), stepsScroll, stepButtons, bottom, errorLine
        ])
        detail.orientation = .vertical
        detail.alignment = .leading
        detail.spacing = 8
        for row in [guidelinesScroll, stepsScroll] {
            row.widthAnchor.constraint(equalTo: detail.widthAnchor).isActive = true
        }

        let root = NSStackView(views: [jobsScroll, detail])
        root.orientation = .horizontal
        root.alignment = .top
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            jobsScroll.heightAnchor.constraint(equalTo: root.heightAnchor),
            detail.widthAnchor.constraint(greaterThanOrEqualToConstant: 360)
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
        // A job written elsewhere (the coordinator following the crawl interval) shows here at once. Only the
        // stored fields are redrawn: guidelines being typed are not in the store yet and must not be replaced.
        jobsChanges = controller.store.changes
            .receive(on: DispatchQueue.main)
            .filter { $0 == .jobs }
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.showStoredFields() } }
    }

    /// Re-reads the jobs and redraws the enabled box and the schedule, leaving the guidelines alone.
    func showStoredFields() {
        model.reload()
        let job = current
        enabledBox.state = job?.isEnabled == true ? .on : .off
        scheduleField.stringValue = job?.scheduleSeconds.map { String($0 / 60) } ?? ""
    }

    // MARK: - Setup

    private func configureJobsTable() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("job"))
        column.title = "Jobs"
        jobsTable.addTableColumn(column)
        jobsTable.dataSource = self
        jobsTable.delegate = self
        _ = jobsTable.accessibilityID("settings.partner.jobs")
    }

    private func configureStepsTable() {
        for (id, title) in zip(Self.stepColumns, ["Name", "Environment", "Command", "Condition"]) {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = id == "environment" ? 90 : 130
            column.isEditable = true
            stepsTable.addTableColumn(column)
        }
        stepsTable.dataSource = self
        stepsTable.delegate = self
        stepsTable.allowsMultipleSelection = false
        _ = stepsTable.accessibilityID("settings.partner.job.steps")
    }

    private static func scroll(_ table: NSTableView) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        return scroll
    }

    private static func labelled(_ title: String, _ field: NSView) -> NSStackView {
        let row = NSStackView(views: [NSTextField(labelWithString: title), field])
        row.spacing = 8
        return row
    }

    // MARK: - State

    private var current: PartnerJob? { model.jobs.first { $0.id == model.selectedID } }

    /// Redraws everything from the model.
    private func refresh() {
        jobsTable.reloadData()
        if let id = model.selectedID, let row = model.jobs.firstIndex(where: { $0.id == id }) {
            jobsTable.selectRowIndexes([row], byExtendingSelection: false)
        }
        refreshDetail()
    }

    private func refreshDetail() {
        let job = current
        detail.isHidden = job == nil
        enabledBox.state = job?.isEnabled == true ? .on : .off
        scheduleField.stringValue = job?.scheduleSeconds.map { String($0 / 60) } ?? ""
        // Text the owner is typing is kept until it is flushed; anything else shows the stored guidelines.
        if !guidelinesEdited, guidelinesView.string != job?.guidelines ?? "" {
            guidelinesView.string = job?.guidelines ?? ""
        }
        resetButton.isHidden = job?.isBuiltIn != true
        stepsTable.reloadData()
        updateStepButtons()
    }

    private func updateStepButtons() {
        let row = stepsTable.selectedRow
        let count = current?.steps.count ?? 0
        removeButton.isEnabled = row >= 0
        upButton.isEnabled = row > 0
        downButton.isEnabled = row >= 0 && row < count - 1
    }

    private func report(_ error: Error) {
        Self.logger.error("Editing a partner job failed: \(error.localizedDescription)")
        errorLine.stringValue = "Could not save: \(error.localizedDescription)"
    }

    private func perform(_ work: () throws -> Void) {
        errorLine.stringValue = ""
        do { try work() } catch { report(error) }
        refreshDetail()
    }

    // MARK: - Tables

    public func numberOfRows(in tableView: NSTableView) -> Int {
        tableView === jobsTable ? model.jobs.count : current?.steps.count ?? 0
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        if tableView === jobsTable {
            let field = NSTextField(labelWithString: model.jobs[row].name)
            field.lineBreakMode = .byTruncatingTail
            return field
        }
        guard let step = current?.steps[safe: row] else { return nil }
        switch identifier.rawValue {
        case "environment":
            let popup = NSPopUpButton(frame: .zero, pullsDown: false)
            popup.addItems(withTitles: ["terminal", "claude"])
            popup.selectItem(withTitle: step.environment.rawValue)
            popup.target = self
            popup.action = #selector(stepEdited(_:))
            return popup
        default:
            let field = NSTextField(string: Self.value(of: identifier.rawValue, in: step))
            field.isEditable = true
            field.isBordered = false
            field.drawsBackground = false
            field.lineBreakMode = .byTruncatingTail
            field.target = self
            field.action = #selector(stepEdited(_:))
            return field
        }
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else { return }
        if table === jobsTable {
            flushGuidelines()
            let row = jobsTable.selectedRow
            model.selectedID = model.jobs.indices.contains(row) ? model.jobs[row].id : nil
            refreshDetail()
        } else {
            updateStepButtons()
        }
    }

    private static func value(of column: String, in step: PartnerJobStep) -> String {
        switch column {
        case "name": step.name
        case "command": step.command
        case "condition": step.condition
        default: step.environment.rawValue
        }
    }

    // MARK: - Actions

    @objc private func stepEdited(_ sender: NSView) {
        let row = stepsTable.row(for: sender)
        let column = stepsTable.column(for: sender)
        guard let job = current, job.steps.indices.contains(row), Self.stepColumns.indices.contains(column) else {
            return
        }
        let text = (sender as? NSTextField)?.stringValue ?? (sender as? NSPopUpButton)?.titleOfSelectedItem ?? ""
        perform {
            try model.update(job.id) { job in
                switch Self.stepColumns[column] {
                case "name": job.steps[row].name = text
                case "command": job.steps[row].command = text
                case "condition": job.steps[row].condition = text
                default: job.steps[row].environment = PartnerJobStep.Environment(rawValue: text) ?? .terminal
                }
            }
        }
    }

    @objc private func enabledChanged() {
        guard let job = current else { return }
        let isOn = enabledBox.state == .on
        perform { try model.update(job.id) { $0.isEnabled = isOn } }
    }

    @objc private func scheduleChanged() {
        guard let job = current else { return }
        let text = scheduleField.stringValue.trimmingCharacters(in: .whitespaces)
        let minutes = Int(text)
        guard text.isEmpty || (minutes ?? 0) > 0 else {
            errorLine.stringValue = "Schedule is a whole number of minutes, or empty."
            refreshDetail()
            return
        }
        perform { try model.update(job.id) { $0.scheduleSeconds = minutes.map { $0 * 60 } } }
    }

    @objc private func addStep() {
        guard let job = current else { return }
        flushGuidelines()
        perform { try model.addStep(to: job.id) }
        let last = (current?.steps.count ?? 1) - 1
        stepsTable.selectRowIndexes([last], byExtendingSelection: false)
    }

    @objc private func removeStep() {
        guard let job = current, stepsTable.selectedRow >= 0 else { return }
        let row = stepsTable.selectedRow
        flushGuidelines()
        perform { try model.removeStep(in: job.id, at: row) }
    }

    @objc private func moveStepUp() { moveSelectedStep(by: -1) }
    @objc private func moveStepDown() { moveSelectedStep(by: 1) }

    private func moveSelectedStep(by offset: Int) {
        guard let job = current, stepsTable.selectedRow >= 0 else { return }
        let row = stepsTable.selectedRow
        flushGuidelines()
        perform { try model.moveStep(in: job.id, from: row, to: row + offset) }
        stepsTable.selectRowIndexes([row + offset], byExtendingSelection: false)
    }

    @objc private func resetJob() {
        guard let job = current, job.isBuiltIn else { return }
        guidelinesEdited = false
        perform { try model.resetToDefault(id: job.id) }
    }

    @objc private func apply() {
        flushGuidelines()
        let controller = self.controller
        Task { @MainActor in await controller.restart() }
    }

    // MARK: - Guidelines

    public func textDidChange(_ notification: Notification) { guidelinesEdited = true }

    public func textDidEndEditing(_ notification: Notification) { flushGuidelines() }

    /// Saves the guidelines text to the job's file, only once the owner has typed in it. Comparing the text
    /// alone was not enough: the first `refresh()` selects a row before the text view is filled, and the
    /// selection flush then saved the empty view over the job's guidelines.
    func flushGuidelines() {
        guard guidelinesEdited else { return }
        guidelinesEdited = false
        guard var job = current, guidelinesView.string != job.guidelines else { return }
        job.guidelines = guidelinesView.string
        perform { try model.save(job) }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
