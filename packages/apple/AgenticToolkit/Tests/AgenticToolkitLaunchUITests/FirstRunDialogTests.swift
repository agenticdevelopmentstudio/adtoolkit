import AppKit
import Testing
import AgenticToolkitLaunch
@testable import AgenticToolkitLaunchUI
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

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

    @Test func noMessageMeansContentFirst() throws {
        let dialog = SampleDialog(modal: RecordingSession())
        #expect(dialog.messageLabel == nil)
        let stack = try #require(dialog.window?.contentView as? NSStackView)
        #expect((stack.arrangedSubviews.first as? NSTextField)?.stringValue == "content")
    }

    @Test func messageIsAHeadlineAboveTheContent() throws {
        let dialog = SampleDialog(message: "Welcome to Sample", modal: RecordingSession())
        let label = try #require(dialog.messageLabel)
        #expect(label.stringValue == "Welcome to Sample")
        let stack = try #require(dialog.window?.contentView as? NSStackView)
        #expect(stack.arrangedSubviews.first === label)
        let content = try #require(stack.arrangedSubviews.dropFirst().first as? NSTextField)
        #expect(content.stringValue == "content")
        let labelSize = try #require(label.font).pointSize
        let contentSize = try #require(content.font).pointSize
        #expect(labelSize > contentSize)
    }

    @Test func buttonsUseOverriddenTitlesAndEnablement() {
        let dialog = SampleDialog(modal: RecordingSession())
        #expect(dialog.cancelButton.title == "Not now")
        #expect(dialog.confirmButton.title == "Install")
        #expect(!dialog.confirmButton.isEnabled)
        #expect(dialog.confirmButton.alphaValue < 1, "a disabled Confirm is faded")
        dialog.checked = true
        dialog.updateConfirmEnabled()
        #expect(dialog.confirmButton.isEnabled)
        #expect(dialog.confirmButton.alphaValue == 1)
    }

    /// The window, headline and buttons are painted from the theme, not the system.
    @Test func paintedFromTheTheme() throws {
        let dialog = SampleDialog(message: "Welcome to Sample", modal: RecordingSession())
        let palette = ThemePaletteObserver.currentPalette
        let window = try #require(dialog.window)
        #expect(window.backgroundColor == palette.windowBackgroundColor)
        #expect(window.appearance?.name == palette.standardAppearance?.name)
        #expect(dialog.messageLabel is ThemedLabel)
        #expect(dialog.messageLabel?.textColor == palette.primaryTextColor)
        for button in [dialog.cancelButton, dialog.confirmButton] {
            #expect(!button.isBordered, "a stock bezel ignores the theme")
            #expect(button.attributedTitle.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
                    == palette.font(.button))
        }
    }

    /// Every part sits inside the window's margins, and a headline longer than
    /// the content wraps instead of running past the right edge.
    @Test func partsStayInsideTheMargins() throws {
        let long = String(repeating: "A long welcome headline that must wrap. ", count: 4)
        for dialog in [SampleDialog(modal: RecordingSession()),
                       SampleDialog(message: long, modal: RecordingSession())] {
            let content = try #require(dialog.window?.contentView as? NSStackView)
            content.layoutSubtreeIfNeeded()
            let inner = content.bounds.insetBy(dx: FirstRunDialog.inset, dy: FirstRunDialog.inset)
                .insetBy(dx: -0.5, dy: -0.5)
            for part in content.arrangedSubviews + [dialog.cancelButton, dialog.confirmButton] {
                let frame = part.convert(part.alignmentRect(forFrame: part.bounds), to: content)
                #expect(inner.contains(frame), "\(type(of: part)) \(frame) leaves \(inner)")
            }
        }
    }

    @Test func buttonsFitTheirTitlesAndShareAHeight() throws {
        let dialog = SampleDialog(modal: RecordingSession())
        dialog.window?.contentView?.layoutSubtreeIfNeeded()
        for button in [dialog.cancelButton, dialog.confirmButton] {
            #expect(button.frame.height == FirstRunDialog.buttonHeight)
            #expect(button.frame.width >= FirstRunDialog.minimumButtonWidth)
            #expect(button.frame.width >= button.attributedTitle.size().width)
        }
        #expect(dialog.cancelButton.frame.maxX < dialog.confirmButton.frame.minX, "Confirm is rightmost")
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
