import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreUI
import AgenticToolkitCoreMacOS

/// Sheet editor for one oversight script: name, the condition rows
/// (`Match All/Any of: [field][op][value]`), optional LLM confirmation, and the
/// response (kind, reason template, action). Edits one group level — a nested
/// predicate tree (possible in the model / via HTTP) renders read-only here and is
/// preserved verbatim on save.
@MainActor
final class ScriptEditorViewController: NSViewController {

    /// Persists the edited script (daemon-side); false = rejected (sheet stays up).
    typealias SaveHandler = @MainActor (OversightScript) async -> Bool

    private var script: OversightScript
    private let onSave: SaveHandler

    private let nameField = NSTextField(string: "")
    private let groupPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let rowsStack = NSStackView()
    private let addRowButton = NSButton(title: "+", target: nil, action: nil)
    private let readOnlySummary = NSTextField(wrappingLabelWithString: "")

    private let llmCheckbox = NSButton(checkboxWithTitle: "Confirm with AI judgment", target: nil, action: nil)
    private let keywordField = NSTextField(string: "")
    private let promptView = NSTextView()

    private let kindField = NSTextField(string: "")
    private let reasonField = NSTextField(string: "")
    private let actionPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let injectField = NSTextField(string: "")

    private let errorLabel = NSTextField(wrappingLabelWithString: "")
    private let saveButton = NSButton(title: "Save", target: nil, action: nil)

    /// The single group level this editor edits, extracted from the predicate when
    /// it is flat; nil = nested tree → read-only predicate UI.
    private var editableRows: [(field: ConditionField, operation: ConditionOperator, value: String)]?
    private var groupIsAll = true

