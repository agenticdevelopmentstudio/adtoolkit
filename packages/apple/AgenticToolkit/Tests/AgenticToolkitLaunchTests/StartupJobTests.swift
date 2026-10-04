import Testing
@testable import AgenticToolkitLaunch

private struct NoopRunner: PrivilegedRunner {
    @MainActor func run(_ argv: [String]) async throws {}
}

private struct PlainJob: StartupJob {
    let id = "plain"
    let title = "Plain"
    @MainActor func run(context: StartupJobContext) async throws {}
}

private struct LateAdminJob: StartupJob {
    let id = "late-admin"
    let title = "Late admin"
    let needsAdministrator = true
    let order = StartupJobOrder.last
    @MainActor func run(context: StartupJobContext) async throws {}
}

/// Main-actor isolated, so it is Sendable without an unchecked escape hatch.
@MainActor private final class Sink {
    var details: [String] = []
    var ranPrivileged = false
}

private struct ReportingJob: StartupJob {
    let id = "reporting"
    let title = "Reporting"
    let sink: Sink
    @MainActor func run(context: StartupJobContext) async throws {
        context.progress("working")
        try await context.privileged.run(["/usr/bin/true"])
        sink.ranPrivileged = true
    }
}

@Suite struct StartupJobTests {
    @Test func defaultsAreNormalAndUnprivileged() {
        let job = PlainJob()
        #expect(job.order == .normal)
        #expect(job.needsAdministrator == false)
    }

    @Test func lastSortsAfterNormal() {
        #expect(StartupJobOrder.normal < StartupJobOrder.last)
    }

    @Test func overridesTakeEffect() {
        let job = LateAdminJob()
        #expect(job.order == .last)
        #expect(job.needsAdministrator)
    }

    @Test func sortingByOrderPutsLastAfterNormal() {
        let jobs: [any StartupJob] = [LateAdminJob(), PlainJob()]
        let sorted = jobs.sorted { $0.order < $1.order }
        #expect(sorted.map(\.id) == ["plain", "late-admin"])
    }

    @MainActor @Test func jobSeesTheContextItRunsWith() async throws {
        let sink = Sink()
        let context = StartupJobContext(privileged: NoopRunner(),
                                        progress: { sink.details.append($0) })
        try await ReportingJob(sink: sink).run(context: context)
        #expect(sink.details == ["working"])
        #expect(sink.ranPrivileged)
    }
}
