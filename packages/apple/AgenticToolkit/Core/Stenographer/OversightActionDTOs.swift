import Foundation

/// What the app needs to act on a finding *right now*: whether the session is at a
/// safe breakpoint, and — when it is — the terminal target to inject into.
///
/// The daemon computes this because it is the single source of truth for session state
/// (liveness + the last event that decides idle-vs-mid-response). The **terminal**
/// capability (can we script iTerm2 / Terminal.app for this pane?) is decided app-side,
/// since only the app holds the Automation grant — so a client ANDs `actionable` with its
/// own injector's terminal support before enabling the control. Phase-4 autonomous action
/// gates on the identical `actionable` check, so the safety rule lives in exactly one place.
public struct OversightActionTargetDTO: Codable, Sendable, Equatable {
    public let findingId: Int
    /// The session is live and at a safe breakpoint (last event was `Stop` — Claude
    /// finished a response and is waiting for the user). False ⇒ do not act; see `reason`.
    public let actionable: Bool
    /// Why it isn't actionable (empty when `actionable` is true).
    public let reason: String
    public let sessionId: String
    /// The terminal app (e.g. `"iTerm.app"`, `"Apple_Terminal"`) — the client picks the
    /// injection strategy from this.
    public let termProgram: String
    /// The pane identifier (`TERM_SESSION_ID`) for exact iTerm2 targeting; may be empty.
    public let termSessionId: String
    /// The session's `claude` PID, from which the client can resolve the pane's TTY.
    public let pid: Int
    /// The text to inject (e.g. `"/compact"`).
    public let injectText: String

    public init(
        findingId: Int,
        actionable: Bool,
        reason: String,
        sessionId: String,
        termProgram: String,
        termSessionId: String,
        pid: Int,
        injectText: String
    ) {
        self.findingId = findingId
        self.actionable = actionable
        self.reason = reason
        self.sessionId = sessionId
        self.termProgram = termProgram
        self.termSessionId = termSessionId
        self.pid = pid
        self.injectText = injectText
    }

    /// A "can't act" target carrying only the reason — used when the finding is missing,
    /// resolved, or its session isn't at a safe breakpoint.
    public static func blocked(findingId: Int, reason: String) -> OversightActionTargetDTO {
        OversightActionTargetDTO(
            findingId: findingId, actionable: false, reason: reason,
            sessionId: "", termProgram: "", termSessionId: "", pid: 0, injectText: ""
        )
    }
}

/// The outcome of `POST /oversight/findings/:id/act` (and the XPC equivalent): whether the
/// finding was marked `acted`. The app calls this only *after* a successful injection, so a
/// failure here is a rare race (the finding was already resolved, or vanished).
public struct OversightActResultDTO: Codable, Sendable, Equatable {
    public let findingId: Int
    /// True when the finding transitioned to `acted`.
    public let succeeded: Bool
    /// The finding's status after the call (`"acted"` on success; the current status when
    /// it was already resolved; empty when the finding was not found).
    public let status: String
    /// Human-readable explanation when `succeeded` is false (empty on success).
    public let reason: String

    public init(findingId: Int, succeeded: Bool, status: String, reason: String) {
        self.findingId = findingId
        self.succeeded = succeeded
        self.status = status
        self.reason = reason
    }
}
