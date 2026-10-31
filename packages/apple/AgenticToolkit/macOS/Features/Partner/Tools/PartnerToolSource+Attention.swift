import Foundation
import AgenticToolkitCore

extension PartnerToolSource {

    static var attentionDefinitions: [ToolDefinition] {
        let kinds = AttentionKind.allCases.map(\.rawValue).joined(separator: ", ")
        let reference = ["type": "object", "description": "String keys to string values naming what this is about.",
                         "additionalProperties": ["type": "string"]] as [String: Any]
        return [
            ToolDefinition(
                name: "partner_attention_create",
                description: "Creates an attention item for the owner: kind, text, optional reference.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "kind": ToolJSONSchema.string("One of: \(kinds)."),
                    "text": ToolJSONSchema.string("What the owner needs to know or decide."),
                    "reference": reference
                ], required: ["kind", "text"])),
            ToolDefinition(
                name: "partner_attention_update",
                description: "Changes an attention item's text or marks it done.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "id": ToolJSONSchema.string("The item's id."),
                    "text": ToolJSONSchema.string("The new text."),
                    "done": ToolJSONSchema.boolean("True to mark the item done.")
                ], required: ["id"])),
            ToolDefinition(
                name: "partner_attention_list",
                description: "Lists open attention items, and done items still in the retention window.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [:])),
            ToolDefinition(
                name: "partner_notify",
                description: "Posts a macOS notification and records it as an attention item of kind notification.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "title": ToolJSONSchema.string("The notification title."),
                    "body": ToolJSONSchema.string("The notification body."),
                    "reference": reference
                ], required: ["title", "body"]))
        ]
    }

    func attentionTool(_ name: String, _ data: Data) async -> (content: String, isError: Bool) {
        let args = Self.arguments(data)
        let reference = (args["reference"] as? [String: Any])?.compactMapValues { $0 as? String } ?? [:]
        let caller = callerID() ?? "partner"
        do {
            switch name {
            case "partner_attention_create":
                guard let kindName = args["kind"] as? String, let kind = AttentionKind(rawValue: kindName) else {
                    return Self.failure("kind must be one of: "
                        + AttentionKind.allCases.map(\.rawValue).joined(separator: ", "))
                }
                guard let text = args["text"] as? String, !text.isEmpty else { return Self.failure("text is required") }
                let item = try await MainActor.run {
                    try self.notifier.notify(kind: kind, title: text, body: "", reference: reference,
                                             createdBy: caller)
                }
                return Self.encode(item)
            case "partner_notify":
                guard let title = args["title"] as? String, let body = args["body"] as? String else {
                    return Self.failure("title and body are required")
                }
                let item = try await MainActor.run {
                    try self.notifier.notify(title: title, body: body, reference: reference, createdBy: caller)
                }
                return Self.encode(item)
            case "partner_attention_update":
                guard let id = args["id"] as? String, var item = try store.attentionItem(id: id) else {
                    return Self.failure("no attention item with that id")
                }
                if let text = args["text"] as? String { item.text = text }
                if args["done"] as? Bool == true {
                    item.state = .done
                    item.completedAt = Date()
                }
                item.updatedAt = Date()
                try store.update(item)
                return Self.encode(item)
            case "partner_attention_list":
                let days = await MainActor.run { UserSettings.partnerAttentionRetentionDays.value }
                let cutoff = Date().addingTimeInterval(-TimeInterval(days) * 86_400)
                return Self.encode(try store.attentionItems(includeDoneCompletedAfter: cutoff))
            default:
                return ("unknown tool \(name)", true)
            }
        } catch {
            return Self.failure("\(name) failed: \(error.localizedDescription)")
        }
    }
}
