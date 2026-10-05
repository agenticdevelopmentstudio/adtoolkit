import Foundation

/// The work-tracking half of a daemon's XPC surface, as its own protocol so
/// any app can talk to it without linking the daemon's whole protocol. Every
/// body and reply is JSON in the daemon's snake-case style.
@objc public protocol WorkTrackingXPCProtocol {
    /// Body = encoded `WorkTrackingPreferences`. Replies the encoded
    /// `WorkTrackingStatus` after applying; empty Data when it did not apply.
    func workTrackingSetPreferences(_ body: Data, reply: @escaping (Data) -> Void)
    /// Encoded `WorkTrackingStatus`; empty Data on failure.
    func workTrackingStatus(reply: @escaping (Data) -> Void)
    /// Re-checks Accessibility (the one explicit, user-driven check) and
    /// replies the new status.
    func workTrackingRecheckPermissions(reply: @escaping (Data) -> Void)
    /// Newest first; one encoded `ActivitySpanDTO` each. `since` nil = any.
    /// A read that failed replies the one element `WorkTrackingWire.readFailedRow`,
    /// so a failure never reads as "no activity".
    func workTrackingSpans(since: String?, limit: Int, reply: @escaping ([Data]) -> Void)
}
