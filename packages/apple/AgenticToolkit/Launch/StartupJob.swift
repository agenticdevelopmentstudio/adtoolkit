import Foundation

/// Where a job sits in the startup queue. `.last` jobs run after every
/// `.normal` one, in queue order among themselves — the permissions walkthrough
/// is `.last` so it never interleaves with a password prompt.
public enum StartupJobOrder: Int, Sendable, Comparable {
    case normal, last
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Runs a command as root. One instance serves a whole queue, so a runner that
/// caches authorization prompts once (the AppleScript one reuses a single
/// compiled script, which is what macOS's authorization grace is tied to).
public protocol PrivilegedRunner: Sendable {
    @MainActor func run(_ argv: [String]) async throws
}

public struct StartupJobContext: Sendable {
    public let privileged: any PrivilegedRunner
    /// Replaces the progress panel's detail line ("Restarting the daemon…").
    public let progress: @MainActor @Sendable (String) -> Void

    public init(privileged: any PrivilegedRunner,
                progress: @escaping @MainActor @Sendable (String) -> Void) {
        self.privileged = privileged
        self.progress = progress
    }
}

/// One unit of startup work. It runs on the main actor, so it may drive UI
/// (the walkthrough does); slow work belongs in an `await` off the main actor.
public protocol StartupJob: Sendable {
    /// Stable identity: two jobs with the same id are the same job, and the
    /// queue keeps only the first.
    var id: String { get }
    /// Shown in the progress panel while it runs.
    var title: String { get }
    var needsAdministrator: Bool { get }
    var order: StartupJobOrder { get }
    @MainActor func run(context: StartupJobContext) async throws
}

public extension StartupJob {
    var needsAdministrator: Bool { false }
    var order: StartupJobOrder { .normal }
}
