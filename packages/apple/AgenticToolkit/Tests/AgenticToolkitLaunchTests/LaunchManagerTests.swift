import Foundation
import Testing
@testable import AgenticToolkitLaunch

private struct LMRunner: PrivilegedRunner {
    @MainActor func run(_ argv: [String]) async throws {}
}

@MainActor private final class LMLog { var entries: [String] = [] }
private struct LMBoom: Error {}

private struct LMJob: StartupJob {
    let id: String
    var needsAdministrator = false
    var fails = false
    let log: LMLog
    var title: String { id }
    @MainActor func run(context: StartupJobContext) async throws {
        log.entries.append(id)
        if fails { throw LMBoom() }
    }
}

private struct FixedPreparation: PreparationJob {
    let jobs: [any StartupJob]
    var delay: Duration = .zero
    func assess() async -> [any StartupJob] {
        try? await Task.sleep(for: delay)
        return jobs
    }
}

private struct OtherPreparation: PreparationJob {
    func assess() async -> [any StartupJob] { [] }
}

/// Releases everyone once `expected` assessments have started. Serial
/// assessment never reaches it, so a timeout releases all and flags it.
@MainActor private final class StartLatch {
    let expected: Int
    var arrived = 0
    var timedOut = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var timeout: Task<Void, Never>?
    init(expected: Int) { self.expected = expected }

    func arriveAndWait() async {
        arrived += 1
        // After a timeout nobody waits again, so a serial run fails, not hangs.
        if timedOut { return }
        if arrived == expected { release(); return }
        if arrived == 1 {
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, let self, !self.waiters.isEmpty else { return }
                self.timedOut = true
                self.release()
            }
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    private func release() {
        timeout?.cancel()
        let pending = waiters
        waiters = []
        pending.forEach { $0.resume() }
    }
}

private struct GatedPreparation: PreparationJob {
    let latch: StartLatch
    func assess() async -> [any StartupJob] {
        await latch.arriveAndWait()
        return []
    }
}

@MainActor private final class LMExperience: FirstRunExperience {
    var started = 0
    let jobs: [any StartupJob]
    init(jobs: [any StartupJob]) { self.jobs = jobs }
    func start() async -> [any StartupJob] { started += 1; return jobs }
}

@MainActor private final class LMPresenter: LaunchPresenter {
    var events: [String] = []
    var retryAnswers: [Bool] = []
    func begin(needsAdministrator: Bool) { events.append("begin(\(needsAdministrator))") }
    func willRun(_ job: any StartupJob) { events.append("run:\(job.id)") }
    func finish() { events.append("finish") }
    func reportFailures(_ failures: [StartupFailure]) async -> Bool {
        events.append("failures:\(failures.map(\.job.id).joined(separator: ","))")
        return retryAnswers.isEmpty ? false : retryAnswers.removeFirst()
    }
}

/// Holds `reportFailures` open until the test answers it.
@MainActor private final class PendingPresenter: LaunchPresenter {
    var events: [String] = []
    var pending: CheckedContinuation<Bool, Never>?
    private var calls = 0
    func begin(needsAdministrator: Bool) { events.append("begin") }
    func willRun(_ job: any StartupJob) { events.append("run:\(job.id)") }
    func finish() { events.append("finish") }
    func reportFailures(_ failures: [StartupFailure]) async -> Bool {
        calls += 1
        // Only the first call parks; a regressed retry then fails the test, not hangs it.
        guard calls == 1 else { return false }
        return await withCheckedContinuation { pending = $0 }
    }
}

@MainActor private final class Heard { var lines: [String] = [] }

private struct Talker: StartupJob {
    let id = "talk"
    let title = "Talk"
    @MainActor func run(context: StartupJobContext) async throws { context.progress("hello") }
}

@MainActor @Suite struct LaunchManagerTests {
    func defaults() -> UserDefaults {
        UserDefaults(suiteName: "lm-\(UUID().uuidString)")!
    }

    @Test func orderIsAppThenPreparationInRegistrationOrderThenFirstRun() async {
        let log = LMLog()
        let presenter = LMPresenter()
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: presenter)
        manager.addStartupJob(LMJob(id: "app", log: log))
        // The slow one is registered first; its jobs still come first.
        manager.addPreparationJob(FixedPreparation(jobs: [LMJob(id: "prep1", log: log)], delay: .milliseconds(50)))
        manager.addPreparationJob(FixedPreparation(jobs: [LMJob(id: "prep2", log: log)]))
        manager.firstRunExperience = LMExperience(jobs: [LMJob(id: "first", log: log)])

