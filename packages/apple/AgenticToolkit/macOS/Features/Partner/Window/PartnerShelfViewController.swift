import AppKit
import AgenticToolkitCore

/// One row of the Coding Partner shelf: the partner's own conversation, or a terminal session it opened.
public enum PartnerShelfRow: Identifiable, Equatable {
    case partner(status: String)
    case session(id: String, title: String, subtitle: String, isLive: Bool)

    /// "partner" or the session id.
    public var id: String {
        switch self {
        case .partner: return Self.partnerID
        case .session(let id, _, _, _): return id
        }
    }

    public static let partnerID = "partner"

    var title: String {
        switch self {
        case .partner: return "Partner"
        case .session(_, let title, _, _): return title
        }
    }

    var subtitle: String {
        switch self {
        case .partner(let status): return status
        case .session(_, _, let subtitle, _): return subtitle
        }
    }

    var symbol: String {
        switch self {
        case .partner: return "person.crop.circle"
        case .session(_, _, _, let isLive): return isLive ? "terminal" : "terminal.fill"
        }
    }

    var isDimmed: Bool {
        if case .session(_, _, _, false) = self { return true }
        return false
    }
}

/// The Coding Partner's left column: one row per ``PartnerShelfRow``.
@MainActor
public final class PartnerShelfViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    /// Replacing the rows keeps the selection on the same id when it is still listed.
    public var rows: [PartnerShelfRow] = [] {
        didSet {
            guard rows != oldValue else { return }
            reloadKeepingSelection()
        }
    }

    /// A row was clicked or moved to.
    public var onSelect: ((PartnerShelfRow.ID) -> Void)?

    private let tableView = NSTableView()
    private var isSettingSelection = false

    public override func loadView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("row"))
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.style = .sourceList
        tableView.rowHeight = 40
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setAccessibilityIdentifier("partner.shelf")

        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        view = scroll
    }

    /// Selects the row with `id` without reporting it through ``onSelect``.
    public func setSelection(_ id: PartnerShelfRow.ID) {
        selectedID = id
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        isSettingSelection = true
        defer { isSettingSelection = false }
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
    }

    private func reloadKeepingSelection() {
        isSettingSelection = true
        tableView.reloadData()
        tableView.deselectAll(nil)
        isSettingSelection = false
        if let selectedID { setSelection(selectedID) }
    }

    /// The selected row's id: rows move as sessions open, so the selection follows the id, not the index.
    private var selectedID: PartnerShelfRow.ID?

    // MARK: - Table

    public func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("PartnerShelfCell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? PartnerShelfCell
            ?? PartnerShelfCell(identifier: identifier)
        cell.configure(rows[row])
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        let index = tableView.selectedRow
        guard !isSettingSelection, rows.indices.contains(index) else { return }
        selectedID = rows[index].id
        onSelect?(rows[index].id)
    }
}

/// A shelf row: symbol, title, and a one-line status beneath it.
private final class PartnerShelfCell: NSTableCellView {
    private let symbol = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let subtitle = NSTextField(labelWithString: "")

    init(identifier: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        self.identifier = identifier
        title.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        title.lineBreakMode = .byTruncatingTail
        subtitle.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byTruncatingTail
        let text = NSStackView(views: [title, subtitle])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 1
        let row = NSStackView(views: [symbol, text])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            symbol.widthAnchor.constraint(equalToConstant: 18),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            row.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            row.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        textField = title
        imageView = symbol
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(_ row: PartnerShelfRow) {
        symbol.image = NSImage(systemSymbolName: row.symbol, accessibilityDescription: nil)
        title.stringValue = row.title
        subtitle.stringValue = row.subtitle
        title.textColor = row.isDimmed ? .secondaryLabelColor : .labelColor
        setAccessibilityIdentifier("partner.shelf.\(row.id)")
    }
}
