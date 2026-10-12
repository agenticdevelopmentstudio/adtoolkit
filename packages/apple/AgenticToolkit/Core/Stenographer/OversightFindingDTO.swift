import Foundation

/// One persisted oversight finding — an observation the AI-oversight subsystem
/// recorded about a live session (e.g. "context 88% used → compact"). Surfaced to
/// the app (XPC) and CLI (HTTP `GET /oversight/findings`). Read-only: the daemon
/// writes these from its observers; clients display them.
///
/// Lives in the shared XPC package (not the daemon) so both the daemon's
/// `DatabaseManager` and the app decode the identical shape.
public struct OversightFindingDTO: Codable, Sendable, Equatable {
    public let id: Int
    /// The session this finding is about.
    public let sessionId: String
    /// The observer that produced it (e.g. `"context"`); namespaces the finding.
    public let observer: String
    /// The actionable category an actor can dispatch on (e.g. `"compact"`).
    public let kind: String
    /// Coarse 0…100 urgency (ContextObserver uses context-used-%). Ordering hint.
    public let severity: Int
    /// Lifecycle: `pending` | `acted` | `dismissed` | `stale`.
    public let status: String
    /// Where the judgement came from: `rule` or `llm`.
    public let source: String
    /// The model behind an `llm`-sourced finding; empty for `rule`.
    public let model: String
    /// One human-readable line explaining the finding.
    public let reason: String
    /// Optional JSON blob of extra structured context (empty when none).
    public let detail: String
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: Int,
        sessionId: String,
        observer: String,
        kind: String,
        severity: Int,
        status: String,
        source: String,
        model: String,
        reason: String,
        detail: String,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.sessionId = sessionId
        self.observer = observer
        self.kind = kind
        self.severity = severity
        self.status = status
        self.source = source
        self.model = model
        self.reason = reason
        self.detail = detail
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
