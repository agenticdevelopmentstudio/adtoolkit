import Foundation
import AgenticToolkitCore

extension PartnerStore {

    /// The attribution's trail and app identity, which share one column.
    private struct StoredContext: Codable {
        var context: [String]
        var appIdentity: String
    }

    public func append(_ message: ChatMessage) throws {
        var source: String?
        var name: String?
        var icon: String?
        var contextJSON: String?
        if let attribution = message.attribution {
            source = attribution.sourceID
            name = attribution.name
            icon = attribution.iconSymbol
            let stored = StoredContext(context: attribution.context, appIdentity: attribution.appIdentity)
            contextJSON = try Self.json(stored)
        }
        try write(.transcript) {
            try run("""
                INSERT INTO partner_message (id, role, text, attribution_source, attribution_name,
                    attribution_icon, attribution_context_json, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [.text(message.id), .text(message.role.scriptingLabel), .text(message.text),
                  .optText(source), .optText(name), .optText(icon), .optText(contextJSON),
                  .date(message.timestamp)])
        }
    }

    /// The newest `limit` messages, oldest first.
    public func transcript(limit: Int) throws -> [ChatMessage] {
        try locked {
            try runQuery("""
                SELECT id, role, text, attribution_source, attribution_name, attribution_icon,
                    attribution_context_json, created_at
                FROM partner_message ORDER BY rowid DESC LIMIT ?
            """, [.int(Int64(max(limit, 0)))], Self.message(from:)).reversed()
        }
    }

    public func clearTranscript() throws {
        try write(.transcript) { try run("DELETE FROM partner_message", []) }
    }

    private static func message(from row: Row) throws -> ChatMessage {
        let role: ChatMessage.Role
        switch row.text(1) {
        case "user": role = .user
        case "assistant": role = .assistant
        case "error": role = .error
        case "notice": role = .notice
        default: throw PartnerStoreError.invalidData("message role \(row.text(1))")
        }
        var attribution: ChatMessage.Attribution?
        if let source = row.optText(3) {
            let stored = try row.optText(6).map {
                try JSONDecoder().decode(StoredContext.self, from: Data($0.utf8))
            }
            attribution = ChatMessage.Attribution(
                sourceID: source, context: stored?.context ?? [], name: row.optText(4) ?? "",
                iconSymbol: row.optText(5) ?? "", appIdentity: stored?.appIdentity ?? "")
        }
        return ChatMessage(id: row.text(0), role: role, text: row.text(2), timestamp: try row.date(7),
                           attribution: attribution)
    }
}
