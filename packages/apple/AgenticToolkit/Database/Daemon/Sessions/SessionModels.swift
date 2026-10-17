#if canImport(AgenticToolkitCore)
import Foundation

/// A lightweight, fully Sendable representation of an ingested event.
/// Created by `ingestEvent` after the event has been written to the DB.
/// Used for SSE broadcasts and the onEventIngested callback.
public struct IngestedEvent: Sendable, Codable {
    public let id: Int64           // event_log row id
    public let event: String       // event type string (matches HookEventType.rawValue)
    public let sessionId: String
    public let timestamp: String
    public let cwd: String
    public let detail: String      // precomputed display string for stream output
    public let toolName: String    // non-empty for PreToolUse / PostToolUse / PostToolUseFailure
    public let model: String       // non-empty for SessionStart
    public let source: String      // non-empty for SessionStart
}
#endif
