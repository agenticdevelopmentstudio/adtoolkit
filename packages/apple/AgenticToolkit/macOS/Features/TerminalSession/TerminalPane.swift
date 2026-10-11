import AppKit
import AIPluginKit
import AgenticToolkitCore

extension ComposableTabsViewID {
    /// A pane holding one live shell. The raw value is what persisted
    /// `layout_nodes` rows already name, so it must not change.
    public static let terminal = ComposableTabsViewID("terminal")
    /// A chat pane that types into the terminal beside it — see
    /// `TerminalChatViewController`.
    public static let terminalChat = ComposableTabsViewID("terminal-chat")
    /// A chat with an AI persona that works the terminal through the tab's
    /// Terminal Chat — see `PersonaTerminalChatViewController`.
    public static let personaTerminalChat = ComposableTabsViewID("persona-terminal-chat")
    /// A terminal behind privacy words and a privacy screen — see
    /// `PrivateTerminalViewController`.
    public static let privateTerminal = ComposableTabsViewID("private-terminal")
}

extension ComposableTabsViewRegistry {

    /// Registers the terminal pane: one shell, opened in the pane's working
    /// directory, with no session list — in a project window the tab already
    /// carries the directory and branch that list would identify a shell by.
    ///
    /// - Parameter preferredAxis: Which way the Split menu proposes adding
    ///   another terminal. A host stacking terminals beside other panes wants
    ///   `.vertical`; a terminal-only window wants them side by side.
    @MainActor
    public func registerTerminal(preferredAxis: ComposableTabsAxis) {
        register(
            .terminal,
            descriptor: .init(
                displayName: "Terminal",
                symbolName: "terminal",
                preferredAxis: preferredAxis,
                // Just the terminal grid: wide enough that an ordinary command
                // line and its output don't wrap.
                minimumThickness: 300
            )
        ) { context in
            let manager = TerminalSessionManager(workingDirectory: context.workingDirectory.path)
            // The pane opens on a live shell; an empty pane is a dead end the
            // user would have to click out of every time.
            manager.addSession()
            return TerminalSessionContentViewController(sessionManager: manager)
        }
    }

    /// Registers the private terminal pane: one shell behind `vault`'s privacy
    /// words, under a privacy screen until the user authenticates.
    @MainActor
    public func registerPrivateTerminal(vault: PrivacyWordsVault, preferredAxis: ComposableTabsAxis) {
        register(
            .privateTerminal,
            descriptor: .init(
                displayName: "Private Terminal",
                symbolName: "eye.slash",
                preferredAxis: preferredAxis,
                minimumThickness: 300
            )
        ) { context in
            PrivateTerminalViewController(vault: vault, workingDirectory: context.workingDirectory.path)
        }
    }

    /// Registers the terminal chat pane: a chat whose messages are typed into
    /// the terminal pane it is connected to and whose replies are what that
    /// terminal prints.
    ///
    /// - Parameter directory: Where each chat lists itself for processes
    ///   outside the app to drive (`TerminalChatControlServer`); nil keeps
    ///   them private to the window.
    @MainActor
    public func registerTerminalChat(directory: TerminalChatDirectory? = nil) {
        register(
            .terminalChat,
            descriptor: .init(
                displayName: "Terminal Chat",
                symbolName: "bubble.left.and.text.bubble.right",
                preferredAxis: .horizontal,
                minimumThickness: 260
            )
        ) { context in
            TerminalChatViewController(
                stateStore: context.makeStateStore(prefix: "terminalChat"),
                directory: directory,
                listing: TerminalChatDirectory.Listing(
                    id: TerminalChatDirectory.chatID(forNode: context.nodeID),
                    project: context.project.displayName,
                    directory: context.workingDirectory,
                    paneNumber: context.paneNumber))
        }
    }

    /// Registers the persona terminal chat pane: an AI persona, on one of the
    /// LLM providers configured in Settings, that runs commands through the
    /// tab's Terminal Chat.
    @MainActor
    public func registerPersonaTerminalChat(pluginManager: AIPluginManager) {
        register(
            .personaTerminalChat,
            descriptor: .init(
                displayName: "Persona Terminal Chat",
                symbolName: "person.crop.circle.badge.questionmark",
                preferredAxis: .horizontal,
                minimumThickness: 260
            )
        ) { context in
            PersonaTerminalChatViewController(
                stateStore: context.makeStateStore(prefix: "personaTerminalChat"),
                pluginManager: pluginManager)
        }
    }
}

extension ComposableTabsLayout {

    /// A layout of terminals: one to start, as many more as the user splits
    /// off, and chat panes that talk to them.
    ///
    /// - Parameters:
    ///   - pluginManager: The LLM providers a persona chat runs on; without
    ///     one, the persona terminal chat pane is not offered.
    ///   - chatDirectory: Where Terminal Chats list themselves for outside
    ///     processes to drive; nil keeps them private to the window.
    ///   - privacyVault: The privacy words private terminals run behind;
    ///     without one, the private terminal pane is not offered.
    @MainActor
    public static func terminalOnly(
        pluginManager: AIPluginManager? = nil,
        chatDirectory: TerminalChatDirectory? = nil,
        privacyVault: PrivacyWordsVault? = nil
    ) throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        registry.registerTerminal(preferredAxis: .horizontal)
        registry.registerTerminalChat(directory: chatDirectory)
        var allows: [ComposableTabsViewAllowance] = [
            .unbounded(.terminal, preferredAxis: .horizontal),
            .unbounded(.terminalChat),
            .unbounded(.placeholder)
        ]
        if let privacyVault {
            registry.registerPrivateTerminal(vault: privacyVault, preferredAxis: .horizontal)
            allows.insert(.unbounded(.privateTerminal, preferredAxis: .horizontal), at: 1)
        }
        if let pluginManager {
            registry.registerPersonaTerminalChat(pluginManager: pluginManager)
            allows.insert(.unbounded(.personaTerminalChat), at: allows.count - 1)
        }
        return try ComposableTabsLayout(
            registry: registry,
            spec: .split(
                axis: .horizontal,
                children: [.pane(.terminal)],
                allows: allows
            )
        )
    }
}
