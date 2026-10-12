import AppKit
import OSLog
import AgenticToolkitCore

/// The Sessions window as an app feature: a Window-menu item and a status-item
/// entry that open the live list of Claude Code sessions stenographerd knows.
@MainActor
public final class SessionsCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "stenographer.sessions.showWindow"
    }

    private let service: any StenographerDaemonService

    public init(service: any StenographerDaemonService, commandRegistry: CommandRegistry) {
        self.service = service
        super.init()
        featureName = "Sessions"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "Sessions", category: "Stenographer",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .window, title: "Sessions", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 40, key: ""),
            MenuContribution(slot: .statusItem(section: 1), title: "Sessions", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 30)
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        SessionsWindowController.ensureCurrent(service: service)
        StenographerSummaryPrefsPush.startObserving(service: service)
    }

    /// The AI Summaries settings pane, for the host's settings window.
    public func settingsPanel() -> AISummariesSettingsPanel {
        AISummariesSettingsPanel(service: service)
    }

    public func showWindow() {
        SessionsWindowController.present(service: service)
    }
}

extension SessionsCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
