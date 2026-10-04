import AppKit
import Testing
import AgenticToolkitLaunch
@testable import AgenticToolkitLaunchUI

@MainActor
private final class RecordingSession: ModalSession {
    var entered = 0
    var left = 0
    func enter(_ window: NSWindow) { entered += 1 }
    func leave() { left += 1 }
}

private struct NamedJob: StartupJob {
    let id: String
    let title: String
    @MainActor func run(context: StartupJobContext) async throws {}
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

    @Test func finishAfterPresentLeavesModal() async {
        let session = RecordingSession()
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: session)
        presenter.begin(needsAdministrator: false)
        await drainMainRunLoop()
        #expect(session.entered == 1)
        presenter.finish()
        #expect(session.left == 1)
        #expect(!presenter.isPresented)
    }
}
