import Foundation
import AgenticToolkitCore

extension PartnerStore {

    private static let itemColumns =
        "id, kind, text, reference_json, state, created_by, created_at, updated_at, completed_at"

    public func insert(_ item: AttentionItem) throws {
        let reference = try Self.json(item.reference, sorted: true)
        try write(.attention) {
            try run("""
                INSERT INTO attention_item (\(Self.itemColumns)) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [.text(item.id), .text(item.kind.rawValue), .text(item.text), .text(reference),
                  .text(item.state.rawValue), .text(item.createdBy), .date(item.createdAt),
                  .date(item.updatedAt), .optDate(item.completedAt)])
        }
    }

    public func update(_ item: AttentionItem) throws {
        let reference = try Self.json(item.reference, sorted: true)
        try write(.attention) {
            try run("""
                UPDATE attention_item SET kind = ?, text = ?, reference_json = ?, state = ?, created_by = ?,
                    created_at = ?, updated_at = ?, completed_at = ? WHERE id = ?
            """, [.text(item.kind.rawValue), .text(item.text), .text(reference), .text(item.state.rawValue),
                  .text(item.createdBy), .date(item.createdAt), .date(item.updatedAt),
                  .optDate(item.completedAt), .text(item.id)])
        }
    }

    public func attentionItem(id: String) throws -> AttentionItem? {
        try locked {
            try runQuery("SELECT \(Self.itemColumns) FROM attention_item WHERE id = ?", [.text(id)],
                         Self.attentionItem(from:)).first
        }
    }

    /// Open, discussing and sent items first (newest first), then done items completed after the cutoff.
    /// With a nil cutoff, done items are left out.
    public func attentionItems(includeDoneCompletedAfter cutoff: Date?) throws -> [AttentionItem] {
        try locked {
            var sql = "SELECT \(Self.itemColumns) FROM attention_item WHERE state != 'done'"
            var binds: [Value] = []
            if let cutoff {
                sql += " OR (state = 'done' AND completed_at > ?)"
                binds.append(.date(cutoff))
            }
            sql += " ORDER BY (state = 'done'), created_at DESC"
            return try runQuery(sql, binds, Self.attentionItem(from:))
        }
    }

    public func record(_ action: AttentionAction) throws {
        try write(.attention) {
            try run("INSERT INTO attention_action (id, item_id, action, at, message_id) VALUES (?, ?, ?, ?, ?)",
                    [.text(action.id), .text(action.itemID), .text(action.action.rawValue), .date(action.at),
                     .optText(action.messageID)])
        }
    }

    public func actions(itemID: String) throws -> [AttentionAction] {
        try locked {
            try runQuery("""
                SELECT id, item_id, action, at, message_id FROM attention_action
                WHERE item_id = ? ORDER BY at, rowid
            """, [.text(itemID)]) { row in
                guard let kind = AttentionActionKind(rawValue: row.text(2)) else {
                    throw PartnerStoreError.invalidData("attention action \(row.text(2))")
                }
                return AttentionAction(id: row.text(0), itemID: row.text(1), action: kind,
                                       at: try row.date(3), messageID: row.optText(4))
            }
        }
    }

    /// Deletes done items completed before `date`, and their actions. Returns the number of items removed.
    public func purgeDone(completedBefore date: Date) throws -> Int {
        try write(.attention) {
            let cutoff = Value.date(date)
            try run("""
                DELETE FROM attention_action WHERE item_id IN
                    (SELECT id FROM attention_item WHERE state = 'done' AND completed_at < ?)
            """, [cutoff])
            return try run("DELETE FROM attention_item WHERE state = 'done' AND completed_at < ?", [cutoff])
        }
    }

    private static func attentionItem(from row: Row) throws -> AttentionItem {
        guard let kind = AttentionKind(rawValue: row.text(1)), let state = AttentionState(rawValue: row.text(4)) else {
            throw PartnerStoreError.invalidData("attention item \(row.text(0))")
        }
        let reference = try JSONDecoder().decode([String: String].self, from: Data(row.text(3).utf8))
        return AttentionItem(id: row.text(0), kind: kind, text: row.text(2), reference: reference, state: state,
                             createdBy: row.text(5), createdAt: try row.date(6), updatedAt: try row.date(7),
                             completedAt: try row.optDate(8))
    }
}
