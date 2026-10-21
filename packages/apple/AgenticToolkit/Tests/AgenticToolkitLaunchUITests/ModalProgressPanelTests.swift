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

@MainActor private final class Order { var events: [String] = [] }

/// Blocks the main thread in a nested run loop, as NSAppleScript does.
private struct NestedLoopJob: StartupJob {
    let id = "nested"
    let title = "Nested"
    let order: Order
    @MainActor func run(context: StartupJobContext) async throws {
        order.events.append("job")
        spinNestedRunLoop()
    }
}

/// Synchronous on purpose: NSAppleScript's nested loop runs from a blocking call.
private func spinNestedRunLoop() {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
}

private enum TestError: Error, LocalizedError {
    case boom
    /// A privileged tool's whole stderr, as the AppleScript runner reports it.
    case wall
    var errorDescription: String? {
        switch self {
        case .boom: "boom"
        case .wall: (1...40).map { "chown: file\($0): Operation not permitted" }.joined(separator: "\n")
        }
    }
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

    /// NSAppleScript spins a nested run loop while it blocks for the password.
    /// Had the first job started before the panel's modal, that loop would run
    /// the queued modal entry inside the script, and neither could return.
    @Test func firstJobStartsOnlyOnceTheModalIsEntered() async {
        let session = RecordingSession()
        let order = Order()
        session.onEnter = { order.events.append("enter") }
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: session)
        _ = await LaunchManager.runJobs([NestedLoopJob(order: order)], privileged: AppleScriptPrivilegedRunner(),
                                        presenter: presenter, progress: { _ in })
        #expect(order.events == ["enter", "job"])
        #expect(!presenter.isPresented)
    }

    @Test func waitUntilPresentedReturnsWhenFinishedFirst() async {
        let presenter = ModalProgressPanel(appName: "Stenographer", modal: RecordingSession())
        presenter.begin(needsAdministrator: false)
        presenter.finish()
        await presenter.waitUntilPresented()   // must not park forever
        #expect(!presenter.isPresented)
    }

    @Test func failureAlertTextAndButtons() {
        let failures = [StartupFailure(job: NamedJob(id: "a", title: "Restarting the daemon"),
                                       error: TestError.boom)]
        let alert = makeFailureAlert(appName: "Stenographer", failures)
        #expect(alert.messageText == "Stenographer couldn’t finish setting up")
        #expect(alert.informativeText == "• Restarting the daemon: boom")
        #expect(alert.buttons.map(\.title) == ["Continue", "Try Again"])
        #expect(alert.accessoryView == nil)   // nothing more to say, so no Details
    }

    /// A tool's whole stderr is summarized by its first line; the rest waits,
    /// collapsed, in the Details disclosure rather than in the alert's text.
    @Test func multilineErrorIsSummarizedAndDetailedSeparately() throws {
        let failures = [StartupFailure(job: NamedJob(id: "a", title: "Letting S update itself"),
                                       error: TestError.wall)]
        let alert = makeFailureAlert(appName: "S", failures)
        #expect(alert.informativeText == "• Letting S update itself: chown: file1: Operation not permitted")
        let details = try #require(alert.accessoryView as? AlertDetails)
        #expect(details.textView.string.hasPrefix("Letting S update itself\nchown: file1:"))
        #expect(details.textView.string.hasSuffix("chown: file40: Operation not permitted"))
        #expect(!details.isExpanded)
        #expect(!details.textView.isEditable && details.textView.isSelectable)
    }

    @Test func detailsDisclosureExpandsAndCollapses() {
        let alert = NSAlert()
        let details = AlertDetails.attach("line one\nline two", to: alert)
        let collapsed = details.frame.height
        details.disclosure.performClick(nil)
        #expect(details.isExpanded)
        #expect(details.frame.height > collapsed + 100)
        details.disclosure.performClick(nil)
        #expect(!details.isExpanded)
        #expect(details.frame.height == collapsed)
    }

    @Test func longSingleLineIsCutInTheSummaryAndKeptWholeInDetails() {
        struct Long: LocalizedError { var errorDescription: String? { String(repeating: "x", count: 300) } }
        let failures = [StartupFailure(job: NamedJob(id: "a", title: "Step"), error: Long())]
        #expect(failureSummary(failures) == "• Step: " + String(repeating: "x", count: failureSummaryLimit) + "…")
        #expect(failureDetails(failures) == "Step\n" + String(repeating: "x", count: 300))
    }

    @Test func firstButtonContinuesSecondRetries() async {
        let retry = ModalProgressPanel(appName: "S", modal: RecordingSession()) { _ in .alertSecondButtonReturn }
        let skip = ModalProgressPanel(appName: "S", modal: RecordingSession()) { _ in .alertFirstButtonReturn }
        #expect(await retry.reportFailures([]) == true)
        #expect(await skip.reportFailures([]) == false)
    }

    /// Never a sheet: with the progress panel up, the failure still runs as an
    /// application-modal alert of its own.
    @Test func failuresRunAsAModalAlertEvenWithThePanelUp() async {
        var ran = 0
        let presenter = ModalProgressPanel(appName: "S", modal: RecordingSession()) { _ in
            ran += 1
            return .alertFirstButtonReturn
        }
        presenter.begin(needsAdministrator: false)
        #expect(await presenter.reportFailures([]) == false)
        #expect(ran == 1)
        #expect(presenter.panel?.attachedSheet == nil)
        presenter.finish()
    }
}
