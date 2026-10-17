import Foundation

/// Lifecycle state of a Claude Code session.
public enum SessionStatus: String, Sendable {
    case active
    case stale
    case ended
}
