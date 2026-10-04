import AppKit
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
    private var finished = false
    private var inModal = false
    private let detail = NSTextField(labelWithString: "")
    private let notice = NSTextField(wrappingLabelWithString: "")
    private let spinner = NSProgressIndicator()

    public init(appName: String, modal: any ModalSession = ApplicationModalSession()) {
        self.appName = appName
        self.modal = modal
    }

    public func begin(needsAdministrator: Bool) {
        finished = false
        let panel = UndismissablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 120),
            styleMask: [.titled], backing: .buffered, defer: false)
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
        panel.makeKeyAndOrderFront(nil)
        // Entered from a run-loop block — not a main-queue block or a main-actor
        // Task — so the main queue stays drainable under the modal session and
        // the jobs (async, main actor) keep running. Same pattern as
        // PermissionWalkthrough.presentFromRunLoop.
        RunLoop.main.perform(inModes: [.common]) {
            MainActor.assumeIsolated {
                guard !self.finished, let window = self.panel else { return }
                self.inModal = true
                self.modal.enter(window)
            }
        }
    }

    public func willRun(_ job: any StartupJob) { update(detail: job.title) }

    public func update(detail text: String) {
        detailText = text
        detail.stringValue = text
    }

    public func finish() {
        finished = true
        if inModal {
            inModal = false
            modal.leave()
        }
        panel?.orderOut(nil)
        panel = nil
        isPresented = false
    }

    public func reportFailures(_ failures: [StartupFailure]) async -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "\(appName) couldn’t finish setting up"
        alert.informativeText = failures
            .map { "• \($0.job.title): \($0.error.localizedDescription)" }
            .joined(separator: "\n")
        alert.addButton(withTitle: "Retry Failed")
        alert.addButton(withTitle: "Continue")
        guard let panel else {
            return await runAlertFromRunLoop(alert) == .alertFirstButtonReturn
        }
        return await withCheckedContinuation { cont in
            alert.beginSheetModal(for: panel) { cont.resume(returning: $0 == .alertFirstButtonReturn) }
        }
    }
}