    init(script: OversightScript, onSave: @escaping SaveHandler) {
        self.script = script
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        extractEditableRows()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func extractEditableRows() {
        func conditions(of subs: [ScriptPredicate])
            -> [(field: ConditionField, operation: ConditionOperator, value: String)]? {
            var out: [(ConditionField, ConditionOperator, String)] = []
            for sub in subs {
                guard case .condition(let field, let operation, let value) = sub else { return nil }
                out.append((field, operation, value))
            }
            return out
        }
        switch script.trigger.predicate {
        case .condition(let field, let operation, let value):
            groupIsAll = true
            editableRows = [(field, operation, value)]
        case .all(let subs):
            groupIsAll = true
            editableRows = conditions(of: subs)
        case .any(let subs):
            groupIsAll = false
            editableRows = conditions(of: subs)
        }
    }

    // MARK: - Layout

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 560))

        let form = NSStackView()
        form.orientation = .vertical
        form.alignment = .leading
        form.spacing = 10
        form.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        form.translatesAutoresizingMaskIntoConstraints = false

        nameField.stringValue = script.name
        form.addArrangedSubview(labeledRow("Name", nameField, fieldWidth: 300))

        // Trigger
        form.addArrangedSubview(sectionLabel("Trigger"))
        if editableRows != nil {
            groupPopup.addItems(withTitles: ["All", "Any"])
            groupPopup.selectItem(at: groupIsAll ? 0 : 1)
            let matchRow = NSStackView(views: [
                NSTextField(labelWithString: "Match"), groupPopup, NSTextField(labelWithString: "of:")
            ])
            matchRow.orientation = .horizontal
            matchRow.spacing = 6
            form.addArrangedSubview(matchRow)

            rowsStack.orientation = .vertical
            rowsStack.alignment = .leading
            rowsStack.spacing = 6
            form.addArrangedSubview(rowsStack)
            for row in editableRows ?? [] {
                rowsStack.addArrangedSubview(
                    makeConditionRow(field: row.field, operation: row.operation, value: row.value)
                )
            }

            addRowButton.bezelStyle = .smallSquare
            addRowButton.target = self
            addRowButton.action = #selector(addRow)
            form.addArrangedSubview(addRowButton)
        } else {
            readOnlySummary.stringValue = "Nested trigger (edit via the API): "
                + OversightScriptsViewController.triggerSummary(script.trigger.predicate)
            form.addArrangedSubview(readOnlySummary)
        }

        // LLM confirmation
        llmCheckbox.state = script.trigger.llmConfirmation == nil ? .off : .on
        llmCheckbox.target = self
        llmCheckbox.action = #selector(llmToggled)
        form.addArrangedSubview(llmCheckbox)
        keywordField.stringValue = script.trigger.llmConfirmation?.actKeyword ?? "ACT"
        form.addArrangedSubview(labeledRow("Act keyword", keywordField, fieldWidth: 140))
        promptView.string = script.trigger.llmConfirmation?.systemPrompt ?? ""
        promptView.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        promptView.isRichText = false
        let promptScroll = NSScrollView()
        promptScroll.documentView = promptView
        promptScroll.hasVerticalScroller = true
        promptScroll.borderType = .bezelBorder
        promptScroll.translatesAutoresizingMaskIntoConstraints = false
        promptScroll.heightAnchor.constraint(equalToConstant: 90).isActive = true
        promptView.autoresizingMask = [.width]
        form.addArrangedSubview(labeledRow("System prompt", promptScroll, fieldWidth: 440))

        // Response
        form.addArrangedSubview(sectionLabel("Response"))
        kindField.stringValue = script.response.kind
        form.addArrangedSubview(labeledRow("Kind", kindField, fieldWidth: 160))
        reasonField.stringValue = script.response.reasonTemplate
        reasonField.placeholderString = "Reason — {{context_used_pct}} substitutes live values"
        form.addArrangedSubview(labeledRow("Reason", reasonField, fieldWidth: 440))
        actionPopup.addItems(withTitles: ["Type into terminal", "Record only"])
        actionPopup.target = self
        actionPopup.action = #selector(actionChanged)
        if case .injectText(let text) = script.response.action {
            actionPopup.selectItem(at: 0)
            injectField.stringValue = text
        } else {
            actionPopup.selectItem(at: 1)
        }
        form.addArrangedSubview(labeledRow("Action", actionPopup, fieldWidth: 200))
        injectField.placeholderString = "/compact"
        form.addArrangedSubview(labeledRow("Text", injectField, fieldWidth: 200))

        errorLabel.textColor = .systemRed
        form.addArrangedSubview(errorLabel)

        // Buttons
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelTapped))
        cancel.bezelStyle = .rounded
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.target = self
        saveButton.action = #selector(saveTapped)
        let buttons = NSStackView(views: [cancel, saveButton])
        buttons.orientation = .horizontal
        buttons.spacing = 10
        form.addArrangedSubview(buttons)

        let scroll = NSScrollView()
        scroll.documentView = flipped(wrapping: form)
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: root.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        view = root
        syncEnabledStates()
    }

    private func flipped(wrapping content: NSView) -> NSView {
        let container = TopAnchoredFlippedView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 620)
        ])
        return container
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        return label
    }

    private func labeledRow(_ label: String, _ field: NSView, fieldWidth: CGFloat) -> NSView {
        let labelField = NSTextField(labelWithString: label)
        labelField.alignment = .right
        labelField.widthAnchor.constraint(equalToConstant: 110).isActive = true
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: fieldWidth).isActive = true
        let row = NSStackView(views: [labelField, field])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        return row
    }

    // MARK: - Condition rows

    private func makeConditionRow(
        field: ConditionField, operation: ConditionOperator, value: String
    ) -> NSView {
        let fieldPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        fieldPopup.addItems(withTitles: ConditionField.allCases.map(\.rawValue))
        fieldPopup.selectItem(withTitle: field.rawValue)

        let opPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        opPopup.addItems(withTitles: ConditionOperator.allCases.map(\.rawValue))
        opPopup.selectItem(withTitle: operation.rawValue)

        let valueField = NSTextField(string: value)
        valueField.translatesAutoresizingMaskIntoConstraints = false
        valueField.widthAnchor.constraint(equalToConstant: 160).isActive = true

        let removeButton = NSButton(title: "−", target: self, action: #selector(removeRow(_:)))
        removeButton.bezelStyle = .smallSquare

        let row = NSStackView(views: [fieldPopup, opPopup, valueField, removeButton])
        row.orientation = .horizontal
        row.spacing = 6
        return row
    }

    @objc private func addRow() {
        rowsStack.addArrangedSubview(
            makeConditionRow(field: .contextUsedPct, operation: .greaterOrEqual, value: "80")
        )
    }

    @objc private func removeRow(_ sender: NSButton) {
        guard let row = sender.superview else { return }
        rowsStack.removeArrangedSubview(row)
        row.removeFromSuperview()
    }

    /// Read the condition rows back out of the UI.
    private func currentConditions() -> [(field: ConditionField, operation: ConditionOperator, value: String)] {
        rowsStack.arrangedSubviews.compactMap { row in
            guard let stack = row as? NSStackView, stack.arrangedSubviews.count >= 3,
                  let fieldPopup = stack.arrangedSubviews[0] as? NSPopUpButton,
                  let opPopup = stack.arrangedSubviews[1] as? NSPopUpButton,
                  let valueField = stack.arrangedSubviews[2] as? NSTextField,
                  let field = ConditionField(rawValue: fieldPopup.titleOfSelectedItem ?? ""),
                  let operation = ConditionOperator(rawValue: opPopup.titleOfSelectedItem ?? "")
            else { return nil }
            return (field, operation, valueField.stringValue)
        }
    }

    // MARK: - Actions

    @objc private func llmToggled() { syncEnabledStates() }
    @objc private func actionChanged() { syncEnabledStates() }

    private func syncEnabledStates() {
        let llmOn = llmCheckbox.state == .on
        keywordField.isEnabled = llmOn
        promptView.isEditable = llmOn
        injectField.isEnabled = actionPopup.indexOfSelectedItem == 0
    }

    @objc private func cancelTapped() {
        dismiss(self)
    }

    @objc private func saveTapped() {
        var edited = script
        edited.name = nameField.stringValue

        if editableRows != nil {
            let conditions = currentConditions().map {
                ScriptPredicate.condition(field: $0.field, operation: $0.operation, value: $0.value)
            }
            guard !conditions.isEmpty else {
                errorLabel.stringValue = "Add at least one condition."
                return
            }
            edited.trigger.predicate = groupPopup.indexOfSelectedItem == 0
                ? .all(conditions) : .any(conditions)
        }
        // else: nested tree preserved verbatim.

        if llmCheckbox.state == .on {
            let keyword = keywordField.stringValue.trimmingCharacters(in: .whitespaces)
            guard !keyword.isEmpty else {
                errorLabel.stringValue = "The act keyword must not be empty."
                return
            }
            edited.trigger.llmConfirmation = LLMConfirmation(
                systemPrompt: promptView.string, actKeyword: keyword
            )
        } else {
            edited.trigger.llmConfirmation = nil
        }

        edited.response.kind = kindField.stringValue.trimmingCharacters(in: .whitespaces)
        edited.response.reasonTemplate = reasonField.stringValue
        if actionPopup.indexOfSelectedItem == 0 {
            let text = injectField.stringValue.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else {
                errorLabel.stringValue = "The text to type must not be empty."
                return
            }
            edited.response.action = .injectText(text)
        } else {
            edited.response.action = .none
        }

        guard !edited.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorLabel.stringValue = "The script needs a name."
            return
        }
        guard !edited.response.kind.isEmpty else {
            errorLabel.stringValue = "The response kind must not be empty."
            return
        }
        // Numeric fields need numeric values (mirrors the daemon's validation).
        for condition in currentConditions()
        where editableRows != nil && condition.field.isNumeric && Double(condition.value) == nil {
            errorLabel.stringValue = "'\(condition.field.rawValue)' compares numbers — "
                + "'\(condition.value)' isn't one."
            return
        }

        errorLabel.stringValue = ""
        saveButton.isEnabled = false
        Task { @MainActor in
            defer { saveButton.isEnabled = true }
            if await onSave(edited) {
                dismiss(self)
            } else {
                errorLabel.stringValue = "The daemon rejected the script (is it running?)."
            }
        }
    }
}
