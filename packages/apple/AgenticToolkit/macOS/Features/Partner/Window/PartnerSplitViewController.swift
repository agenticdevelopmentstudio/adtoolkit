import AppKit
import Combine
import AgenticToolkitCore
import os

/// The Coding Partner window's three columns: the shelf, the selected row's
/// content, and "Needs you" as the inspector.
///
/// Turns the attention pane's buttons into controller calls, and keeps the one
/// piece of window state the controller does not: which attention item, if
/// any, the owner is discussing. The next line the composer sends goes to the
/// partner as the reply to that item, and ends the discussion.
@MainActor
public final class PartnerSplitViewController: NSSplitViewController {

    public let shelf = PartnerShelfViewController()
    public let attention: AttentionPaneViewController
    public private(set) var content: PartnerContentViewController!

    /// A reference link in the attention pane was clicked. The app decides what opening it means.
    public var onOpenReference: (([String: String]) -> Void)? {
        get { attention.model.onOpenReference }
        set { attention.model.onOpenReference = newValue }
    }

    private let controller: PartnerController
    private var attentionItem: NSSplitViewItem!
    private var selectedID: PartnerShelfRow.ID = PartnerShelfRow.partnerID
    /// The middle column shows a live session's terminal, which its close replaces with the final screen.
    private var showsLiveSession = false
    /// The attention item the owner pressed Discuss on and has not replied to yet.
    private var discussionItemID: String?
    private var subscriptions: Set<AnyCancellable> = []
    private var sessionSubscriptions: Set<AnyCancellable> = []
    private var paneVisibleObserver: UserSettingObserver<Bool>?
    private var collapseObservation: NSKeyValueObservation?

    public init(controller: PartnerController) {
        self.controller = controller
        attention = AttentionPaneViewController(model: AttentionPaneModel(
            store: controller.store,
            retentionDays: { UserSettings.partnerAttentionRetentionDays.value }))
        super.init(nibName: nil, bundle: nil)
        content = PartnerContentViewController(controller: controller) { [weak self] text in
            self?.sendFromComposer(text)
        }
        wireAttention()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // No split autosave: it would also restore the inspector's collapsed state, a second source of truth
        // beside `partnerAttentionPaneVisible`.
        let shelfItem = NSSplitViewItem(sidebarWithViewController: shelf)
        shelfItem.minimumThickness = 180
        shelfItem.canCollapse = true
        addSplitViewItem(shelfItem)

        let contentItem = NSSplitViewItem(viewController: content)
        contentItem.minimumThickness = 300
        addSplitViewItem(contentItem)

        let attentionItem = NSSplitViewItem(inspectorWithViewController: attention)
        attentionItem.minimumThickness = 260
        attentionItem.canCollapse = true
        attentionItem.isCollapsed = !UserSettings.partnerAttentionPaneVisible.value
        addSplitViewItem(attentionItem)
        self.attentionItem = attentionItem
        bindAttentionVisibility()

        shelf.onSelect = { [weak self] id in self?.select(id) }
        observeRows()
        reloadRows()
        select(selectedID)
    }

    // MARK: - Selection

    /// Shows the row with `id` in the middle column and selects it on the shelf. An id no longer listed
    /// shows the partner.
    public func select(_ row: PartnerShelfRow.ID) {
        loadViewIfNeeded()
        if row != PartnerShelfRow.partnerID, let id = UUID(uuidString: row),
           let session = controller.sessions.session(id: id) {
            content.show(session: session)
            showsLiveSession = true
        } else if row != PartnerShelfRow.partnerID, let record = closedRecord(id: row) {
            content.showClosed(record)
            showsLiveSession = false
        } else {
            showsLiveSession = false
            selectedID = PartnerShelfRow.partnerID
            content.showPartner()
            shelf.setSelection(selectedID)
            return
        }
        selectedID = row
        shelf.setSelection(row)
    }

    /// Puts `text` in the partner's composer with the cursor at its end, showing the partner first.
    public func prefillComposer(_ text: String) {
        select(PartnerShelfRow.partnerID)
        let chatView = content.chatView
        guard let field = chatView.composerField as? NSTextField else { return }
        field.stringValue = text
        // The send button follows the delegate's text-changed call, which a programmatic set does not make.
        chatView.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        chatView.focusInput()
        field.currentEditor()?.selectedRange = NSRange(location: (text as NSString).length, length: 0)
    }

    // MARK: - Composer

    /// The owner's reply to the item under discussion: an owner line carrying the item id, so the partner
    /// can close it with `partner_attention_update`.
    static func discussionReply(itemID: String, text: String) -> PartnerInbound {
        let attribution = ChatMessage.Attribution(
            sourceID: PartnerController.attentionSourcePrefix + itemID, context: [], name: "Discuss",
            iconSymbol: "bubble.left.and.bubble.right")
        return .owner(text: "Regarding attention item \(itemID):\n\(text)", attribution: attribution)
    }

