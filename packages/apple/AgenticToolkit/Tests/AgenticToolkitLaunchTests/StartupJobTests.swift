import Testing
@testable import AgenticToolkitLaunch

struct NoopRunner: PrivilegedRunner {
    @MainActor func run(_ argv: [String]) async throws {}
}

struct PlainJob: StartupJob {
    let id = "plain"
    let title = "Plain"
    @MainActor func run(context: StartupJobContext) async throws {}
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
}
