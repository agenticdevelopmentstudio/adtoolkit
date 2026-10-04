import Foundation

/// Hand-written rather than synthesized, and keyed on ``ContextEventKind``.
///
/// Swift's synthesized enum coding invents its own case keys (`appFocus`,
/// `titleChanged`, …). This payload crosses a process boundary — the daemon
/// serializes a page of the event log and the app decodes it — so the wire
/// tag has to be the same string the schema already calls the kind
/// (`"app_focus"`), not a compiler-chosen spelling that would silently
/// change if a case were renamed.
///
/// The tag is therefore `ContextEventKind`, the single existing source of
/// truth for kind names, which also makes `kind` and payload impossible to
/// disagree across the wire: the decoder switches on the tag and can only
/// produce the matching case.
extension ContextEventDetail: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case payload
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        switch self {
        case .appFocus(let detail): try container.encode(detail, forKey: .payload)
        case .window(let detail):   try container.encode(detail, forKey: .payload)
        case .network(let detail):  try container.encode(detail, forKey: .payload)
        case .location(let detail): try container.encode(detail, forKey: .payload)
        case .input(let detail):    try container.encode(detail, forKey: .payload)
        case .session(let detail):  try container.encode(detail, forKey: .payload)
        case .power(let detail):    try container.encode(detail, forKey: .payload)
        case .appLifecycle(let detail): try container.encode(detail, forKey: .payload)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(ContextEventKind.self, forKey: .kind)
        switch kind {
        case .appFocus: self = .appFocus(try container.decode(AppFocusDetail.self, forKey: .payload))
        case .window:   self = .window(try container.decode(WindowDetail.self, forKey: .payload))
        case .network:  self = .network(try container.decode(NetworkDetail.self, forKey: .payload))
        case .location: self = .location(try container.decode(LocationDetail.self, forKey: .payload))
        case .input:    self = .input(try container.decode(InputDetail.self, forKey: .payload))
        case .session:  self = .session(try container.decode(SessionDetail.self, forKey: .payload))
        case .power:    self = .power(try container.decode(PowerDetail.self, forKey: .payload))
        case .appLifecycle: self = .appLifecycle(try container.decode(AppLifecycleDetail.self, forKey: .payload))
        }
    }
}
