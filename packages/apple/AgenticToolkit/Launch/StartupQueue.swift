import Foundation

public struct StartupFailure: Sendable {
    public let job: any StartupJob
    public let error: any Error

    public init(job: any StartupJob, error: any Error) {
        self.job = job
        self.error = error
    }
}

/// FIFO runner for startup jobs. Order is the order given, except that `.last`
/// jobs move (stably) to the end; a repeated id keeps its first occurrence. A
/// failing job never stops the queue — failures are returned together so the
/// presenter can offer one Retry for all of them.
@MainActor
public final class StartupQueue {
    public private(set) var jobs: [any StartupJob]

    public init(jobs: [any StartupJob]) {
        var seen = Set<String>()
        let unique = jobs.filter { seen.insert($0.id).inserted }
        // Stable partition: Swift's sort is not guaranteed stable, so split.
        self.jobs = unique.filter { $0.order == .normal } + unique.filter { $0.order == .last }
    }

    public var needsAdministrator: Bool { jobs.contains { $0.needsAdministrator } }

    public func run(context: StartupJobContext,
                    willRun: (any StartupJob) -> Void) async -> [StartupFailure] {
        var failures: [StartupFailure] = []
        for job in jobs {
            willRun(job)
            do { try await job.run(context: context) } catch {
                failures.append(StartupFailure(job: job, error: error))
            }
        }
        return failures
    }
}
