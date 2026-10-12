import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// A chat pane that talks to a terminal pane: what is typed here is typed
/// there, and what the terminal prints comes back as replies.
///
/// Which terminal is the user's choice: the link beside the gear (or Connect
/// to Terminal… in the pane's Settings) puts up a ``TerminalPanePicker`` and
/// they click the one they mean. The link shows whether the chat is connected;
/// clicking it while connected offers to disconnect.
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
    private var connectableObserver: NSObjectProtocol?

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
        if let directory, let listing { directory.add(session, as: listing) }
        session.terminalDidExit = { [weak self] in self?.applyConnectionState() }
        // A terminal that starts after this chat appeared — a private one
        // waiting on its words — is connected to the moment it is there.
        connectableObserver = NotificationCenter.default.addObserver(
            forName: .terminalPaneConnectableDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.session.terminal == nil, self.isViewLoaded, self.view.window != nil else { return }
                self.reconnect()
            }
        }
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

    /// Re-makes the remembered connection, starting that pane's terminal if
    /// it has not started — a minimized pane never appears to start itself.
    private func reconnect() {
        guard let connectedPaneID,
              let pane = tabPanes().first(where: { $0.nodeID == connectedPaneID }),
              let connectable = pane.contentViewController as? TerminalPaneConnectable
        else { return applyConnectionState() }
        connect(toPane: pane, connectable)
    }

    /// Connects to `connectable`'s terminal, starting it first if need be, and
    /// remembers the pane.
    private func connect(toPane pane: ComposableTabsPaneViewController, _ connectable: TerminalPaneConnectable) {
        connectedPaneID = pane.nodeID
        if let terminal = connectable.connectableTerminal {
            session.connect(to: terminal)
            return applyConnectionState()
        }
        guard !isStarting else { return }
        isStarting = true
        applyConnectionState()
        Task { [weak self] in
            guard let self else { return }
            var choseAnother = false
            do {
                let terminal = try await connectable.startConnectableTerminal()
                choseAnother = self.connectedPaneID != pane.nodeID
                if !choseAnother { self.session.connect(to: terminal) }
            } catch {
                choseAnother = self.connectedPaneID != pane.nodeID
                if !choseAnother { self.startError = error.localizedDescription }
            }
            self.isStarting = false
            // The user chose another pane while this one started; that choice
            // was put off only because a start was in flight, so act on it now.
            if choseAnother { return self.reconnect() }
            self.applyConnectionState()
        }
    }

    /// A terminal is being started for this chat to connect to.
    private var isStarting = false
    /// Why the last start failed, shown until the next attempt.
    private var startError: String?

    private func applyConnectionState() {
        guard let chatView else { return }
        let connected = session.terminal != nil
        chatView.isComposerEnabled = connected
        chatView.composerPrompt = connected ? "$" : nil
        if connected {
            startError = nil
            chatView.setStatus(nil, icon: nil)
        } else if isStarting {
            chatView.setStatus("Starting the terminal…", icon: nil)
        } else if let startError {
            chatView.setStatus("The terminal could not start: \(startError)", icon: nil)
        } else if connectedPaneID != nil {
            chatView.setStatus("Its terminal isn't available yet — or click the link to choose another", icon: nil)
        } else {
            chatView.setStatus("Not connected — click the link to choose a terminal", icon: nil)
        }
        (parent as? PaneViewController)?.refreshAccessories()
    }

    /// The pane this chat is connected to, while it is in the tab.
    private var connectedPane: ComposableTabsPaneViewController? {
        guard let connectedPaneID else { return nil }
        return tabPanes().first { $0.nodeID == connectedPaneID }
    }

    @objc private func linkPressed(_ sender: Any?) {
        if session.terminal == nil { connectPressed(sender) } else { confirmDisconnect() }
    }

    /// Asks before letting go of the terminal: the chat's history stays, but
    /// nothing more is typed into or read from it.
    private func confirmDisconnect() {
        guard let window = view.window else { return }
        let alert = NSAlert()
        if let name = connectedPane?.resolvedTitle {
            alert.messageText = "Disconnect from \(name)?"
        } else {
            alert.messageText = "Disconnect from the terminal?"
        }
        alert.informativeText = "This chat stops typing into the terminal and reading what it prints."
        alert.addButton(withTitle: "Disconnect")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            MainActor.assumeIsolated { self?.disconnect() }
        }
    }

    private func disconnect() {
        connectedPaneID = nil
        session.connect(to: nil)
        applyConnectionState()
    }

    /// Closes the Settings sheet and lets the user click the terminal to
    /// connect to.
    @objc private func connectPressed(_ sender: Any?) {
        (parent as? PaneViewController)?.dismissOptionsDialog()
        guard picker == nil, let window = view.window else { return }
        let picker = TerminalPanePicker(window: window) { [weak self] in
            self?.tabPanes() ?? []
        }
        picker.onPick = { [weak self] pane, connectable in
            self?.connect(toPane: pane, connectable)
        }
        picker.onFinish = { [weak self] in self?.picker = nil }
        self.picker = picker
        // After the sheet has gone, so the panel is not put up behind it.
        DispatchQueue.main.async { picker.begin() }
    }

    private enum Keys {
        static let connectedPane = "connectedPane"
    }
}

extension TerminalChatViewController: PaneAccessoryProviding {

    /// The link beside the gear: whole while connected, broken while not.
    public func makePaneAccessoryViews() -> [NSView] {
        let connected = session.terminal != nil
        let title: String
        if connected {
            title = connectedPane.map { "Connected to \($0.resolvedTitle) — click to disconnect" }
                ?? "Connected — click to disconnect"
        } else {
            title = "Not connected — click to choose a terminal"
        }
        let button = NSButton(
            image: connected ? Self.linkedImage(description: title) : Self.unlinkedImage(description: title),
            target: self, action: #selector(linkPressed(_:)))
        button.isBordered = false
        button.toolTip = title
        button.setAccessibilityLabel(title)
        button.setAccessibilityValue(connected ? "connected" : "not connected")
        button.setAccessibilityIdentifier("terminalChat.link")
        return [button]
    }

    private static let linkConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)

    private static func linkedImage(description: String) -> NSImage {
        let image = NSImage(systemSymbolName: "link", accessibilityDescription: description) ?? NSImage()
        return image.withSymbolConfiguration(linkConfiguration) ?? image
    }

    /// SF Symbols has no broken link, so it is the link with a slash through
    /// it, drawn the way the system's own `.slash` variants are.
    private static func unlinkedImage(description: String) -> NSImage {
        let link = linkedImage(description: description)
        let size = link.size
        let image = NSImage(size: size, flipped: false) { rect in
            link.draw(in: rect)
            let slash = NSBezierPath()
            slash.move(to: NSPoint(x: rect.minX + 1, y: rect.maxY - 1))
            slash.line(to: NSPoint(x: rect.maxX - 1, y: rect.minY + 1))
            slash.lineWidth = 1.5
            slash.lineCapStyle = .round
            // The template is recoloured as a whole, so cut a gap beside the
            // slash first and the stroke reads apart from the link behind it.
            NSGraphicsContext.current?.compositingOperation = .clear
            slash.lineWidth = 4
            slash.stroke()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            slash.lineWidth = 1.5
            NSColor.black.setStroke()
            slash.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = description
        return image
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
        if let connectableObserver { NotificationCenter.default.removeObserver(connectableObserver) }
        if let directory, let listing { directory.remove(id: listing.id) }
        session.close()
    }
}
