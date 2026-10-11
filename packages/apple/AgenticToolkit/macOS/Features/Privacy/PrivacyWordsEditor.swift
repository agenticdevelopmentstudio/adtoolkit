import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreUI

/// The sheet that edits the privacy words: a table of alias and real pairs,
/// each word edited in place, with add and remove beneath it and Save and
/// Cancel under that.
///
/// Edits are a draft until Save, which asks the user to authenticate and then
/// writes them to the keychain through the vault — Cancel leaves the words as
/// they were. The vault must already hold the words: whoever opens this has
/// just made the user authenticate.
///
/// Everything in it sits inside a ``ConcealedContainerView``, revealed for as
/// long as the sheet is up, so neither the accessibility API nor a screen
/// capture can read the words off it; and the sheet's window answers the
/// accessibility focus question with itself, so the field being typed in is
/// not named either.
@MainActor
public final class PrivacyWordsEditor: NSObject {

    private struct DraftRow {
        let id = UUID().uuidString
        var alias: String
        var real: String
    }

    private enum Column {
        static let alias = "alias"
        static let real = "real"
    }

    private let vault: PrivacyWordsVault
    private var rows: [DraftRow]
    private let card: ComposableSettings.EditableTableCard
    private let window: NSWindow
    private weak var parentWindow: NSWindow?
    /// Keeps the editor alive while its sheet is up: nothing else holds it.
    private var retainedSelf: PrivacyWordsEditor?
    /// Save's authentication is on screen, so a second press does not stack another.
    private var isSaving = false

    /// Opens the editor as a sheet on `parentWindow`.
    public static func present(vault: PrivacyWordsVault, on parentWindow: NSWindow) {
        let editor = PrivacyWordsEditor(vault: vault, parentWindow: parentWindow)
        editor.retainedSelf = editor
        parentWindow.beginSheet(editor.window)
        editor.beginEditingFirstRowIfEmpty()
    }

