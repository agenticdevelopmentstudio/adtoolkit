import AppKit
import OSLog
import AgenticToolkitCore

/// The floating panel the command palette lives in.
///
/// Everything about the panel itself — the titleless `NSPanel`, the container
/// framing, the show ordering, the pointer-screen positioning, and the single
/// re-entrant dismissal path — is `FloatingChooserPanelController`'s, and is
/// documented there. This type is the things that are the palette's own: its
/// fixed size, clearing the model around every appearance, focusing the search
/// field, and the **picker mode** — another feature's chooser filling the same
/// panel in place of the command list.
@MainActor
public final class CommandPaletteWindowController: FloatingChooserPanelController {

    /// 640x400, spelled rather than asked of the content: the palette's list is
    /// a fixed size whatever it currently holds, so a chooser that shrank to
    /// three commands and grew back would move under the pointer between one
    /// query and the next.
    private static let contentSize = NSSize(width: 640, height: 400)

    private let paletteController: CommandPaletteViewController
    private let modeHost: CommandPaletteModeHostViewController

    /// The Escape handling a picker gets for free. A picker's own search field
    /// swallows Escape to clear itself, exactly as the palette's does, so the
    /// panel installs the same window-level monitor the palette uses.
    private let pickerKeyboard = PickerKeyboardController()

    // MARK: - Lifecycle

    public init(model: CommandPaletteModel) {
        let paletteController = CommandPaletteViewController(model: model)
        let modeHost = CommandPaletteModeHostViewController(commands: paletteController)
        self.paletteController = paletteController
        self.modeHost = modeHost
        super.init(
            content: modeHost,
            contentRect: NSRect(origin: .zero, size: Self.contentSize)
        )
        window?.setAccessibilityIdentifier("command-palette.window")

        paletteController.onRun = { [weak self] in self?.close() }
        paletteController.onCancel = { [weak self] in self?.close() }
        pickerKeyboard.onCancel = { [weak self] in self?.close() }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show

    /// Bring the palette up on its command list, empty, re-read from the
    /// registry, and focus it.
    ///
    /// The reset happens before `super.show()` positions and activates, so the
    /// panel is never on screen holding the last visit's typing even for a
    /// frame.
    public override func show() {
        endPicker()
        paletteController.reset()
        super.show()
        logger.debug("Command palette shown")
    }

    /// Bring the palette up in picker mode, showing `picker` in place of the
    /// command list. `picker` takes the keyboard the way the command list does:
    /// its first responder is whatever it makes first responder when it
    /// appears. Escape, a click away and the picker's own dismissal all close
    /// the panel, which returns it to the command list for next time.
    public func show(picker: NSViewController) {
        modeHost.show(picker)
        super.show()
        pickerKeyboard.startEscapeMonitor(for: window)
        logger.debug("Command palette shown in picker mode")
    }

    /// The command list keeps first responder for the palette's whole life —
    /// the table is a display surface. A picker focuses itself on appearing.
    public override func takeInitialFocus() {
        guard !modeHost.isShowingPicker else { return }
        paletteController.focusSearchField()
    }

    // MARK: - Dismiss

    /// Every dismissal clears the palette and leaves picker mode.
    ///
    /// Here rather than only in `show()` because a closed palette should not be
    /// sitting on the last visit's query and selection at all: `runSelection`
    /// takes what it needs from the model *before* asking for the dismissal
    /// that clears it.
    public override func panelWillClose() {
        endPicker()
        paletteController.reset()
    }

    private func endPicker() {
        pickerKeyboard.stopEscapeMonitor()
        modeHost.showCommands()
    }
}

extension CommandPaletteWindowController: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// The panel's one child: the command list, or a picker in its place.
///
/// The floating panel hosts exactly one content controller for its whole life,
/// so the switch between modes happens one level down, here, rather than by
/// swapping the window's content (which would re-frame the panel).
@MainActor
final class CommandPaletteModeHostViewController: NSViewController {

    private let commands: NSViewController
    private var picker: NSViewController?

    var isShowingPicker: Bool { picker != nil }

    init(commands: NSViewController) {
        self.commands = commands
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        view = NSView()
        install(commands)
    }

    func show(_ newPicker: NSViewController) {
        _ = view
        removeCurrent()
        picker = newPicker
        install(newPicker)
    }

    func showCommands() {
        guard picker != nil else { return }
        removeCurrent()
        picker = nil
        install(commands)
    }

    private func removeCurrent() {
        let current = picker ?? commands
        current.view.removeFromSuperview()
        current.removeFromParent()
    }

    private func install(_ child: NSViewController) {
        addChild(child)
        let hosted = child.view
        hosted.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosted)
        NSLayoutConstraint.activate([
            hosted.topAnchor.constraint(equalTo: view.topAnchor),
            hosted.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosted.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosted.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
