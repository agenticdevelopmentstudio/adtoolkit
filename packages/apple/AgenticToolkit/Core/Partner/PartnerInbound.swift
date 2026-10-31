import Foundation

/// Everything that can start a partner turn.
public enum PartnerInbound: Sendable, Equatable {
    case owner(text: String, attribution: ChatMessage.Attribution?)
    case tick(jobID: String, jobName: String, previousTick: Date?, summary: String?)
    case sessionIdle(sessionID: String, title: String)
    case sessionExited(sessionID: String, title: String)
    case lifecycle(Lifecycle)

    public enum Lifecycle: Sendable, Equatable {
        case started(resumed: Bool, goneSessions: [String])
        case guidelinesChanged
        case willQuit(endingSessions: [String])
        case turnTimedOut
    }

    /// What the partner reads.
    public var text: String {
        switch self {
        case .owner(let text, _):
            return text
        case .tick(_, let jobName, let previousTick, let summary):
            var lines = ["Timer tick for job \(jobName)."]
            if let previousTick {
                lines.append("Previous tick: \(previousTick.formatted(.iso8601))")
            }
            if let summary { lines.append(summary) }
            return lines.joined(separator: "\n")
        case .sessionIdle(let sessionID, let title):
            return "Session \(sessionID) (\(title)) went idle."
        case .sessionExited(let sessionID, let title):
            return "Session \(sessionID) (\(title)) exited."
        case .lifecycle(let lifecycle):
            switch lifecycle {
            case .started(let resumed, let gone):
                let list = gone.isEmpty ? "none" : gone.joined(separator: ", ")
                return "You were started (resumed: \(resumed)). Sessions gone since last time: \(list)"
            case .guidelinesChanged:
                return "Your guidelines changed and were applied at this restart."
            case .willQuit(let ending):
                let list = ending.isEmpty ? "none" : ending.joined(separator: ", ")
                return "The app is about to quit. These sessions will end: \(list)"
            case .turnTimedOut:
                return "Your previous turn was terminated after the turn timeout and the session resumed."
            }
        }
    }

    /// Entries with the same non-nil key collapse into one. Owner and lifecycle never do.
    public var coalescingKey: String? {
        switch self {
        case .tick(let jobID, _, _, _): return "tick:\(jobID)"
        case .sessionIdle(let sessionID, _): return "idle:\(sessionID)"
        case .sessionExited(let sessionID, _): return "exit:\(sessionID)"
        case .owner, .lifecycle: return nil
        }
    }

    public var attribution: ChatMessage.Attribution? {
        if case .owner(_, let attribution) = self { return attribution }
        return nil
    }
}
