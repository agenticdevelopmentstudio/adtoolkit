// AgenticToolkitCore is macOS-only, so this is too (review F29).
#if os(macOS)
import Foundation
import AgenticToolkitCore

/// Where work-tracking writes. The host implements it over its own database.
/// Every timestamp is ISO-8601 UTC (`UTCTimestamp`).
public protocol ActivityPersistence: AnyObject, Sendable {
    func openActivitySpan(_ span: ActivitySpanDTO) throws
    /// Ends the span if it is still open; a closed span keeps its first end.
    /// A span shorter than one second is deleted instead. Opening an id that
    /// already exists throws.
    func closeActivitySpan(id: String, endedAt: String) throws
    func retitleActivitySpan(id: String, title: String) throws
    /// Heartbeat: the span was still current at `at`.
    func touchActivitySpan(id: String, at: String) throws
    /// Opens an idle interval unless one is already open.
    func openIdleInterval(from: String) throws
    /// Closes the open idle interval, if any.
    func closeIdleInterval(until: String) throws
    /// After a restart: every open span closed per `ActivityRecovery`, every
    /// open idle interval closed at `now`. Returns the spans that survived
    /// closing — one deleted for being under a second is not counted.
    @discardableResult func recoverActivity(now: String) throws -> Int
    /// Deletes derived spans that ended before `before`, and idle intervals
    /// that ended before it. What "derived" means is the host's. Returns rows deleted.
    @discardableResult func pruneActivity(endedBefore before: String) throws -> Int
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO]   // newest first
    func openActivitySpans() throws -> [ActivitySpanDTO]
}

/// What closing one span did.
public enum ActivitySpanClose: Sendable, Equatable {
    /// No open span had that id.
    case none
    /// The span ended.
    case closed
    /// The span was under a second long and is gone.
    case deleted
}

public enum ActivityRecovery {
    /// Where a span left open by a crash ends: its last heartbeat (or its
    /// start without one), pulled back to the start of an idle interval that
    /// opened after that heartbeat and is still open. Never later than the
    /// heartbeat — downtime is never billed.
    public static func recoveredEnd(startedAt: String, lastSeenAt: String, openIdleFrom: [String]) -> String {
        let start = UTCTimestamp.canonical(startedAt) ?? startedAt
        let seen = lastSeenAt.isEmpty ? "" : (UTCTimestamp.canonical(lastSeenAt) ?? lastSeenAt)
        let base = seen.isEmpty ? start : seen
        let idle = openIdleFrom
            .map { UTCTimestamp.canonical($0) ?? $0 }
            .filter { $0 >= start && $0 <= base }
            .min()
        return idle ?? base
    }
}
#endif
