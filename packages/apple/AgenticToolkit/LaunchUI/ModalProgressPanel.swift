import AppKit
import AgenticToolkitCoreMacOS
import AgenticToolkitLaunch

/// How the panel's modal session is entered and left. Injected so tests can
/// observe it without spinning a real modal loop.
@MainActor
public protocol ModalSession {
    func enter(_ window: NSWindow)
    func leave()
}

@MainActor
public struct ApplicationModalSession: ModalSession {
    public init() {}
    public func enter(_ window: NSWindow) { NSApp.runModal(for: window) }
    /// abortModal, not stopModal: the stop comes from a job's completion, not
    /// an event, and stopModal only takes effect after the next event.
    public func leave() { NSApp.abortModal() }
}

/// A panel nobody can dismiss: titled, no close box, Escape ignored. It is the
/// app's only surface while the startup queue runs.
final class UndismissablePanel: NSPanel {
    override func cancelOperation(_ sender: Any?) {}
    override var canBecomeKey: Bool { true }
}

@MainActor
public final class ModalProgressPanel: NSObject, LaunchPresenter {
    public private(set) var panel: NSPanel?
    public private(set) var isPresented = false
    public private(set) var detailText = ""
    public private(set) var noticeText = ""

    private let appName: String
    private let modal: any ModalSession
    private let runAlert: @MainActor (NSAlert) async -> NSApplication.ModalResponse
    /// Bumped by every begin() and finish(); a queued run-loop block carries the
    /// value it was scheduled under and does nothing if it no longer matches.
    private var generation = 0
    private var inModal = false
    /// Callers of waitUntilPresented(), resumed as the modal session opens or
    /// the panel goes away.
    private var presentedWaiters: [CheckedContinuation<Void, Never>] = []
    private let detail = NSTextField(labelWithString: "")
    private let notice = NSTextField(wrappingLabelWithString: "")
    private let spinner = NSProgressIndicator()

    public init(appName: String,
                modal: any ModalSession = ApplicationModalSession(),
                runAlert: @escaping @MainActor (NSAlert) async -> NSApplication.ModalResponse = {
                    await runAlertFromRunLoop($0)
                }) {
        self.appName = appName
        self.modal = modal
        self.runAlert = runAlert
    }

    public func begin(needsAdministrator: Bool) {
        // A second begin() replaces the first completely: leave its modal and
        // order its panel out, so sessions never nest and no panel is orphaned.
        finish()
        let token = generation
        let panel = UndismissablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 120),
            styleMask: [.titled], backing: .buffered, defer: false)
        // The password prompt takes focus; the panel is the app's only surface
        // and must stay up while the app is inactive.
        panel.hidesOnDeactivate = false
        panel.title = "Setting up \(appName)"
        noticeText = needsAdministrator
            ? "\(appName) is getting ready. You may be asked for your password."
            : "\(appName) is getting ready."
        notice.stringValue = noticeText
        spinner.style = .spinning
        spinner.startAnimation(nil)
        let stack = NSStackView(views: [notice, NSStackView(views: [spinner, detail])])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        panel.contentView = stack
        panel.center()
        self.panel = panel
        isPresented = true
        NSApp.activateUnlessQuiet()
        panel.makeKeyAndOrderFront(nil)
        // Entered from a run-loop block — not a main-queue block or a main-actor
        // Task — so the main queue stays drainable under the modal session and
        // the jobs (async, main actor) keep running. Same pattern as
        // PermissionWalkthrough.presentFromRunLoop.
        RunLoop.main.perform(inModes: [.common]) {
            MainActor.assumeIsolated {
                guard self.generation == token, let window = self.panel else { return }
                self.inModal = true
                // Resumed waiters run inside the session about to start, so a
                // job's nested run loop nests inside the modal, never under it.
                self.releasePresentedWaiters()
                self.modal.enter(window)
                // enter() blocks until the session ends; if it ended some way
                // other than finish(), a later finish() must not abort whatever
                // modal is topmost by then.
                if self.generation == token { self.inModal = false }
            }
        }
    }

    public func waitUntilPresented() async {
        guard panel != nil, !inModal else { return }
        await withCheckedContinuation { presentedWaiters.append($0) }
    }

    private func releasePresentedWaiters() {
        let waiters = presentedWaiters
        presentedWaiters = []
        waiters.forEach { $0.resume() }
    }

    public func willRun(_ job: any StartupJob) {
        update(detail: job.title)
        // A `.last` job (the permissions walkthrough) runs its own modal; the
        // progress panel steps out of its way. Last thing done to the panel.
        if job.order == .last { panel?.orderOut(nil) }
    }

    public func update(detail text: String) {
        detailText = text
        detail.stringValue = text
    }

    public func finish() {
        generation += 1
        if inModal {
            inModal = false
            modal.leave()
        }
        panel?.orderOut(nil)
        panel = nil
        isPresented = false
        releasePresentedWaiters()
    }

    /// A modal alert of its own, never a sheet on the progress panel: a sheet
    /// reads as part of the panel, and the failure is the one thing the user
    /// must answer before anything else happens.
    public func reportFailures(_ failures: [StartupFailure]) async -> Bool {
        await runAlert(makeFailureAlert(appName: appName, failures)) == .alertFirstButtonReturn
    }
}

/// The retry-or-continue alert. The first button retries the failed jobs.
///
/// The informative text names each failed step with one short line of why; the
/// full error, which can be a tool's entire stderr, goes behind `AlertDetails`.
@MainActor
func makeFailureAlert(appName: String, _ failures: [StartupFailure]) -> NSAlert {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "\(appName) couldn’t finish setting up"
    alert.informativeText = failureSummary(failures)
    let details = failureDetails(failures)
    if !details.isEmpty { AlertDetails.attach(details, to: alert) }
    alert.addButton(withTitle: "Retry Failed")
    alert.addButton(withTitle: "Continue")
    return alert
}

/// The longest a summary line's reason runs before it is cut with an ellipsis.
let failureSummaryLimit = 120

/// One line per failed step: its title, and the first line of its error.
func failureSummary(_ failures: [StartupFailure]) -> String {
    failures.map { failure in
        let firstLine = failure.error.localizedDescription
            .split(whereSeparator: \.isNewline).first
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        guard !firstLine.isEmpty else { return "• \(failure.job.title)" }
        let reason = firstLine.count > failureSummaryLimit
            ? firstLine.prefix(failureSummaryLimit) + "…" : firstLine
        return "• \(failure.job.title): \(reason)"
    }.joined(separator: "\n")
}

/// Every step's full error, headed by its title. Empty when no error says more
/// than its summary line already did, so a one-line failure gets no disclosure.
func failureDetails(_ failures: [StartupFailure]) -> String {
    let full = failures.map {
        (title: $0.job.title,
         text: $0.error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    let saysMore = full.contains { $0.text.contains(where: \.isNewline) || $0.text.count > failureSummaryLimit }
    guard saysMore else { return "" }
    return full.map { "\($0.title)\n\($0.text)" }.joined(separator: "\n\n")
}
