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
                self.modal.enter(window)
                // enter() blocks until the session ends; if it ended some way
                // other than finish(), a later finish() must not abort whatever
                // modal is topmost by then.
                if self.generation == token { self.inModal = false }
            }
        }
    }

    public func willRun(_ job: any StartupJob) { update(detail: job.title) }

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
    }

    public func reportFailures(_ failures: [StartupFailure]) async -> Bool {
        let alert = makeFailureAlert(appName: appName, failures)
        guard let panel else {
            return await runAlert(alert) == .alertFirstButtonReturn
        }
        return await withCheckedContinuation { cont in
            alert.beginSheetModal(for: panel) { cont.resume(returning: $0 == .alertFirstButtonReturn) }
        }
    }
}

/// The retry-or-continue alert. The first button retries the failed jobs.
@MainActor
func makeFailureAlert(appName: String, _ failures: [StartupFailure]) -> NSAlert {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "\(appName) couldn’t finish setting up"
    alert.informativeText = failures
        .map { "• \($0.job.title): \($0.error.localizedDescription)" }
        .joined(separator: "\n")
    alert.addButton(withTitle: "Retry Failed")
    alert.addButton(withTitle: "Continue")
    return alert
}
