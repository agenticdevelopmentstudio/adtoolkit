#if canImport(AgenticToolkitCore)
import Foundation

/// A read-only snapshot of one live session, assembled once per oversight tick from
/// `sessions` ⋈ `session_metrics`. Observers reason over an array of these rather than
/// re-querying per session, so the whole fleet is examined from a single consistent read.
public struct LiveSessionSnapshot: Sendable, Equatable {
    public let sessionId: String
    public let cwd: String
    public let status: String
    public let model: String
    public let gitBranch: String
    public let lastActivityAt: String
    /// Percentage of the context window in use (0…100), from the status-line feed.
    /// 0 when the session has never reported a status-line payload.
    public let contextUsedPct: Int
    /// Total context-window size in tokens, or 0 when unknown.
    public let contextWindowSize: Int
    /// The terminal pane identifier (`TERM_SESSION_ID`), for a future actor to target.
    public let termSessionId: String

    public init(
        sessionId: String,
        cwd: String,
        status: String,
        model: String,
        gitBranch: String,
        lastActivityAt: String,
        contextUsedPct: Int,
        contextWindowSize: Int,
        termSessionId: String
    ) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.status = status
        self.model = model
        self.gitBranch = gitBranch
        self.lastActivityAt = lastActivityAt
        self.contextUsedPct = contextUsedPct
        self.contextWindowSize = contextWindowSize
        self.termSessionId = termSessionId
    }
}

/// The lifecycle of a finding. A finding is `pending` while its condition holds and no
/// one has handled it; `acted`/`dismissed` once a human (or, later, an autonomous actor)
/// resolves it; `stale` once the condition itself no longer holds. A recurrence of a
/// `stale` finding re-pends it; `acted`/`dismissed` are preserved across re-detection.
public enum FindingStatus: String, Sendable, CaseIterable {
    case pending
    case acted
    case dismissed
    case stale
}

/// Where a finding's judgement came from: a deterministic rule, or the local model.
public enum FindingSource: String, Sendable {
    case rule
    case llm
}

/// One observation an observer wants recorded about a session — the write-side unit.
/// Keyed by (sessionId, observer, kind): an observer re-detecting the same condition on
/// the same session refreshes the existing row rather than piling up duplicates.
public struct SessionFinding: Sendable, Equatable {
    public let sessionId: String
    /// The observer that produced this (e.g. `"context"`). Namespaces the finding.
    public let observer: String
    /// The actionable category an actor can dispatch on (e.g. `"compact"`).
    public let kind: String
    /// A coarse 0…100 urgency (context observer uses context-used-%). Ordering hint only.
    public let severity: Int
    public let source: FindingSource
    /// The model that produced an `llm`-sourced finding; empty for `rule`.
    public let model: String
    /// One human-readable line explaining the finding.
    public let reason: String
    /// Optional JSON blob of extra structured context (empty string when none).
    public let detail: String

    public init(
        sessionId: String,
        observer: String,
        kind: String,
        severity: Int,
        source: FindingSource,
        model: String = "",
        reason: String,
        detail: String = ""
    ) {
        self.sessionId = sessionId
        self.observer = observer
        self.kind = kind
        self.severity = severity
        self.source = source
        self.model = model
        self.reason = reason
        self.detail = detail
    }
}

// The read model for a persisted finding — `OversightFindingDTO` — lives in Core so a
// daemon and its app decode the identical shape.
#endif