    private func sendFromComposer(_ text: String) {
        guard let itemID = discussionItemID else {
            controller.chatSession.send(text)
            return
        }
        discussionItemID = nil
        controller.enqueue(Self.discussionReply(itemID: itemID, text: text))
    }

    // MARK: - Attention

    private func wireAttention() {
        let model = attention.model
        model.onDiscuss = { [weak self] id in self?.discuss(itemID: id) }
        model.onResolved = { [weak self] id in self?.press(.resolved, itemID: id) }
        model.onConfirm = { [weak self] id in self?.press(.confirm, itemID: id) }
    }

    private func discuss(itemID: String) {
        do {
            let quoted = try controller.beginDiscussion(itemID: itemID)
            discussionItemID = itemID
            prefillComposer(quoted)
        } catch {
            Self.logger.error("Discuss on \(itemID) failed: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    private func press(_ action: AttentionActionKind, itemID: String) {
        do {
            try controller.performButton(action, itemID: itemID)
            // A Resolved on the item being discussed settles it: the next composer line is ordinary again.
            if discussionItemID == itemID { discussionItemID = nil }
        } catch {
            Self.logger.error("\(action.rawValue) on \(itemID) failed: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    /// The inspector follows the setting, and a toggle in the window writes it back.
    private func bindAttentionVisibility() {
        paneVisibleObserver = UserSettingObserver(UserSettings.partnerAttentionPaneVisible) { [weak self] visible in
            guard let item = self?.attentionItem, item.isCollapsed == visible else { return }
            item.animator().isCollapsed = !visible
        }
        collapseObservation = attentionItem.observe(\.isCollapsed, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated {
                guard let item = self?.attentionItem else { return }
                let visible = !item.isCollapsed
                if UserSettings.partnerAttentionPaneVisible.value != visible {
                    UserSettings.partnerAttentionPaneVisible.value = visible
                }
            }
        }
    }

    // MARK: - Rows

    private func observeRows() {
        controller.$state
            .sink { [weak self] _ in self?.scheduleReload() }
            .store(in: &subscriptions)
        controller.sessions.$sessions
            .sink { [weak self] sessions in self?.observe(sessions) }
            .store(in: &subscriptions)
        controller.store.changes
            // Main first: the filter closure is main-actor isolated, and writes arrive from MCP calls off it.
            .receive(on: DispatchQueue.main)
            // A review's state and summary are in its session's subtitle.
            .filter { $0 == .sessions || $0 == .reviews }
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.reloadRows() } }
            .store(in: &subscriptions)
    }

    /// A session's state is in its row's subtitle, so each live session's changes reload the rows too.
    private func observe(_ sessions: [PartnerSession]) {
        sessionSubscriptions = []
        for session in sessions {
            session.$state
                .sink { [weak self] _ in self?.scheduleReload() }
                .store(in: &sessionSubscriptions)
        }
        scheduleReload()
    }

    /// `@Published` sends before the value changes, so the rows are rebuilt on the next main-queue turn.
    private func scheduleReload() {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated { self?.reloadRows() }
        }
    }

    private func reloadRows() {
        let live = controller.sessions.sessions
        let liveIDs = Set(live.map(\.id.uuidString))
        var rows: [PartnerShelfRow] = [.partner(status: controller.state.displayText)]
        for session in live {
            let subtitle = PartnerShelfRow.sessionSubtitle(
                directory: session.directory, state: session.state.rawValue, review: review(id: session.reviewID),
                sessionID: session.id.uuidString)
            rows.append(.session(id: session.id.uuidString, title: session.title, subtitle: subtitle,
                                 isLive: true))
        }
        for record in storedRecords() where !liveIDs.contains(record.id) {
            let subtitle = PartnerShelfRow.sessionSubtitle(
                directory: record.directory, state: "closed", review: review(id: record.reviewID),
                sessionID: record.id)
            rows.append(.session(id: record.id, title: record.title, subtitle: subtitle, isLive: false))
        }
        shelf.rows = rows
        // The row on show went away (a purge): fall back to the partner. A live session that closed is
        // still listed, now as a closed one, and its final screen replaces the terminal.
        if !rows.contains(where: { $0.id == selectedID }) {
            select(PartnerShelfRow.partnerID)
        } else if showsLiveSession, !liveIDs.contains(selectedID) {
            select(selectedID)
        }
    }

    private func storedRecords() -> [PartnerStore.SessionRecord] {
        do { return try controller.store.sessions() } catch {
            Self.logger.error("Loading partner sessions failed: \(error.localizedDescription)")
            return []
        }
    }

    /// An unreadable review leaves the row with its plain folder-and-state line.
    private func review(id: String?) -> PartnerReview? {
        guard let id else { return nil }
        do { return try controller.store.review(id: id) } catch {
            Self.logger.error("Loading review \(id) failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func closedRecord(id: String) -> PartnerStore.SessionRecord? {
        storedRecords().first { $0.id == id }
    }
}

extension PartnerSplitViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