    private init(vault: PrivacyWordsVault, parentWindow: NSWindow) {
        precondition(vault.isLoaded, "The privacy words editor opened without the words loaded.")
        self.vault = vault
        self.parentWindow = parentWindow
        rows = (vault.filter?.pairs ?? []).map { DraftRow(alias: $0.alias, real: $0.real) }
        card = ComposableSettings.EditableTableCard(
            title: "Privacy Words",
            columns: [
                .init(id: Column.alias, title: "Shown as", width: 200, kind: .text(editable: true)),
                .init(id: Column.real, title: "Real word", width: 200, kind: .text(editable: true))
            ],
            emptyMessage: "No privacy words yet — add one with +.",
            visibleRows: 8,
            accessibilityPrefix: "privacyWords")
        window = ConcealedSheetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false)
        super.init()
        window.title = "Privacy Words"
        window.minSize = NSSize(width: 420, height: 300)
        window.contentView = makeContent()
        wireCard()
        reloadRows()
    }

    // MARK: - Layout

    private func makeContent() -> NSView {
        let concealed = ConcealedContainerView()
        concealed.isRevealed = true

        let explanation = NSTextField(wrappingLabelWithString:
            "A private terminal shows each real word as the word it is shown as, "
            + "and types the real word whenever you type the other. The words are "
            + "kept in the keychain and nowhere else.")
        explanation.textColor = .secondaryLabelColor
        explanation.translatesAutoresizingMaskIntoConstraints = false

        let tableArea = TableFillingView(card: card)
        tableArea.translatesAutoresizingMaskIntoConstraints = false

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancel.bezelStyle = .rounded
        cancel.keyEquivalent = "\u{1b}"
        let save = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        save.bezelStyle = .rounded
        save.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, save])
        buttons.orientation = .horizontal
        buttons.spacing = 12
        buttons.translatesAutoresizingMaskIntoConstraints = false

        for view in [explanation, tableArea, buttons] { concealed.addSubview(view) }
        let margin: CGFloat = 20
        NSLayoutConstraint.activate([
            explanation.topAnchor.constraint(equalTo: concealed.topAnchor, constant: margin),
            explanation.leadingAnchor.constraint(equalTo: concealed.leadingAnchor, constant: margin),
            concealed.trailingAnchor.constraint(equalTo: explanation.trailingAnchor, constant: margin),

            tableArea.topAnchor.constraint(equalTo: explanation.bottomAnchor, constant: 12),
            tableArea.leadingAnchor.constraint(equalTo: concealed.leadingAnchor, constant: margin),
            concealed.trailingAnchor.constraint(equalTo: tableArea.trailingAnchor, constant: margin),

            buttons.topAnchor.constraint(equalTo: tableArea.bottomAnchor, constant: 16),
            concealed.trailingAnchor.constraint(equalTo: buttons.trailingAnchor, constant: margin),
            concealed.bottomAnchor.constraint(equalTo: buttons.bottomAnchor, constant: margin)
        ])
        return concealed
    }

    // MARK: - The draft

    private func wireCard() {
        card.onAdd = { [weak self] in self?.addRow() }
        card.onRemove = { [weak self] id in
            self?.rows.removeAll { $0.id == id }
            self?.reloadRows()
        }
        card.onEdit = { [weak self] id, column, value in
            guard let self, let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            let word = value.trimmingCharacters(in: .whitespaces)
            if column == Column.alias { self.rows[index].alias = word } else { self.rows[index].real = word }
            self.reloadRows()
        }
    }

    private func reloadRows() {
        card.setRows(rows.map { row in
            ComposableSettings.EditableTableRow(
                id: row.id,
                cells: [Column.alias: .text(row.alias), Column.real: .text(row.real)],
                // Half a pair is dropped on save; the tint says so before then.
                isFlagged: row.alias.isEmpty != row.real.isEmpty)
        })
    }

    private func addRow() {
        rows.append(DraftRow(alias: "", real: ""))
        reloadRows()
        beginEditing(row: rows.count - 1)
    }

    private func beginEditingFirstRowIfEmpty() {
        if rows.isEmpty { addRow() }
    }

    private func beginEditing(row: Int) {
        let table = card.tableView
        guard row < table.numberOfRows else { return }
        table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        table.scrollRowToVisible(row)
        table.editColumn(0, row: row, with: nil, select: true)
    }

    // MARK: - Save and Cancel

    @objc private func save(_ sender: Any?) {
        // A cell still being typed in commits by losing focus.
        window.makeFirstResponder(nil)
        let pairs = rows.map { TextSubstitutionFilter.Pair(alias: $0.alias, real: $0.real) }
        guard !isSaving else { return }
        isSaving = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isSaving = false }
            do {
                try await self.vault.save(pairs, reason: "save the privacy words")
                self.close()
            } catch {
                let alert = NSAlert()
                alert.messageText = "The privacy words could not be saved."
                alert.informativeText = error.localizedDescription
                alert.beginSheetModal(for: self.window, completionHandler: nil)
            }
        }
    }

    @objc private func cancel(_ sender: Any?) {
        close()
    }

    private func close() {
        // The draft goes with the sheet: nothing typed here outlives it.
        rows.removeAll()
        card.setRows([])
        parentWindow?.endSheet(window)
        window.orderOut(nil)
        retainedSelf = nil
    }
}

/// Holds the card at the top and gives its table whatever height is left, so
/// the table grows and shrinks with the sheet. The card itself keeps a fixed
/// height by design; telling it the height is the owner's job.
@MainActor
private final class TableFillingView: NSView {

    private let card: ComposableSettings.EditableTableCard

    init(card: ComposableSettings.EditableTableCard) {
        self.card = card
        super.init(frame: .zero)
        addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
        // Shrinks below the card's current height so the slack can go negative.
        let minimum = heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        minimum.isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let slack = bounds.height - card.frame.height
        if abs(slack) > 0.5 { card.tableHeight += slack }
    }
}

/// The sheet's window: whatever has focus inside it, the accessibility API is
/// told the window itself is focused, so the word being typed is never named.
@MainActor
private final class ConcealedSheetWindow: NSWindow {
    override var accessibilityFocusedUIElement: Any? { self }
}
