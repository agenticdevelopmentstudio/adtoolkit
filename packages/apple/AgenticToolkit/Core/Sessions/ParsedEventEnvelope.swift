import Foundation

extension ParsedEvent {

    /// The session this event belongs to. Stored on the spool row so a backlog
    /// can be read by session without decoding every envelope.
    public var sessionId: String {
        (hookData["session_id"] as? String) ?? ""
    }

    /// This event re-encoded as the drop-file envelope — the same shape
    /// `ParseResult.parse(envelopeJSON:)` reads, which is the point: the spool
    /// stores one opaque blob and round-trips it through the parser every other
    /// capture path already uses, so spooling adds no second format to keep in
    /// step and no second decoder to get wrong.
    ///
    /// Built at capture time, never at drain time. the envelope builder resolves the
    /// live `claude` process by cwd and reads its environment, so the facts in
    /// `context` are only true at the moment the hook fires; deferring the build
    /// would attribute an event to whatever process happens to hold that cwd
    /// minutes later.
    public func envelopeJSON() throws -> Data {
        var envelope: [String: Any] = [
            "event": eventType,
            "timestamp": timestamp,
            "hook_data": hookData,
            "account_email": accountEmail
        ]
        if let context { envelope["context"] = context }
        // Only written when it was actually resolved, so a round-trip preserves
        // the nil that means "this envelope never carried one".
        if let oauthAccountEmail { envelope["oauth_account_email"] = oauthAccountEmail }
        // A payload that can't be serialized can't be spooled, and finding that
        // out here — on the hook delivery, with the event still in hand — is the
        // difference between one logged capture failure and a row that fails to
        // decode on every drain forever.
        guard JSONSerialization.isValidJSONObject(envelope) else {
            throw EnvelopeEncodingError.notSerializable(eventType)
        }
        return try JSONSerialization.data(withJSONObject: envelope)
    }
}

/// Why an event could not be written to the spool.
public enum EnvelopeEncodingError: LocalizedError {
    /// A hook payload carried something `JSONSerialization` won't take.
    case notSerializable(String)

    public var errorDescription: String? {
        switch self {
        case .notSerializable(let eventType):
            return "\(eventType) payload is not JSON-serializable"
        }
    }
}
