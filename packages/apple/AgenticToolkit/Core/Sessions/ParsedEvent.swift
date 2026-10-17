import Foundation

/// A hook event ready for ingestion. Produced by the drop-file parser or the
/// envelope builder (Unix socket path) and consumed by the daemon's ingestion
/// handler. Sendable: the dicts are constructed once
/// and never mutated thereafter, so it's safe to send across task boundaries.
public struct ParsedEvent: @unchecked Sendable {
    public let eventType: String
    public let timestamp: String
    public let hookData: [String: Any]
    public let context: [String: Any]?
    public let accountEmail: String

    /// The oauth login that was current **when the hook fired**, for the events
    /// whose `accountEmail` is empty because no token could be fingerprinted.
    ///
    /// Resolved at capture and carried, rather than looked up at write time,
    /// because write time may be much later: an event sits in the spool for as
    /// long as the migration that parked the daemon takes, and a drop file can
    /// survive a reboot. Resolving then attributes the whole backlog to whoever
    /// happens to be logged in at the drain — and because the sessions upsert is
    /// first-oauth-wins, that wrong attribution is the one that sticks.
    ///
    /// `nil` means "this envelope predates the field" (a drop file written by an
    /// older build), which is the only case where resolving at write time is
    /// still the best available answer. Empty means "resolved, and there was no
    /// oauth login" — a real answer, not a missing one.
    public let oauthAccountEmail: String?

    public init(
        eventType: String,
        timestamp: String,
        hookData: [String: Any],
        context: [String: Any]?,
        accountEmail: String,
        oauthAccountEmail: String? = nil
    ) {
        self.eventType = eventType
        self.timestamp = timestamp
        self.hookData = hookData
        self.context = context
        self.accountEmail = accountEmail
        self.oauthAccountEmail = oauthAccountEmail
    }
}
