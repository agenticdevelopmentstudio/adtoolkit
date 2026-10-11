import AppKit
import AgenticToolkitCore

/// Install and Uninstall items in the app menu for a command-line tool the
/// app ships in its bundle — the way an editor offers to put its command on
/// the PATH. Only the one that applies is shown.
@MainActor
public final class CommandLineToolFeature: AppFeature {

    private let link: CommandLineToolLink

    public init(link: CommandLineToolLink, commandRegistry registry: CommandRegistry) {
        self.link = link
        super.init()

        let installID = "commandLineTool.\(link.name).install"
        let uninstallID = "commandLineTool.\(link.name).uninstall"
        registry.register(AppCommand(
            id: installID, title: "Install '\(link.name)' Command", category: "App",
            run: { [weak self] in self?.install() }
        ))
        registry.register(AppCommand(
            id: uninstallID, title: "Uninstall '\(link.name)' Command", category: "App",
            run: { [weak self] in self?.uninstall() }
        ))
        menuContributions = [
            MenuContribution(
                slot: .app, title: "Install '\(link.name)' Command…",
                commandID: installID, registry: registry, order: 100,
                isHidden: { link.state == .installed }
            ),
            MenuContribution(
                slot: .app, title: "Uninstall '\(link.name)' Command",
                commandID: uninstallID, registry: registry, order: 101,
                isHidden: { link.state != .installed }
            )
        ]
    }

    private func install() {
        let replaced: String? = if case .linkedElsewhere(let old) = link.state { old } else { nil }
        do {
            try link.install()
            var detail = "\(link.linkURL.path) now runs \(link.tool.path)."
            if let replaced { detail += "\n\nIt replaced a link to \(replaced)." }
            detail += "\n\n\(link.directory.path) has to be on your PATH for the command to be found."
            report("'\(link.name)' is installed", detail, style: .informational)
        } catch {
            report("Could not install '\(link.name)'", error.localizedDescription, style: .warning)
        }
    }

    private func uninstall() {
        do {
            try link.uninstall()
            report("'\(link.name)' is uninstalled", "\(link.linkURL.path) was removed.", style: .informational)
        } catch {
            report("Could not uninstall '\(link.name)'", error.localizedDescription, style: .warning)
        }
    }

    private func report(_ title: String, _ detail: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.alertStyle = style
        alert.runModal()
    }
}
