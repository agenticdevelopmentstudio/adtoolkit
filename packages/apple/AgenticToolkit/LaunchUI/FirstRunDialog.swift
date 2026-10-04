import AppKit
import AgenticToolkitCoreMacOS
import AgenticToolkitLaunch

/// The standard first-run dialog: a fixed-size, closable window with the
/// subclass's content above a Cancel/Confirm row. Closing it is Cancel.
///
/// Subclass and override the titles, `makeContentView()`, `isConfirmEnabled`
/// and `jobsForConfirm()`; call `updateConfirmEnabled()` when your content changes.
///
/// The window is built inside `super.init`, before the rest of a subclass's
/// initializer body runs. That is why the titles are computed `open var`s, not
/// stored ones. A subclass whose titles depend on per-instance state must
/// assign that state BEFORE calling `super.init`.
@MainActor
open class FirstRunDialog: NSWindowController, NSWindowDelegate {
    public enum Result: Sendable {
        case confirmed([any StartupJob])
        case cancelled
    }

    open var dialogTitle: String { "Welcome" }
    open var cancelTitle: String { "Not now" }
    open var confirmTitle: String { "Install" }
    open var isConfirmEnabled: Bool { true }
    open func makeContentView() -> NSView { NSView() }
    open func jobsForConfirm() -> [any StartupJob] { [] }

    public let confirmButton = NSButton(title: "", target: nil, action: nil)
    public let cancelButton = NSButton(title: "", target: nil, action: nil)
    private let modal: any ModalSession
    private var continuation: CheckedContinuation<Result, Never>?
    /// Bumped by every runModal() and complete(); a queued run-loop block does
    /// nothing if the value it was scheduled under no longer matches.
    private var generation = 0
    private var inModal = false

    public init(modal: any ModalSession = ApplicationModalSession()) {
        self.modal = modal
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        buildContent()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func buildContent() {
        guard let window else { return }
        window.title = dialogTitle
        cancelButton.title = cancelTitle
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.keyEquivalent = "\u{1b}"
        confirmButton.title = confirmTitle
        confirmButton.target = self
        confirmButton.action = #selector(confirmClicked)
        confirmButton.keyEquivalent = "\r"
        let buttons = NSStackView(views: [NSView(), cancelButton, confirmButton])
        let stack = NSStackView(views: [makeContentView(), buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        window.contentView = stack
        window.setContentSize(stack.fittingSize)
        updateConfirmEnabled()
    }

    public func updateConfirmEnabled() { confirmButton.isEnabled = isConfirmEnabled }

    public func runModal() async -> Result {
        guard continuation == nil else {
            assertionFailure("runModal while already running")
            return .cancelled
        }
        return await withCheckedContinuation { cont in
            continuation = cont
            generation += 1
            let token = generation
            window?.center()
            NSApp.activateUnlessQuiet()
            showWindow(nil)
            // Entered from a run-loop block, as in ModalProgressPanel, so the
            // main queue stays drainable under the modal session.
            RunLoop.main.perform(inModes: [.common]) {
                MainActor.assumeIsolated {
                    guard self.generation == token, let window = self.window else { return }
                    self.inModal = true
                    self.modal.enter(window)
                    // enter() blocks until the session ends; if it ended some
                    // way other than complete(), a later complete() must not
                    // abort whatever modal is topmost by then.
                    if self.generation == token { self.inModal = false }
                }
            }
        }
    }

    @objc private func confirmClicked() { confirm() }
    @objc private func cancelClicked() { cancel() }

    public func confirm() { complete(.confirmed(jobsForConfirm())) }
    public func cancel() { complete(.cancelled) }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        cancel()
        return false   // complete() already ordered it out
    }

    private func complete(_ result: Result) {
        guard let continuation else { return }
        self.continuation = nil
        generation += 1
        if inModal {
            inModal = false
            modal.leave()
        }
        window?.orderOut(nil)
        continuation.resume(returning: result)
    }
}
