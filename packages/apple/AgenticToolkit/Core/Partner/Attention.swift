import Foundation

/// What an attention item asks of the owner.
public enum AttentionKind: String, Codable, Sendable, CaseIterable { case question, blocked, notification }

/// Where an attention item is in its life.
public enum AttentionState: String, Codable, Sendable { case open, discussing, sent, done }

/// What the owner did to an attention item.
public enum AttentionActionKind: String, Codable, Sendable { case discuss, resolved, confirm, reopen }

/// Something the partner needs the owner to look at.
public struct AttentionItem: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var kind: AttentionKind
    public var text: String
    public var reference: [String: String]
    public var state: AttentionState
    public var createdBy: String
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?

    public init(id: String = UUID().uuidString, kind: AttentionKind, text: String, reference: [String: String] = [:],
                state: AttentionState = .open, createdBy: String, createdAt: Date = Date(), updatedAt: Date = Date(),
                completedAt: Date? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.reference = reference
        self.state = state
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
}

/// One owner action on an attention item, kept as history.
public struct AttentionAction: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var itemID: String
    public var action: AttentionActionKind
    // swiftlint:disable:next identifier_name
    public var at: Date
    public var messageID: String?

    public init(id: String = UUID().uuidString, itemID: String, action: AttentionActionKind,
                // swiftlint:disable:next identifier_name
                at: Date = Date(), messageID: String? = nil) {
        self.id = id
        self.itemID = itemID
        self.action = action
        self.at = at
        self.messageID = messageID
    }
}
