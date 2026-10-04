import Testing
@testable import AgenticToolkitLaunch

private struct QueueNoopRunner: PrivilegedRunner {
    @MainActor func run(_ argv: [String]) async throws {}
}

@MainActor private final class Log { var entries: [String] = [] }
private struct Boom: Error {}

private struct RecordingJob: StartupJob {
    let id: String
    var order: StartupJobOrder = .normal
    var needsAdministrator = false
    var fails = false
    let log: Log
    var title: String { id }
    @MainActor func run(context: StartupJobContext) async throws {
        log.entries.append(id)
        if fails { throw Boom() }
    }
}

@MainActor @Suite struct StartupQueueTests {
    let context = StartupJobContext(privileged: QueueNoopRunner(), progress: { _ in })

    @Test func runsFifoWithLastAtEnd() async {
        let log = Log()
        let queue = StartupQueue(jobs: [
            RecordingJob(id: "walk", order: .last, log: log),
            RecordingJob(id: "a", log: log),
            RecordingJob(id: "b", log: log)
        ])
        _ = await queue.run(context: context) { _ in }
        #expect(log.entries == ["a", "b", "walk"])
    }

    @Test func dedupesKeepingFirst() {
        let log = Log()
        let queue = StartupQueue(jobs: [
            RecordingJob(id: "a", log: log), RecordingJob(id: "a", order: .last, log: log)
        ])
        #expect(queue.jobs.map(\.id) == ["a"])
        #expect(queue.jobs.first?.order == .normal)
    }

    @Test func failuresCollectedAndRetryRunsOnlyFailed() async {
        let log = Log()
        let queue = StartupQueue(jobs: [
            RecordingJob(id: "a", fails: true, log: log),
            RecordingJob(id: "b", log: log),
            RecordingJob(id: "c", fails: true, log: log)
        ])
        let failures = await queue.run(context: context) { _ in }
        #expect(failures.map(\.job.id) == ["a", "c"], "failures come back in run order")
        #expect(log.entries == ["a", "b", "c"], "a failure does not stop the queue")

        log.entries = []
        let retry = StartupQueue(jobs: failures.map(\.job))
        _ = await retry.run(context: context) { _ in }
        #expect(log.entries == ["a", "c"])
    }

    @Test func lastJobsKeepRelativeOrder() async {
        let log = Log()
        let queue = StartupQueue(jobs: [
            RecordingJob(id: "last1", order: .last, log: log),
            RecordingJob(id: "a", log: log),
            RecordingJob(id: "last2", order: .last, log: log),
            RecordingJob(id: "b", log: log)
        ])
        _ = await queue.run(context: context) { _ in }
        #expect(log.entries == ["a", "b", "last1", "last2"])
    }

    @Test func reportsAdministratorNeed() {
        let log = Log()
        #expect(StartupQueue(jobs: [RecordingJob(id: "a", log: log)]).needsAdministrator == false)
        #expect(StartupQueue(jobs: [RecordingJob(id: "a", needsAdministrator: true, log: log)]).needsAdministrator)
    }

    @Test func willRunCalledInOrder() async {
        let log = Log()
        var seen: [String] = []
        let queue = StartupQueue(jobs: [RecordingJob(id: "a", log: log), RecordingJob(id: "b", log: log)])
        _ = await queue.run(context: context) { seen.append($0.id) }
        #expect(seen == ["a", "b"])
    }
}
