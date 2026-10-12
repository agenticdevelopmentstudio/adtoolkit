import AppKit
import OSLog
import AgenticToolkitCore

/// The Conversations window as an app feature: a Window-menu item and a status-item
/// entry that open every observed session's dialogue on one timeline.
@MainActor
public final class ConversationsCoordinator: AppFeature {

    public enum CommandID {
        public static let showWindow = "stenographer.conversations.showWindow"
    }

    private let service: any StenographerDaemonService

    public init(service: any StenographerDaemonService, commandRegistry: CommandRegistry) {
        self.service = service
        super.init()
        featureName = "Conversations"
        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "Conversations", category: "Stenographer",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .window, title: "Conversations", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 50, key: ""),
            MenuContribution(slot: .statusItem(section: 1), title: "Conversations", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 40)
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        ConversationsWindowController.ensureCurrent(service: service)
    }

    public func showWindow() {
        ConversationsWindowController.present(service: service)
    }
}

extension ConversationsCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
