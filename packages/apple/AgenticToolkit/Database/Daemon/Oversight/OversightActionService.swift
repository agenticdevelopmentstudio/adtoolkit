#if canImport(AgenticToolkitCore)
import Foundation

/// The write-back half of oversight, daemon-side: decide whether a finding can be acted on
/// *now* (the safety gate) and record that it was. Kept separate from the app's terminal
/// injection — the daemon owns session state and the audit record; the app owns the
/// Automation grant that actually types into a pane. Phase 3 (human-approved) and Phase 4
/// (autonomous) both funnel through `target` so the safety rule has a single home.
public enum OversightActionService {

    /// The event type that marks a safe breakpoint: Claude finished its response and is
    /// waiting for the user. Injecting text at any other point would interleave with
    /// work in flight. (See `DaemonDatabase.lastEventType`.)
    public static let idleEventType = "Stop"

    /// Resolve what acting on `findingId` would entail right now. The action comes from
    /// the finding's script (`observer` == script id → `response.action`); a `.none`
    /// action, a missing script (e.g. deleted, or a legacy pre-scripts finding), or any
    /// failed safety gate yields a `blocked` target carrying the reason, so HTTP and
    /// XPC report the identical shape.
    public static func target(findingId: Int, database: DaemonDatabase) -> OversightActionTargetDTO {
        guard let finding = try? database.fetchOversightFinding(id: findingId) else {
            return .blocked(findingId: findingId, reason: "Finding no longer exists.")
        }
        guard let script = ScriptStore.script(id: finding.observer, database: database) else {
            return .blocked(
                findingId: findingId,
                reason: "The script that recorded this finding no longer exists."
            )
        }
        guard case .injectText(let injectText) = script.response.action, !injectText.isEmpty else {
            return .blocked(findingId: findingId, reason: "This script records findings without an action.")
        }
        guard finding.status == "pending" else {
            return .blocked(findingId: findingId, reason: "Finding is already \(finding.status).")
        }
        guard let session = try? database.fetchSession(sessionId: finding.sessionId, includeEventCount: false) else {
            return .blocked(findingId: findingId, reason: "The session for this finding no longer exists.")
        }
        guard session.status == "active" else {
            return .blocked(findingId: findingId, reason: "Session is \(session.status), not live.")
        }
        let lastEvent = (try? database.lastEventType(sessionId: finding.sessionId)) ?? ""
        guard lastEvent == idleEventType else {
            let phase = lastEvent.isEmpty ? "hasn't recorded any activity yet" : "is mid-response (\(lastEvent))"
            return .blocked(
                findingId: findingId,
                reason: "Session \(phase) — wait until it's idle, then act."
            )
        }
        return OversightActionTargetDTO(
            findingId: findingId,
            actionable: true,
            reason: "",
            sessionId: session.sessionId,
            termProgram: session.termProgram,
            termSessionId: session.termSessionId,
            pid: session.pid,
            injectText: injectText
        )
    }

    /// The result of recording an act — a host maps this to transport status codes and an
    /// XPC reply to an `OversightActResultDTO`.
    public enum ActOutcome: Sendable {
        case acted(OversightFindingDTO)
        case notFound
        case notPending(currentStatus: String)
        case failed(String)
    }

    /// Record that `findingId` was acted on (mark it `acted`). The caller (app) performs
    /// the injection first and only records on success, so this is a bookkeeping write —
    /// but it re-validates against the current row so a stale/duplicate call can't resurrect
    /// or overwrite a resolved finding.
    public static func act(findingId: Int, database: DaemonDatabase) -> ActOutcome {
        guard let finding = try? database.fetchOversightFinding(id: findingId) else {
            return .notFound
        }
        guard finding.status == "pending" else {
            return .notPending(currentStatus: finding.status)
        }
        do {
            try database.markOversightFindingActed(id: findingId)
        } catch {
            return .failed(error.localizedDescription)
        }
        guard let updated = try? database.fetchOversightFinding(id: findingId) else {
            return .failed("Could not re-read the finding after acting.")
        }
        return .acted(updated)
    }

    /// Serialize an `ActOutcome` for the XPC reply.
    public static func result(for outcome: ActOutcome, findingId: Int) -> OversightActResultDTO {
        switch outcome {
        case .acted(let finding):
            return OversightActResultDTO(findingId: finding.id, succeeded: true, status: finding.status, reason: "")
        case .notFound:
            return OversightActResultDTO(
                findingId: findingId, succeeded: false, status: "", reason: "Finding not found."
            )
        case .notPending(let status):
            return OversightActResultDTO(
                findingId: findingId, succeeded: false, status: status, reason: "Finding is already \(status)."
            )
        case .failed(let message):
            return OversightActResultDTO(findingId: findingId, succeeded: false, status: "", reason: message)
        }
    }
}
#endif
