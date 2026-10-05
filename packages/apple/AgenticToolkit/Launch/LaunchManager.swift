import Foundation

@MainActor
public protocol LaunchPresenter: AnyObject {
    /// The queue is about to run. `needsAdministrator` lets the panel say a
    /// password may be asked for before the prompt appears.
    func begin(needsAdministrator: Bool)
    /// Returns once the presenter is on screen and ready for jobs. The first
    /// job waits for it: a job that blocks the main thread in a nested run loop
    /// (NSAppleScript, while its password prompt is up) must never be where a
    /// modal presenter enters its session, or neither can return.
    func waitUntilPresented() async
    func willRun(_ job: any StartupJob)
    /// The queue is done (after any retries); dismiss.
    func finish()
    /// Some jobs failed; return true to retry exactly those.
    func reportFailures(_ failures: [StartupFailure]) async -> Bool
}

public extension LaunchPresenter {
    /// A presenter with no session of its own is ready as soon as it begins.
    func waitUntilPresented() async {}
}

public struct LaunchReport: Sendable {
    public let ran: [String]
    public let failed: [String]
    public let firstRunShown: Bool
}

public struct JobsOutcome: Sendable {
    public let ran: [String]
    public let failed: [String]
}

/// Takes control of the app at launch while the user waits:
/// preparation (concurrent assessments) → first run (once per user) →
/// startup (one FIFO queue behind an undismissable progress panel).
@MainActor
public final class LaunchManager {
    public static let firstRunCompleteKey = "launch_manager_first_run_complete"

    public var firstRunExperience: (any FirstRunExperience)?
    /// Receives each running job's progress detail line.
    public var progressSink: (@MainActor @Sendable (String) -> Void)?
    private var preparationJobs: [any PreparationJob] = []
    private var startupJobs: [any StartupJob] = []
    private let defaults: UserDefaults
    private let privileged: any PrivilegedRunner
    private let presenter: (any LaunchPresenter)?

    public init(defaults: UserDefaults = .standard,
                privileged: any PrivilegedRunner,
                presenter: (any LaunchPresenter)?) {
        self.defaults = defaults
        self.privileged = privileged
        self.presenter = presenter
    }

    public var preparationJobNames: [String] {
        preparationJobs.map { String(describing: type(of: $0)) }
    }

    public func addPreparationJob(_ job: any PreparationJob) { preparationJobs.append(job) }
    public func addStartupJob(_ job: any StartupJob) { startupJobs.append(job) }

    public func run() async -> LaunchReport {
        var queued = startupJobs
        queued += await assessAll()

        var firstRunShown = false
        if let experience = firstRunExperience, !defaults.bool(forKey: Self.firstRunCompleteKey) {
            firstRunShown = true
            queued += await experience.start()
            defaults.set(true, forKey: Self.firstRunCompleteKey)
        }

        let outcome = await Self.runJobs(queued, privileged: privileged, presenter: presenter) { [weak self] in
            self?.progressSink?($0)
        }
        return LaunchReport(ran: outcome.ran, failed: outcome.failed, firstRunShown: firstRunShown)
    }

    /// The one queue + retry loop; launch and any later "run these now" flow
    /// share it. Empty input makes no presenter calls. Cancellation stops
    /// further retries but still calls `finish()`.
    public static func runJobs(_ jobs: [any StartupJob],
                               privileged: any PrivilegedRunner,
                               presenter: (any LaunchPresenter)?,
                               progress: @escaping @MainActor @Sendable (String) -> Void) async -> JobsOutcome {
        let queue = StartupQueue(jobs: jobs)
        guard !queue.jobs.isEmpty else { return JobsOutcome(ran: [], failed: []) }

        presenter?.begin(needsAdministrator: queue.needsAdministrator)
        await presenter?.waitUntilPresented()
        let context = StartupJobContext(privileged: privileged, progress: progress)
        var failures = await queue.run(context: context) { presenter?.willRun($0) }
        while !failures.isEmpty, !Task.isCancelled, let presenter {
            guard await presenter.reportFailures(failures), !Task.isCancelled else { break }
            failures = await StartupQueue(jobs: failures.map(\.job))
                .run(context: context) { presenter.willRun($0) }
        }
        presenter?.finish()
        return JobsOutcome(ran: queue.jobs.map(\.id), failed: failures.map(\.job.id))
    }

    /// Every assessment at once; results kept in REGISTRATION order, so a slow
    /// first assessment still queues first.
    private func assessAll() async -> [any StartupJob] {
        let jobs = preparationJobs
        return await withTaskGroup(of: (Int, [any StartupJob]).self) { group in
            for (index, job) in jobs.enumerated() {
                group.addTask { (index, await job.assess()) }
            }
            var results = [[any StartupJob]](repeating: [], count: jobs.count)
            for await (index, found) in group { results[index] = found }
            return results.flatMap { $0 }
        }
    }
}
