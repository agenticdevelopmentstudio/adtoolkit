import Foundation

/// Outcome of parsing a drop-file (`ParseResult.parse(envelopeJSON:)`). Splitting
/// the old overloaded `nil` into three cases is what makes it impossible to
/// mistake a valid-but-untracked event for a malformed one:
/// - `.event`  — ingest it.
/// - `.skip`   — well-formed but intentionally not tracked (no session_id);
///               discard quietly, never an error. Collapsing this into `.unparseable`
///               is what quarantined valid StatusLine events and lit the error badge.
/// - `.lostEvent` — the file is empty: its writer died between creating it and
///               filling it, so the event is gone. A real loss, but not a
///               recoverable one — quarantining it burns the retry budget on a
///               file that can never parse and then lights the badge forever.
///               Logged as a terminal `lost` row instead.
/// - `.unparseable` — malformed JSON / missing event type; a real error → quarantine.
public enum ParseResult: Sendable {
    case event(ParsedEvent)
    case skip(reason: String)
    case lostEvent
    case unparseable
}

extension ParseResult {

    /// Parses the envelope format:
    /// `{"event": "PreToolUse", "timestamp": "...", "hook_data": {...}, "context": {...}}`
    /// `context` is optional — present in v5+ drops, absent in legacy v4 drops or
    /// hand-crafted test fixtures.
    ///
    /// The inverse of ``ParsedEvent/envelopeJSON()``.
    public static func parse(envelopeJSON rawJson: String) -> ParseResult {
        // An empty drop file is not malformed JSON — it is a file whose writer
        // died between creating it and filling it, so whatever event it carried
        // is already gone. Deciding that here keeps the live scan and the
        // quarantine retry from drifting on what "empty" means.
        guard !rawJson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .lostEvent
        }
        guard let data = rawJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let eventType = json["event"] as? String,
              !eventType.isEmpty else {
            return .unparseable
        }
        let hookData = json["hook_data"] as? [String: Any] ?? [:]
        guard let sessionId = hookData["session_id"] as? String, !sessionId.isEmpty else {
            // Well-formed but not tied to a session — e.g. a StatusLine drop that
            // carries only term_session_id. We don't track session-less events (the
            // socket path, the envelope builder, drops them too), but that's a
            // deliberate skip, NOT a parse error: never quarantine it.
            return .skip(reason: "no session_id — not a trackable session event")
        }
        _ = sessionId
        let timestamp = json["timestamp"] as? String ?? ""
        let context = json["context"] as? [String: Any]
        let accountEmail = json["account_email"] as? String ?? ""
        // Absent (not empty) for envelopes written before the field existed —
        // see `ParsedEvent.oauthAccountEmail`, where the two mean different things.
        let oauthAccountEmail = json["oauth_account_email"] as? String
        return .event(ParsedEvent(eventType: eventType, timestamp: timestamp,
                                  hookData: hookData, context: context, accountEmail: accountEmail,
                                  oauthAccountEmail: oauthAccountEmail))
    }
}
