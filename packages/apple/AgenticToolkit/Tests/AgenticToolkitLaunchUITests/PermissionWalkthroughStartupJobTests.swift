import AppKit
import Testing
import AgenticToolkitLaunch
import AgenticToolkitPermissionsUI
@testable import AgenticToolkitLaunchUI

@MainActor
private final class PanelSession: ModalSession {
    func enter(_ window: NSWindow) {}
    func leave() {}
}

private struct FakeJob: StartupJob {
    let id = "fake"
    let title = "Fake"
    let order: StartupJobOrder
    @MainActor func run(context: StartupJobContext) async throws {}
}

/// Compiles only while `isComplete` is readable off the main actor.
private func readCompleteOffMainActor() -> @Sendable () -> Bool {
    { PermissionWalkthrough.isComplete }
}

@MainActor @Suite struct PermissionWalkthroughStartupJobTests {
    @Test func isLastWithStableId() {
        let job = PermissionWalkthroughStartupJob { PermissionWalkthrough(permissions: []) }
        #expect(job.order == .last)
        #expect(job.id == "permissions-walkthrough")
    }

    @Test func preparationQueuesOnlyWhenIncomplete() async {
        let make: @MainActor @Sendable () -> PermissionWalkthrough = { PermissionWalkthrough(permissions: []) }
        #expect(await PermissionWalkthroughPreparation(isComplete: { true }, walkthrough: make).assess().isEmpty)
        #expect(await PermissionWalkthroughPreparation(isComplete: { false }, walkthrough: make).assess().map(\.id)
            == ["permissions-walkthrough"])
    }

    @Test func isCompleteIsReadableFromANonisolatedClosure() {
        // Asserts nothing about the value; the point is that it compiles.
        _ = readCompleteOffMainActor()()
    }

    @Test func lastJobOrdersTheProgressPanelOut() throws {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: PanelSession())
        presenter.begin(needsAdministrator: false)
        presenter.willRun(FakeJob(order: .last))
        let panel = try #require(presenter.panel)
        #expect(!panel.isVisible)
        presenter.finish()
    }

    @Test func failuresAfterALastJobUseTheStandaloneAlert() async throws {
        var alertShown = false
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: PanelSession()) { _ in
            alertShown = true
            return .alertFirstButtonReturn
        }
        presenter.begin(needsAdministrator: false)
        presenter.willRun(FakeJob(order: .last))
        let failures = [StartupFailure(job: FakeJob(order: .normal), error: CancellationError())]
        var result: Bool?
        let task = Task { @MainActor in result = await presenter.reportFailures(failures) }
        for _ in 0..<10_000 where result == nil { await Task.yield() }
        try #require(result != nil, "reportFailures never answered")
        task.cancel()
        #expect(result == true)
        #expect(alertShown)
        presenter.finish()
    }

    @Test func normalJobLeavesTheProgressPanelVisible() throws {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: PanelSession())
        presenter.begin(needsAdministrator: false)
        presenter.willRun(FakeJob(order: .normal))
        let panel = try #require(presenter.panel)
        #expect(panel.isVisible)
        presenter.finish()
    }
}
