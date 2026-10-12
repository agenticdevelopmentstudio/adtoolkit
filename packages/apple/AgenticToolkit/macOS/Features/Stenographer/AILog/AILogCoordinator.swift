import AppKit
import KeyboardShortcuts
import OSLog
import AgenticToolkitCore

/// The AI Log window as an app feature: a Window-menu item and a status-item
/// entry that open the record of every LLM call stenographerd made.
@MainActor
public final class AILogCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "stenographer.ailog.showWindow"
    }

    /// The window's stable id — what Stenographer's scripting called it — and
    /// the key its key command's binding is stored under (`window.ai-log`).
    public static let windowID = "ai-log"

    /// The system-wide key command that opens this window. The host installs
    /// it through `StenographerWindowKeyCommands.install(commands:)`.
    public func keyCommand() -> KeyCommandDescriptor {
        StenographerWindowKeyCommands.descriptor(
            windowID: Self.windowID, title: "AI Log",
            defaultShortcut: nil,
            present: { [weak self] in self?.showWindow() })
    }

    private let service: any StenographerDaemonService

    public init(service: any StenographerDaemonService, commandRegistry: CommandRegistry) {
        self.service = service
        super.init()
        featureName = "AI Log"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "AI Log", category: "Stenographer",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .window, title: "AI Log", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 70, key: ""),
            MenuContribution(slot: .statusItem(section: 1), title: "AI Log", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 60)
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        AILogWindowController.ensureCurrent(service: service)
    }

    public func showWindow() {
        AILogWindowController.present(service: service)
    }
}

extension AILogCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
