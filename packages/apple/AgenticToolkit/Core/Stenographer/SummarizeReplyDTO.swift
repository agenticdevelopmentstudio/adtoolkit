import Foundation

/// Reply payload for `summarizeSession` — `{session_id, summary}` on success,
/// `{session_id, error}` on failure — so the app's manual Summarize can show the
/// daemon's reason (e.g. the local-model memory guard's refusal) instead of a
/// generic failure, matching the HTTP twin's `error.localizedDescription`. A nil
/// XPC reply remains "transport/encoding failed".
public struct SummarizeReplyDTO: Codable, Sendable, Equatable {
    public let sessionId: String
    /// The stored summary (nil on failure).
    public let summary: String?
    /// The failure description (nil on success).
    public let error: String?

    public init(sessionId: String, summary: String? = nil, error: String? = nil) {
        self.sessionId = sessionId
        self.summary = summary
        self.error = error
    }
}
