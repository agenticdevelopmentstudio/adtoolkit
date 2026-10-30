import AppKit
import KeyboardShortcuts

/// A project window's bindable key commands: one per shelf panel, each showing
/// the shelf on that panel with the keyboard in its filter, or hiding it when
/// that panel is already up.
///
/// Like `ConversationsKeyCommands`, the window is resolved when the command
/// runs — the key window, if it carries a project shelf — so the section can be
/// declared at launch, before any project window exists.
@MainActor
public enum ProjectWindowKeyCommands {

    public static let toggleBrowserID = "projects.toggleBrowser"
    public static let toggleActiveProjectsID = "projects.toggleActiveProjects"

    public static let sectionTitle = "Project Window"

    public static func section() -> KeyCommandSection {
        KeyCommandSection(
            title: sectionTitle,
            scope: .app,
            // Each command declines unless a project window is key, so ⌘0 may
            // also be the Conversations window's list.
            isWindowSpecific: true,
            commands: [
                KeyCommandDescriptor(
                    id: toggleBrowserID,
                    title: "Show Project Browser",
                    defaultShortcut: KeyboardShortcuts.Shortcut(.zero, modifiers: .command),
                    perform: { toggle(.browser) }
                ),
                KeyCommandDescriptor(
                    id: toggleActiveProjectsID,
                    title: "Show Active Projects",
                    defaultShortcut: KeyboardShortcuts.Shortcut(.one, modifiers: .command),
                    perform: { toggle(.activeProjects) }
                )
            ])
    }

    private static func toggle(_ panel: ProjectShelfPanel) -> Bool {
        let target = KeyCommandRegistry.shared.commandWindow
        guard let window = target?.windowController as? ProjectShelfWindow else {
            // Declining is normal — another window's command may share the
            // chord — but a chord that silently does nothing is the hardest
            // thing to debug, so say which window had the keyboard.
            let title = target?.title ?? "none"
            ProjectsCoordinator.logger.debug(
                "\(panel.rawValue, privacy: .public) toggle declined: key window is \(title, privacy: .public)")
            return false
        }
        window.toggleShelfPanel(panel)
        return true
    }
}
