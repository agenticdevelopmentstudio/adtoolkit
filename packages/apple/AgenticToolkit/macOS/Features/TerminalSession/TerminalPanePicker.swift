import AppKit

/// Lets the user choose a terminal pane by clicking it: a small movable panel
/// asks them to, every click in the window is caught until they do, and the
/// pane they pick is outlined while the panel confirms it.
///
/// Any pane whose content is ``TerminalPaneConnectable`` can be picked,
/// running or not — starting its terminal is the connection's business. A
/// click anywhere else says so and keeps waiting.
/// Cancel, or Escape, ends it without a choice.
///
/// Hold on to the picker while it runs — it reports through `onFinish` when
/// the panel has closed, which is the moment to let it go.
@MainActor
public final class TerminalPanePicker: NSObject {

    /// Called once, when the user picks a terminal pane.
    public var onPick: ((ComposableTabsPaneViewController, TerminalPaneConnectable) -> Void)?
    /// Called once, when the panel has closed — picked or cancelled.
    public var onFinish: (() -> Void)?

    private weak var hostWindow: NSWindow?
    private let panes: () -> [ComposableTabsPaneViewController]
    private let panel: NSPanel
    private let message = NSTextField(wrappingLabelWithString: "")
    private let button = NSButton(title: "Cancel", target: nil, action: nil)
    private var monitor: Any?
    private var highlight: NSView?
    private var hasPicked = false

    /// - Parameters:
    ///   - window: The window whose panes can be picked.
    ///   - panes: The panes on offer, asked again on every click so the
    ///     answer follows the layout.
    public init(window: NSWindow, panes: @escaping () -> [ComposableTabsPaneViewController]) {
        hostWindow = window
        self.panes = panes
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 110),
            styleMask: [.titled, .utilityWindow],
            backing: .buffered, defer: true)
        super.init()
        buildPanel()
    }

    private func buildPanel() {
        panel.title = "Connect to Terminal"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.setAccessibilityIdentifier("terminalPanePicker")

        message.stringValue = "Click on a terminal to connect to."
        message.alignment = .center
        message.setAccessibilityIdentifier("terminalPanePicker.message")

        button.target = self
        button.action = #selector(buttonPressed(_:))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\u{1b}"
        button.setAccessibilityIdentifier("terminalPanePicker.button")

        let stack = NSStackView(views: [message, button])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 16, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
            message.widthAnchor.constraint(equalToConstant: 280)
        ])
        panel.contentView = content
    }

    /// Puts the panel up over the window and starts catching clicks.
    public func begin() {
        guard let hostWindow else { return finish() }
        let size = panel.frame.size
        let host = hostWindow.frame
        panel.setFrameOrigin(NSPoint(x: host.midX - size.width / 2, y: host.midY - size.height / 2))
        panel.orderFront(nil)

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .keyDown]) { [weak self] event in
            self?.handle(event) ?? event
        }
    }

    /// Ends the pick without a choice, as Cancel does.
    public func cancel() {
        finish()
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .keyDown:
            // Escape stops it, and once a choice is confirmed Return does too —
            // from whichever window has the keyboard.
            if event.keyCode == 53 || (hasPicked && (event.keyCode == 36 || event.keyCode == 76)) {
                finish()
                return nil
            }
            return event
        case .leftMouseDown:
            guard !hasPicked, let hostWindow, event.window === hostWindow else { return event }
            pick(at: event.locationInWindow)
            // Nothing else in the window reacts to a click meant as a choice.
            return nil
        default:
            return event
        }
    }

    private func pick(at point: NSPoint) {
        guard let pane = panes().first(where: { pane in
            guard let view = pane.viewIfLoaded, view.window === hostWindow else { return false }
            return view.bounds.contains(view.convert(point, from: nil))
        }) else { return }

        guard let connectable = pane.contentViewController as? TerminalPaneConnectable else {
            message.stringValue = "That isn't a terminal. Click on a terminal to connect to."
            return
        }
        hasPicked = true
        outline(pane.view)
        message.stringValue = "Connected to \(pane.resolvedTitle)."
        button.title = "OK"
        button.keyEquivalent = "\r"
        onPick?(pane, connectable)
    }

    private func outline(_ view: NSView) {
        let outline = PickedPaneOutline(frame: view.bounds)
        outline.autoresizingMask = [.width, .height]
        view.addSubview(outline, positioned: .above, relativeTo: nil)
        highlight = outline
    }

    @objc private func buttonPressed(_ sender: Any?) {
        finish()
    }

    private func finish() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        highlight?.removeFromSuperview()
        highlight = nil
        panel.orderOut(nil)
        let onFinish = self.onFinish
        self.onFinish = nil
        onPick = nil
        onFinish?()
    }
}

/// The accent-coloured ring around the picked pane. Lets every click through
/// and is nothing to accessibility.
private final class PickedPaneOutline: NSView {

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.borderWidth = 3
        layer?.cornerRadius = 4
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func isAccessibilityElement() -> Bool { false }
}
