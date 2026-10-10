import AppKit
import AgenticToolkitCore
import os

/// One project window of terminals over a fixed directory, for a host that is
/// a terminal and nothing else: no registry, no browser, no scan.
///
/// It is still an ordinary project window — `ProjectWindowManager` opens it,
/// so the tabs carry the same cards (session, directory, branch) and the panes
/// persist the same way as in any project window. What this feature adds is
/// the one `git_repo` row that window is keyed on, found by path and inserted
/// the first time, and the terminal-only layout every tab starts from.
///
/// The layout is process-wide (`ComposableTabsLayout.install`), so this feature
/// installs it in its initializer, before any window can load. A host that
/// also opens other kinds of project windows wants its own layout and should
/// not use this feature.
@MainActor
public final class TerminalWorkspaceCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "terminalWorkspace.action.showWindow"
    }

    private let database: ProjectDatabase
    private let windowManager: ProjectWindowManager
    private let directory: URL
    private let name: String

    /// - Parameters:
    ///   - database: Where the window keeps its tabs and layout.
    ///   - directory: The folder the workspace — and so every new shell —
    ///     starts in.
    ///   - name: The window's title, and the workspace row's name.
    ///   - commandRegistry: Required, as for every feature, so a dropped
    ///     registry is a compile error rather than a menu that lost an item.
    public init(
        database: ProjectDatabase,
        directory: URL = FileManager.default.homeDirectoryForCurrentUser,
        name: String,
        commandRegistry registry: CommandRegistry,
        windowManager: ProjectWindowManager = .shared
    ) throws {
        self.database = database
        self.windowManager = windowManager
        self.directory = directory
        self.name = name
        try ComposableTabsLayout.install(.terminalOnly())
        super.init()

        windowManager.attach(database: database)
        windowManager.commandRegistry = registry

        registry.register(AppCommand(
            id: CommandID.showWindow,
            title: "Terminal Window",
            category: "Terminal",
            run: { [weak self] in self?.showWindow() }
        ))
        menuContributions = [
            MenuContribution(
                slot: .window, title: "Terminal Window",
                commandID: CommandID.showWindow, registry: registry,
                order: 0, key: "1"
            )
        ]
    }

    /// Opens the workspace window, or brings it forward when it is open.
    public func showWindow() {
        do {
            windowManager.openProject(try workspaceRepo())
        } catch {
            Self.logger.error("Cannot open the terminal workspace: \(error)")
        }
    }

    /// Whether the workspace window is on screen — what a host's reopen
    /// handler asks before deciding to show it.
    public var isWindowOpen: Bool {
        guard let repo = try? database.repo(path: directory.path) else { return false }
        return windowManager.windowController(for: repo.id) != nil
    }

    /// The row the window is keyed on. Found by path rather than by a stored
    /// id, so the database is the only place that knows it (`dry`).
    private func workspaceRepo() throws -> GitRepo {
        if let existing = try database.repo(path: directory.path) {
            return existing
        }
        let repo = GitRepo(path: directory.path, name: name)
        try database.insert(repo)
        return repo
    }
}

extension TerminalWorkspaceCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
