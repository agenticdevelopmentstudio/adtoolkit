import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// A chat pane that talks to a terminal pane: what is typed here is typed
/// there, and what the terminal prints comes back as replies.
///
/// Which terminal is the user's choice: Connect to Terminal… in the pane's
/// Settings puts up a ``TerminalPanePicker`` and they click the one they mean.
/// Any pane offering ``TerminalPaneConnectable`` will do — the chat knows
/// nothing about what kind of terminal it is. The choice is remembered by
/// pane and re-made when the chat next appears.
@MainActor
public final class TerminalChatViewController: NSViewController {

    private let stateStore: PaneStateStore
    /// What this pane types into its terminal through — public so a persona
    /// chat in the same tab can drive it (`PersonaTerminalChatViewController`).
    public let session: TerminalChatSession
    private let viewModel: AIChatViewModel
    private var chatView: ChatView?
    private let directory: TerminalChatDirectory?
    private let listing: TerminalChatDirectory.Listing?
    private var picker: TerminalPanePicker?

    /// - Parameters:
    ///   - directory: Where this chat lists itself, under `listing`, for
    ///     processes outside the app to drive; nil keeps it private.
    public init(
        stateStore: PaneStateStore,
        directory: TerminalChatDirectory? = nil,
        listing: TerminalChatDirectory.Listing? = nil
    ) {
        self.stateStore = stateStore
        self.directory = directory
        self.listing = listing
        session = TerminalChatSession()
        viewModel = AIChatViewModel(session: session)
        super.init(nibName: nil, bundle: nil)
        // Earlier versions kept a connect flag and substitution words here;
        // the words now belong to the private terminal alone, so none are
        // left lying in pane state.
        stateStore.setPaneStateValue(nil, forKey: Keys.legacyConnected)
        stateStore.setPaneStateValue(nil, forKey: Keys.legacySubstitutions)
        if let directory, let listing { directory.add(session, as: listing) }
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
        // The remembered pane can only be found once this one is in the tree.
        if session.terminal == nil { reconnect() }
    }

    // MARK: - Connection

    /// The pane last connected to, by node.
    private var connectedPaneID: UUID? {
        get { stateStore.paneStateValue(forKey: Keys.connectedPane).flatMap(UUID.init(uuidString:)) }
        set { stateStore.setPaneStateValue(newValue?.uuidString, forKey: Keys.connectedPane) }
    }

    private func reconnect() {
        guard let connectedPaneID else { return applyConnectionState() }
        let terminal = tabPanes()
            .first { $0.nodeID == connectedPaneID }
            .flatMap { ($0.contentViewController as? TerminalPaneConnectable)?.connectableTerminal }
        session.connect(to: terminal)
        applyConnectionState()
    }

    private func applyConnectionState() {
        guard let chatView else { return }
        let connected = session.terminal != nil
        chatView.isComposerEnabled = connected
        chatView.composerPrompt = connected ? "$" : nil
        if connected {
            chatView.setStatus(nil, icon: nil)
        } else if connectedPaneID != nil {
            chatView.setStatus(
                "Its terminal isn't available — use Connect to Terminal… in this pane's Settings", icon: nil)
        } else {
            chatView.setStatus("Not connected — use Connect to Terminal… in this pane's Settings", icon: nil)
        }
    }

    /// Closes the Settings sheet and lets the user click the terminal to
    /// connect to.
    @objc private func connectPressed(_ sender: Any?) {
        (parent as? PaneViewController)?.dismissOptionsDialog()
        guard picker == nil, let window = view.window else { return }
        let picker = TerminalPanePicker(window: window) { [weak self] in
            self?.tabPanes() ?? []
        }
        picker.onPick = { [weak self] pane, terminal in
            guard let self else { return }
            self.connectedPaneID = pane.nodeID
            self.session.connect(to: terminal)
            self.applyConnectionState()
        }
        picker.onFinish = { [weak self] in self?.picker = nil }
        self.picker = picker
        // After the sheet has gone, so the panel is not put up behind it.
        DispatchQueue.main.async { picker.begin() }
    }

    private enum Keys {
        static let connectedPane = "connectedPane"
        static let legacyConnected = "connected"
        static let legacySubstitutions = "substitutions"
    }
}

extension TerminalChatViewController: PaneOptionsProviding {

    public func makePaneOptionRows() -> [NSView] {
        let connect = NSButton(title: "Connect to Terminal…", target: self, action: #selector(connectPressed(_:)))
        connect.bezelStyle = .rounded
        connect.setAccessibilityIdentifier("terminalChat.options.connect")
        return [connect]
    }
}

extension TerminalChatViewController: PaneContentTeardown {
    public func paneContentWillBeDiscarded() {
        picker?.cancel()
        if let directory, let listing { directory.remove(id: listing.id) }
        session.close()
    }
}
