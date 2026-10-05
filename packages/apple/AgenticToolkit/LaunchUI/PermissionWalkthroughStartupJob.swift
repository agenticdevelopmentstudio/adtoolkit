import AgenticToolkitLaunch
import AgenticToolkitPermissionsUI

/// The permissions walkthrough as a startup job. `.last`, so it never shares
/// the screen with a password prompt from an earlier job.
public struct PermissionWalkthroughStartupJob: StartupJob {
    public let id = "permissions-walkthrough"
    public let title = "Reviewing permissions"
    public let order: StartupJobOrder = .last
    private let make: @MainActor @Sendable () -> PermissionWalkthrough

    public init(walkthrough: @escaping @MainActor @Sendable () -> PermissionWalkthrough) { make = walkthrough }

    @MainActor public func run(context: StartupJobContext) async throws {
        let walkthrough = make()
        // The walkthrough's Done button holds its target weakly: keep it alive
        // until it reports done, or an optimized build can free it mid-window.
        await withCheckedContinuation { cont in walkthrough.runIfNeeded { cont.resume() } }
        withExtendedLifetime(walkthrough) {}
    }
}

/// Queues the walkthrough job only while the walkthrough is incomplete.
public struct PermissionWalkthroughPreparation: PreparationJob {
    private let isComplete: @Sendable () -> Bool
    private let make: @MainActor @Sendable () -> PermissionWalkthrough

    public init(isComplete: @escaping @Sendable () -> Bool,
                walkthrough: @escaping @MainActor @Sendable () -> PermissionWalkthrough) {
        self.isComplete = isComplete
        self.make = walkthrough
    }

    public func assess() async -> [any StartupJob] {
        isComplete() ? [] : [PermissionWalkthroughStartupJob(walkthrough: make)]
    }
}
