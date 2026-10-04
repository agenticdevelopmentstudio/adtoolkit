import AppKit
import Testing
import AgenticToolkitLaunch
@testable import AgenticToolkitLaunchUI

@MainActor
private final class RecordingSession: ModalSession {
    var entered = 0
    var left = 0
    /// Runs inside enter(), as events do inside a real modal loop.
    var onEnter: (@MainActor () -> Void)?
    func enter(_ window: NSWindow) {
        entered += 1
        onEnter?()
    }
    func leave() { left += 1 }
}

private struct NamedJob: StartupJob {
    let id: String
    let title: String
    @MainActor func run(context: StartupJobContext) async throws {}
}

private enum TestError: Error, LocalizedError {
    case boom
    var errorDescription: String? { "boom" }
}

@MainActor
private func drainMainRunLoop() async {
    await withCheckedContinuation { cont in
        RunLoop.main.perform(inModes: [.common]) { cont.resume() }
    }
}

@MainActor @Suite struct ModalProgressPanelTests {
    @Test func panelIsTitledOnlyAndNotClosable() throws {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: RecordingSession())
        presenter.begin(needsAdministrator: false)
        let panel = try #require(presenter.panel)
        #expect(panel.styleMask.contains(.titled))
        #expect(!panel.styleMask.contains(.closable))
        #expect(!panel.styleMask.contains(.resizable))
        presenter.finish()
    }

    @Test func showsJobTitleAndAdministratorNotice() {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: RecordingSession())
        presenter.begin(needsAdministrator: true)
        #expect(presenter.noticeText.contains("password"))
        presenter.willRun(NamedJob(id: "a", title: "Restarting the daemon"))
        #expect(presenter.detailText == "Restarting the daemon")
        presenter.finish()
    }

    @Test func escapeDoesNotDismiss() {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: RecordingSession())
        presenter.begin(needsAdministrator: false)
        presenter.panel?.cancelOperation(nil)
        #expect(presenter.isPresented)
        presenter.finish()
    }

    @Test func finishBeforePresentNeverEntersModal() async {
        let session = RecordingSession()
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: session)
        presenter.begin(needsAdministrator: false)
        presenter.finish()
        await drainMainRunLoop()
        #expect(session.entered == 0)
        #expect(!presenter.isPresented)
    }

    @Test func finishInsideModalLeavesIt() async {
        let session = RecordingSession()
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: session)
        session.onEnter = { presenter.finish() }
        presenter.begin(needsAdministrator: false)
        await drainMainRunLoop()
        #expect(session.entered == 1)
        #expect(session.left == 1)
        #expect(!presenter.isPresented)
    }

    @Test func finishAfterModalEndedOnItsOwnDoesNotAbortAnother() async {
        let session = RecordingSession()   // enter() returns at once: the modal ended itself
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: session)
        presenter.begin(needsAdministrator: false)
        await drainMainRunLoop()
        presenter.finish()
        #expect(session.entered == 1)
        #expect(session.left == 0)
        #expect(!presenter.isPresented)
    }

    @Test func panelStaysVisibleWhenAppDeactivates() {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: RecordingSession())
        presenter.begin(needsAdministrator: true)
        #expect(presenter.panel?.hidesOnDeactivate == false)
        presenter.finish()
    }

    @Test func secondBeginReplacesTheFirst() async throws {
        let session = RecordingSession()
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: session)
        presenter.begin(needsAdministrator: false)
        let first = try #require(presenter.panel)
        presenter.begin(needsAdministrator: false)
        let second = try #require(presenter.panel)
        await drainMainRunLoop()
        #expect(session.entered == 1)
        #expect(first !== second)
        #expect(!first.isVisible)
        #expect(presenter.isPresented)
        presenter.finish()
    }

    @Test func failureAlertTextAndButtons() {
        let failures = [StartupFailure(job: NamedJob(id: "a", title: "Restarting the daemon"),
                                       error: TestError.boom)]
        let alert = makeFailureAlert(appName: "Stenographer", failures)
        #expect(alert.messageText == "Stenographer couldn’t finish setting up")
        #expect(alert.informativeText == "• Restarting the daemon: boom")
        #expect(alert.buttons.map(\.title) == ["Retry Failed", "Continue"])
    }

    @Test func withoutPanelFirstButtonRetriesSecondContinues() async {
        let retry = ModalProgressPanel(appName: "S", modal: RecordingSession()) { _ in .alertFirstButtonReturn }
        let skip = ModalProgressPanel(appName: "S", modal: RecordingSession()) { _ in .alertSecondButtonReturn }
        #expect(await retry.reportFailures([]) == true)
        #expect(await skip.reportFailures([]) == false)
    }
}
