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

    /// Registers the terminal chat pane: a chat whose messages are typed into
    /// the tab's terminal and whose replies are what that terminal prints,
    /// passed through the pane's substitutions each way.
    @MainActor
    public func registerTerminalChat() {
        register(
            .terminalChat,
            descriptor: .init(
                displayName: "Terminal Chat",
                symbolName: "bubble.left.and.text.bubble.right",
                preferredAxis: .horizontal,
                minimumThickness: 260
            )
        ) { context in
            TerminalChatViewController(stateStore: context.makeStateStore(prefix: "terminalChat"))
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
    /// - Parameter pluginManager: The LLM providers a persona chat runs on;
    ///   without one, the persona terminal chat pane is not offered.
    @MainActor
    public static func terminalOnly(pluginManager: AIPluginManager? = nil) throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        registry.registerTerminal(preferredAxis: .horizontal)
        registry.registerTerminalChat()
        var allows: [ComposableTabsViewAllowance] = [
            .unbounded(.terminal, preferredAxis: .horizontal),
            .unbounded(.terminalChat),
            .unbounded(.placeholder)
        ]
        if let pluginManager {
            registry.registerPersonaTerminalChat(pluginManager: pluginManager)
            allows.insert(.unbounded(.personaTerminalChat), at: 2)
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
