import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// A chat pane that talks to the terminal beside it: what is typed here is
/// typed there, and what the terminal prints comes back as replies, each way
/// through the pane's substitutions.
///
/// **Experimental, and deliberately narrow.** "The terminal beside it" means the
/// first terminal pane in the same tab — the pane assumes there is exactly one.
/// Choosing which terminal to talk to is for when the experiment has earned it.
@MainActor
public final class TerminalChatViewController: NSViewController {

    private let stateStore: PaneStateStore
    private let session: TerminalChatSession
    private let viewModel: AIChatViewModel
    private var chatView: ChatView?

    public init(stateStore: PaneStateStore) {
        self.stateStore = stateStore
        let filter = TextSubstitutionFilter(
            parsing: stateStore.paneStateValue(forKey: Keys.substitutions) ?? "")
        session = TerminalChatSession(filter: filter)
        viewModel = AIChatViewModel(session: session)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.frame = NSRect(x: 0, y: 0, width: 360, height: 500)
        let chatView = ChatView(viewModel: viewModel)
        // Control-C is how a terminal is stopped, so the chat standing in for
        // its command line has to be able to send it.
        chatView.isInterruptEnabled = true
        chatView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chatView)
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: container.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        self.chatView = chatView
        view = container
        applyConnectionState()
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        // The sibling terminal can only be found once this pane is in the tree,
        // and a remembered connection is re-made rather than stored.
        if isConnectEnabled { connect() }
    }

    // MARK: - Connection

    private var isConnectEnabled: Bool {
        get { stateStore.paneStateValue(forKey: Keys.connected) == "1" }
        set { stateStore.setPaneStateValue(newValue ? "1" : nil, forKey: Keys.connected) }
    }

    private func connect() {
        session.connect(to: isConnectEnabled ? siblingTerminal() : nil)
        applyConnectionState()
    }

    private func applyConnectionState() {
        guard let chatView else { return }
        let connected = session.terminal != nil
        chatView.isComposerEnabled = connected
        chatView.composerPrompt = connected ? "$" : nil
        if connected {
            chatView.setStatus(nil, icon: nil)
        } else if isConnectEnabled {
            chatView.setStatus("No terminal in this tab to connect to", icon: nil)
        } else {
            chatView.setStatus("Not connected — turn on Connect to Terminal in this pane's Settings", icon: nil)
        }
    }

    /// The first terminal pane in this tab. Reached by walking up to the pane
    /// holding this content and from there to the tab's root split.
    private func siblingTerminal() -> TerminalSession? {
        var ancestor = parent
        while let current = ancestor, !(current is ComposableTabsPaneViewController) {
            ancestor = current.parent
        }
        guard let pane = ancestor as? ComposableTabsPaneViewController,
              let split = pane.host as? ComposableTabsViewController,
              let root = split.rootSplit() else { return nil }
        return root.allLeaves().lazy.compactMap {
            ($0.contentViewController as? TerminalSessionContentViewController)?
                .sessionManager.selectedSession
        }.first
    }

    // MARK: - Substitutions

    private func setSubstitutions(_ text: String) {
        let filter = TextSubstitutionFilter(parsing: text)
        session.filter = filter
        stateStore.setPaneStateValue(filter.pairs.isEmpty ? nil : filter.serialized,
                                     forKey: Keys.substitutions)
    }

    @objc private func substitutionsEdited(_ sender: NSTextField) {
        setSubstitutions(sender.stringValue)
    }

    private enum Keys {
        static let connected = "connected"
        static let substitutions = "substitutions"
    }
}

extension TerminalChatViewController: PaneOptionsProviding {

    public func makePaneOptionRows() -> [NSView] {
        let connect = WindowOptionsToggle(
            title: "Connect to terminal",
            isOn: isConnectEnabled,
            onChange: { [weak self] value in
                self?.isConnectEnabled = value
                self?.connect()
            }
        ).checkboxAccessibilityID("terminalChat.options.connect")

        let label = NSTextField(labelWithString: "Substitutions (alias = real; …)")
        let field = NSTextField(string: session.filter.serialized)
        field.placeholderString = "bobby mcfarin = mike fullerton"
        field.target = self
        field.action = #selector(substitutionsEdited(_:))
        // Committed when the field loses focus too, so closing the sheet
        // without pressing Return does not throw the edit away.
        field.cell?.sendsActionOnEndEditing = true
        field.setAccessibilityIdentifier("terminalChat.options.substitutions")
        field.widthAnchor.constraint(greaterThanOrEqualToConstant: 280).isActive = true

        let substitutions = NSStackView(views: [label, field])
        substitutions.orientation = .vertical
        substitutions.alignment = .leading
        substitutions.spacing = 4

        return [connect, substitutions]
    }
}

extension TerminalChatViewController: PaneContentTeardown {
    public func paneContentWillBeDiscarded() {
        session.close()
    }
}
