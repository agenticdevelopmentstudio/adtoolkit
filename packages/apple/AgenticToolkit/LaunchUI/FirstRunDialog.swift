import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS
import AgenticToolkitLaunch

/// The standard first-run dialog: a fixed-size, closable window with an
/// optional headline message, the subclass's content, and a Cancel/Confirm
/// row, all in the app's theme. Closing it is Cancel.
///
/// The window is as wide as the content's fitting width (at least
/// `minimumContentWidth`) plus `inset` each side; give wrapping labels in the
/// content a `preferredMaxLayoutWidth` (``ThemedLabel/wrapping(_:width:role:textRole:weight:)``)
/// so that width is the one they wrap at.
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
    /// The headline above the content; nil when the dialog was given no message.
    public private(set) var messageLabel: NSTextField?
    private let message: String?
    private let modal: any ModalSession
    private var continuation: CheckedContinuation<Result, Never>?
    /// Bumped by every runModal() and complete(); a queued run-loop block does
    /// nothing if the value it was scheduled under no longer matches.
    private var generation = 0
    private var inModal = false

    /// Space around the window's content and between its parts.
    public static let inset: CGFloat = 24
    public static let spacing: CGFloat = 20

    /// `message`, when given, is a headline above the content: a greeting on
    /// first run, say, that a later visit to the same dialog leaves out.
    public init(message: String? = nil, modal: any ModalSession = ApplicationModalSession()) {
        self.message = message
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

    /// The narrowest the content column gets, whatever the content asks for.
    public static let minimumContentWidth: CGFloat = 432
    /// The Cancel/Confirm buttons' size: painted borderless by the theme, they
    /// have no bezel padding of their own.
    public static let buttonHeight: CGFloat = 28
    public static let minimumButtonWidth: CGFloat = 88
    static let buttonTitlePadding: CGFloat = 32
    /// A disabled Confirm, faded as `ThemedActionButton` fades: the theme's paint
    /// does not change with `isEnabled`.
    static let disabledAlpha: CGFloat = 0.45

    /// Painted from the theme: the window's backdrop and appearance, the
    /// headline, and both buttons, repainted on every theme change.
    private func buildContent() {
        guard let window else { return }
        window.title = dialogTitle
        themeObserver = ThemePaletteObserver { [weak window] palette in
            // Stock controls (the subclass's checkboxes) draw from the
            // appearance, so it follows the theme's backdrop.
            window?.appearance = palette.standardAppearance
            window?.backgroundColor = palette.windowBackgroundColor
        }
        cancelButton.title = cancelTitle
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.keyEquivalent = "\u{1b}"
        confirmButton.title = confirmTitle
        confirmButton.target = self
        confirmButton.action = #selector(confirmClicked)
        confirmButton.keyEquivalent = "\r"
        themeButton(cancelButton) { $0.applySecondaryActionTheme($1) }
        themeButton(confirmButton) { $0.applyPrimaryActionTheme($1) }
        let buttons = NSStackView(views: [NSView(), cancelButton, confirmButton])
        buttons.spacing = 12

        // One column width for every part, fixed before layout: the content
        // decides it, and the headline wraps to it rather than widening the
        // window to its one-line length.
        let content = makeContentView()
        let width = max(content.fittingSize.width, Self.minimumContentWidth)
        var parts: [NSView] = [content, buttons]
        if let message {
            let label = ThemedLabel.wrapping(message, width: width, textRole: .title)
            messageLabel = label
            parts.insert(label, at: 0)
        }
        let stack = NSStackView(views: parts)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = Self.spacing
        stack.edgeInsets = NSEdgeInsets(top: Self.inset, left: Self.inset, bottom: Self.inset, right: Self.inset)
        stack.setCustomSpacing(Self.inset + Self.spacing / 2, after: content)
        for part in parts { part.widthAnchor.constraint(equalToConstant: width).isActive = true }
        window.contentView = stack
        window.setContentSize(stack.fittingSize)
        updateConfirmEnabled()
    }

    private var themeObserver: ThemePaletteObserver?

    private func themeButton(_ button: NSButton, paint: @escaping @MainActor (NSButton, SemanticPalette) -> Void) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Self.buttonHeight).isActive = true
        let width = button.widthAnchor.constraint(equalToConstant: Self.minimumButtonWidth)
        width.isActive = true
        button.observeTheme { button, palette in
            paint(button, palette)
            width.constant = max(Self.minimumButtonWidth,
                                 ceil(button.attributedTitle.size().width) + Self.buttonTitlePadding)
        }
    }

    public func updateConfirmEnabled() {
        confirmButton.isEnabled = isConfirmEnabled
        confirmButton.alphaValue = confirmButton.isEnabled ? 1 : Self.disabledAlpha
    }

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
        // Not running: nothing to cancel, so let the window close normally.
        guard continuation != nil else { return true }
        cancel()
        return false   // complete() already ordered it out
    }

    /// A programmatic close() skips windowShouldClose; it still must resume
    /// the waiting caller. complete() orders out rather than closes, so this
    /// cannot re-enter, and cancel() is idempotent.
    public func windowWillClose(_ notification: Notification) { cancel() }

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
