import Foundation
import AgenticToolkitCore

/// The owner's buttons on attention items. Each one speaks to the partner in the owner's voice.
extension PartnerController {

    /// Resolved or Confirm: records the action, sends "Resolved: …" / "Confirmed: …" as the owner, and moves
    /// the item to `.sent`. The partner's next message after that line goes out completes it.
    public func performButton(_ action: AttentionActionKind, itemID: String) throws {
        let verb: String
        let name: String
        switch action {
        case .resolved: verb = "Resolved"; name = "Resolved"
        case .confirm: verb = "Confirmed"; name = "Confirm"
        case .discuss, .reopen: throw ControllerError.unsupportedAction(action)
        }
        guard var item = try store.attentionItem(id: itemID) else { throw ControllerError.unknownItem(itemID) }
        let source = Self.attentionSourcePrefix + itemID
        let messageID = UUID().uuidString
        try store.record(AttentionAction(itemID: itemID, action: action, at: now(), messageID: messageID))
        item.state = .sent
        item.updatedAt = now()
        try store.update(item)
        presetMessageIDs[source] = messageID
        let attribution = ChatMessage.Attribution(sourceID: source, context: [], name: name,
                                                  iconSymbol: "checkmark.circle")
        enqueue(.owner(text: "\(verb): \(item.text)", attribution: attribution))
    }

    /// Discuss: records the action, moves the item to `.discussing`, and returns its text quoted for the
    /// owner's reply. The window sends that reply as `.owner` with a "Discuss" attribution.
    public func beginDiscussion(itemID: String) throws -> String {
        guard var item = try store.attentionItem(id: itemID) else { throw ControllerError.unknownItem(itemID) }
        try store.record(AttentionAction(itemID: itemID, action: .discuss, at: now()))
        item.state = .discussing
        item.updatedAt = now()
        try store.update(item)
        return "> " + item.text.replacingOccurrences(of: "\n", with: "\n> ") + "\n\n"
    }

    /// Marks every item whose button line has gone out `.done`. Called on each message from the partner.
    func completeAwaitedItems() {
        guard !awaitingDone.isEmpty else { return }
        let ids = awaitingDone
        awaitingDone = []
        for id in ids {
            do {
                guard var item = try store.attentionItem(id: id), item.state == .sent else { continue }
                let completed = now()
                item.state = .done
                item.completedAt = completed
                item.updatedAt = completed
                try store.update(item)
            } catch {
                Self.logger.error("Completing attention item \(id) failed: \(error.localizedDescription)")
            }
        }
    }
}
