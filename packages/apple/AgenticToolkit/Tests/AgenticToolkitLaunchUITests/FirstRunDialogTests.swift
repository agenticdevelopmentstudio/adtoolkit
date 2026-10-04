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

@MainActor
private final class SampleDialog: FirstRunDialog {
    var checked = false
    override var dialogTitle: String { "Sample" }
    override var isConfirmEnabled: Bool { checked }
    override func makeContentView() -> NSView { NSTextField(labelWithString: "content") }
    override func jobsForConfirm() -> [any StartupJob] { [NamedJob(id: "x", title: "X")] }
}

@MainActor
private final class DoneBox {
    var done = false
}

@MainActor
private final class DialogBox {
    var dialog: SampleDialog?
}

@MainActor
private func drainMainRunLoop() async {
    await withCheckedContinuation { cont in
        RunLoop.main.perform(inModes: [.common]) { cont.resume() }
    }
}

/// Waits (bounded, no wall clock) until the session was entered.
@MainActor
private func waitForEnter(_ session: RecordingSession) async throws {
    for _ in 0..<10_000 where session.entered == 0 { await Task.yield() }
    try #require(session.entered == 1)
}

@MainActor @Suite struct FirstRunDialogTests {
    @Test func windowIsClosableNotResizable() throws {
        let dialog = SampleDialog(modal: RecordingSession())
        let window = try #require(dialog.window)
        #expect(window.styleMask.contains(.closable))
        #expect(!window.styleMask.contains(.resizable))
        #expect(window.title == "Sample")
    }

    @Test func buttonsUseOverriddenTitlesAndEnablement() {
        let dialog = SampleDialog(modal: RecordingSession())
        #expect(dialog.cancelButton.title == "Not now")
        #expect(dialog.confirmButton.title == "Install")
        #expect(!dialog.confirmButton.isEnabled)
        dialog.checked = true
        dialog.updateConfirmEnabled()
        #expect(dialog.confirmButton.isEnabled)
    }

    @Test func confirmAfterModalEndedOnItsOwnDoesNotAbortAnother() async throws {
        let session = RecordingSession()
        let dialog = SampleDialog(modal: session)
        dialog.checked = true
        let task = Task { await dialog.runModal() }
        try await waitForEnter(session)
        dialog.confirm()
        guard case .confirmed(let jobs) = await task.value else { Issue.record("expected confirmed"); return }
        #expect(jobs.map(\.id) == ["x"])
        // enter() already returned, so the session is over: leave() would
        // abort whatever modal is topmost now.
        #expect(session.entered == 1)
        #expect(session.left == 0)
    }

    @Test func confirmBeforeEnterNeverEntersModal() async throws {
        let session = RecordingSession()
        let dialog = SampleDialog(modal: session)
        dialog.checked = true
        let task = Task { await dialog.runModal() }
        // showWindow runs synchronously inside runModal, before the entry
        // block is queued.
        for _ in 0..<10_000 where dialog.window?.isVisible != true { await Task.yield() }
        try #require(dialog.window?.isVisible == true)
        dialog.confirm()
        _ = await task.value
        await drainMainRunLoop()   // FIFO: runs after the queued entry block
        #expect(session.entered == 0)
        #expect(session.left == 0)
        #expect(dialog.window?.isVisible == false)
    }

    @Test func confirmInsideModalLeavesIt() async throws {
        let session = RecordingSession()
        let dialog = SampleDialog(modal: session)
        session.onEnter = { dialog.confirm() }
        let task = Task { await dialog.runModal() }
        try await waitForEnter(session)
        guard case .confirmed = await task.value else { Issue.record("expected confirmed"); return }
        #expect(session.left == 1)
    }

    @Test func closeBoxWithNoModalRunningCloses() throws {
        let dialog = SampleDialog(modal: RecordingSession())
        let window = try #require(dialog.window)
        #expect(dialog.windowShouldClose(window) == true)
    }

    @Test func programmaticCloseCancelsTheWaitingCaller() async throws {
        let session = RecordingSession()
        let dialog = SampleDialog(modal: session)
        let box = DoneBox()
        let task = Task {
            let result = await dialog.runModal()
            box.done = true
            return result
        }
        try await waitForEnter(session)
        dialog.close()
        for _ in 0..<10_000 where !box.done { await Task.yield() }
        try #require(box.done)
        guard case .cancelled = await task.value else { Issue.record("expected cancelled"); return }
    }

    @Test func closeBoxCancels() async throws {
        let session = RecordingSession()
        let dialog = SampleDialog(modal: session)
        let task = Task { await dialog.runModal() }
        try await waitForEnter(session)
        let window = try #require(dialog.window)
        #expect(dialog.windowShouldClose(window) == false)
        guard case .cancelled = await task.value else { Issue.record("expected cancelled"); return }
    }

    @Test func cancelButtonCancels() async throws {
        let session = RecordingSession()
        let dialog = SampleDialog(modal: session)
        let task = Task { await dialog.runModal() }
        try await waitForEnter(session)
        dialog.cancelButton.performClick(nil)
        guard case .cancelled = await task.value else { Issue.record("expected cancelled"); return }
    }

    @Test func experienceReturnsDialogJobs() async throws {
        let session = RecordingSession()
        let box = DialogBox()
        let experience = DialogFirstRunExperience {
            let dialog = SampleDialog(modal: session)
            dialog.checked = true
            box.dialog = dialog
            return dialog
        }
        let task = Task { await experience.start() }
        try await waitForEnter(session)
        box.dialog?.confirm()
        #expect(await task.value.map(\.id) == ["x"])
    }

    @Test func experienceReturnsNoJobsOnCancel() async throws {
        let session = RecordingSession()
        let box = DialogBox()
        let experience = DialogFirstRunExperience {
            let dialog = SampleDialog(modal: session)
            box.dialog = dialog
            return dialog
        }
        let task = Task { await experience.start() }
        try await waitForEnter(session)
        box.dialog?.cancel()
        #expect(await task.value.isEmpty)
    }
}
