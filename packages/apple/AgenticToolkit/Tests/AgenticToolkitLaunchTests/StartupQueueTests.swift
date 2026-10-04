import Testing
@testable import AgenticToolkitLaunch

@MainActor final class Log { var entries: [String] = [] }
struct Boom: Error {}

struct RecordingJob: StartupJob {
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
    let context = StartupJobContext(privileged: NoopRunner(), progress: { _ in })

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
            RecordingJob(id: "a", log: log),
            RecordingJob(id: "b", fails: true, log: log),
            RecordingJob(id: "c", log: log)
        ])
        let failures = await queue.run(context: context) { _ in }
        #expect(failures.map(\.job.id) == ["b"])
        #expect(log.entries == ["a", "b", "c"], "a failure does not stop the queue")

        log.entries = []
        let retry = StartupQueue(jobs: failures.map(\.job))
        _ = await retry.run(context: context) { _ in }
        #expect(log.entries == ["b"])
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
