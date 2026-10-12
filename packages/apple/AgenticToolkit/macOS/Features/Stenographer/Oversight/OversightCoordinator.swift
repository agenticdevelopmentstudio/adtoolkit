import AppKit
import KeyboardShortcuts
import OSLog
import AgenticToolkitCore

/// The AI Oversight window as an app feature: a Window-menu item and a
/// status-item entry that open the findings and scripts of stenographerd's
/// oversight observers. Starting it also installs the oversight preference push.
@MainActor
public final class OversightCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "stenographer.oversight.showWindow"
    }

    /// The window's stable id — what Stenographer's scripting called it — and
    /// the key its key command's binding is stored under (`window.ai-oversight`).
    public static let windowID = "ai-oversight"

    /// The system-wide key command that opens this window. The host installs
    /// it through `StenographerWindowKeyCommands.install(commands:)`.
    public func keyCommand() -> KeyCommandDescriptor {
        StenographerWindowKeyCommands.descriptor(
            windowID: Self.windowID, title: "AI Oversight",
            defaultShortcut: nil,
            present: { [weak self] in self?.showWindow() })
    }

    private let service: any StenographerDaemonService

    public init(service: any StenographerDaemonService, commandRegistry: CommandRegistry) {
        self.service = service
        super.init()
        featureName = "AI Oversight"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "AI Oversight", category: "Stenographer",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .window, title: "AI Oversight", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 60, key: ""),
            MenuContribution(slot: .statusItem(section: 1), title: "AI Oversight", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 50)
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        OversightFindingsWindowController.ensureCurrent(service: service)
        StenographerOversightPrefsPush.startObserving(service: service)
    }

    public func showWindow() {
        OversightFindingsWindowController.present(service: service)
    }

    /// The AI Oversight settings pane, for the host's settings window.
    public func settingsPanel() -> AIOversightSettingsPanel {
        AIOversightSettingsPanel(service: service)
    }
}

extension OversightCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
