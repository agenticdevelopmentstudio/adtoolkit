import AppKit
import AgenticToolkitCore

extension ComposableTabsViewID {
    /// A pane holding one live shell. The raw value is what persisted
    /// `layout_nodes` rows already name, so it must not change.
    public static let terminal = ComposableTabsViewID("terminal")
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
}

extension ComposableTabsLayout {

    /// A layout with terminals and nothing else: one to start, as many more as
    /// the user splits off.
    @MainActor
    public static func terminalOnly() throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        registry.registerTerminal(preferredAxis: .horizontal)
        return try ComposableTabsLayout(
            registry: registry,
            spec: .split(
                axis: .horizontal,
                children: [.pane(.terminal)],
                allows: [
                    .unbounded(.terminal, preferredAxis: .horizontal),
                    .unbounded(.placeholder)
                ]
            )
        )
    }
}