        let report = await manager.run()

        #expect(log.entries == ["app", "prep1", "prep2", "first"])
        #expect(report.firstRunShown)
        #expect(presenter.events.first == "begin(false)")
        #expect(presenter.events.last == "finish")
    }

    @Test func preparationRunsConcurrently() async {
        let latch = StartLatch(expected: 5)
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: nil)
        for _ in 0..<5 { manager.addPreparationJob(GatedPreparation(latch: latch)) }
        _ = await manager.run()
        #expect(!latch.timedOut, "all five assessments must be in flight at once")
        #expect(latch.arrived == 5)
    }

    @Test func firstRunShownOnceThenRemembered() async {
        let store = defaults()
        let experience = LMExperience(jobs: [])
        for _ in 0..<2 {
            let manager = LaunchManager(defaults: store, privileged: LMRunner(), presenter: nil)
            manager.firstRunExperience = experience
            _ = await manager.run()
        }
        #expect(experience.started == 1)
        #expect(store.bool(forKey: LaunchManager.firstRunCompleteKey))
    }

    @Test func noJobsMeansNoPresenter() async {
        let presenter = LMPresenter()
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: presenter)
        manager.addPreparationJob(FixedPreparation(jobs: []))
        _ = await manager.run()
        #expect(presenter.events.isEmpty)
    }

    @Test func retryRerunsOnlyFailedUntilDeclined() async {
        let log = LMLog()
        let presenter = LMPresenter()
        presenter.retryAnswers = [true, false]
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: presenter)
        manager.addStartupJob(LMJob(id: "ok", log: log))
        manager.addStartupJob(LMJob(id: "bad", fails: true, log: log))

        let report = await manager.run()

        #expect(log.entries == ["ok", "bad", "bad"])
        #expect(report.failed == ["bad"])
        #expect(presenter.events.filter { $0.hasPrefix("failures:") } == ["failures:bad", "failures:bad"])
    }

    @Test func administratorNeedReportedToPresenter() async {
        let log = LMLog()
        let presenter = LMPresenter()
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: presenter)
        manager.addStartupJob(LMJob(id: "root", needsAdministrator: true, log: log))
        _ = await manager.run()
        #expect(presenter.events.first == "begin(true)")
    }

    @Test func progressReachesSink() async {
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: nil)
        let heard = Heard()
        manager.progressSink = { heard.lines.append($0) }
        manager.addStartupJob(Talker())
        _ = await manager.run()
        #expect(heard.lines == ["hello"])
    }

    @Test func preparationJobNamesListRegisteredTypes() {
        let manager = LaunchManager(defaults: defaults(), privileged: LMRunner(), presenter: nil)
        manager.addPreparationJob(FixedPreparation(jobs: []))
        manager.addPreparationJob(OtherPreparation())
        #expect(manager.preparationJobNames == ["FixedPreparation", "OtherPreparation"])
    }

    @Test func runJobsRetriesOnlyFailedAndEmptyMakesNoCalls() async {
        let log = LMLog()
        let presenter = LMPresenter()
        presenter.retryAnswers = [true, false]
        let outcome = await LaunchManager.runJobs(
            [LMJob(id: "ok", log: log), LMJob(id: "bad", fails: true, log: log)],
            privileged: LMRunner(), presenter: presenter, progress: { _ in })
        #expect(log.entries == ["ok", "bad", "bad"])
        #expect(outcome.ran == ["ok", "bad"])
        #expect(outcome.failed == ["bad"])

        let quiet = LMPresenter()
        let empty = await LaunchManager.runJobs([], privileged: LMRunner(), presenter: quiet, progress: { _ in })
        #expect(empty.ran.isEmpty && empty.failed.isEmpty)
        #expect(quiet.events.isEmpty)
    }

    @Test func cancellationDuringFailureReportStopsRetry() async throws {
        let log = LMLog()
        let presenter = PendingPresenter()
        let task = Task { @MainActor in
            await LaunchManager.runJobs([LMJob(id: "bad", fails: true, log: log)],
                                        privileged: LMRunner(), presenter: presenter, progress: { _ in })
        }
        for _ in 0..<10_000 where presenter.pending == nil { await Task.yield() }
        try #require(presenter.pending != nil)
        task.cancel()
        presenter.pending?.resume(returning: true)
        let outcome = await task.value

        #expect(log.entries == ["bad"], "no retry after cancellation")
        #expect(outcome.failed == ["bad"])
        #expect(presenter.events.last == "finish")
    }
}
