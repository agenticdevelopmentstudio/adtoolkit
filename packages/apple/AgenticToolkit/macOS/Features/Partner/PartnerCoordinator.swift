import AppKit
import Combine
import KeyboardShortcuts
import os
import AgenticToolkitCore

/// The Coding Partner as an app feature: its controller, its `partner_*` tools on
/// the app's MCP endpoint, the Window-menu item and key command for its window,
/// and its settings pane.
///
/// Runs the partner while ``UserSettings/partnerEnabled`` is on and the
/// automation endpoint is listening, and stops it when the setting goes off.
/// The host supplies the endpoint's status, what a terminal pane exports, how a
/// tool source reaches the MCP server, and the Projects registry.
@MainActor
public final class PartnerCoordinator: AppFeature {

    public static let windowID = PartnerWindowController.windowID

    public enum CommandID {
        public static let showWindow = "partner.showWindow"
    }

    typealias MakeController = @MainActor (
        _ store: PartnerStore, _ sessions: PartnerSessionRegistry, _ notifier: PartnerNotifier,
        _ paths: PartnerPaths, _ endpoint: @escaping @MainActor () -> PartnerController.Endpoint?
    ) -> PartnerController

    public let controller: PartnerController

    private let status: AutomationServerStatus
    private let settings: SettingsStore
    private let registerTools: @MainActor (any ChatToolSource) -> Void
    private let toolSource: PartnerToolSource
    private var toolsRegistered = false
    private var subscriptions: Set<AnyCancellable> = []
    /// Starts and stops run one after another, never interleaved.
    private var lifecycleTask: Task<Void, Never>?
    /// The partner's pane id, readable off the main actor by the tool source.
    private let callerIDBox = CallerIDBox()

    /// - Parameter detector: How the partner learns a session went idle or exited. `nil` uses
    ///   ``QuietPeriodDetector`` alone, settling after ``UserSettings/partnerIdleSettleSeconds``.
    public convenience init(store: PartnerStore, paths: PartnerPaths, status: AutomationServerStatus,
                            terminalEnvironment: @escaping @MainActor () -> [String: String],
                            registerTools: @escaping @MainActor (any ChatToolSource) -> Void,
                            projects: @escaping @MainActor () -> [PartnerToolSource.Project],
                            commandRegistry: CommandRegistry, detector: (any PartnerSessionEventDetecting)? = nil) {
        self.init(store: store, paths: paths, status: status, terminalEnvironment: terminalEnvironment,
                  registerTools: registerTools, projects: projects, commandRegistry: commandRegistry,
                  detector: detector, settings: UserSettings.shared,
                  makeController: { store, sessions, notifier, paths, endpoint in
                      PartnerController(store: store, sessions: sessions, notifier: notifier, paths: paths,
                                        endpoint: endpoint)
                  })
    }

    init(store: PartnerStore, paths: PartnerPaths, status: AutomationServerStatus,
         terminalEnvironment: @escaping @MainActor () -> [String: String],
         registerTools: @escaping @MainActor (any ChatToolSource) -> Void,
         projects: @escaping @MainActor () -> [PartnerToolSource.Project],
         commandRegistry: CommandRegistry, detector: (any PartnerSessionEventDetecting)?,
         settings: SettingsStore, makeController: MakeController) {
        self.status = status
        self.settings = settings
        self.registerTools = registerTools
        let sessions = PartnerSessionRegistry(
            store: store, environment: { terminalEnvironment() },
            detector: detector ?? QuietPeriodDetector(settle: {
                TimeInterval(settings.get(UserSettings.partnerIdleSettleSeconds))
            }))
        let notifier = PartnerNotifier(store: store, settings: settings)
        controller = makeController(store, sessions, notifier, paths, {
            status.port.flatMap { port in status.token.map { PartnerController.Endpoint(port: port, token: $0) } }
        })
        let box = callerIDBox
        toolSource = PartnerToolSource(callerID: { box.value }, store: store, sessions: sessions,
                                       projects: projects, notifier: notifier)
        super.init()
        featureName = "Coding Partner"

        commandRegistry.register(AppCommand(
            id: CommandID.showWindow, title: "Coding Partner", category: "Coding Partner",
            run: { [weak self] in self?.showWindow() }))
        menuContributions = [
            MenuContribution(slot: .window, title: "Coding Partner", commandID: CommandID.showWindow,
                             registry: commandRegistry, order: 55, key: "")
        ]
    }

    public override func start() throws {
        // Registered unopened so the toolkit's restore-on-launch can reopen it.
        PartnerWindowController.ensureCurrent(controller: controller)
        PartnerWindowController.current?.splitViewController.onOpenReference = { reference in
            guard let url = Self.referenceURL(reference) else { return }
            // `open` hands the URL to its app without activating the Kitchen.
            NSWorkspace.shared.open(url)
        }
        startServices()
    }

    /// Everything `start()` does but the window: the tools, once, and the partner's run state from then on.
    func startServices() {
        if !toolsRegistered {
            toolsRegistered = true
            registerTools(toolSource)
        }
        guard subscriptions.isEmpty else { return }
        let box = callerIDBox
        // `callerID` is set before the state leaves `.starting` and cleared before it reaches `.stopped`.
        controller.$state
            .sink { [weak controller] _ in box.value = controller?.callerID }
            .store(in: &subscriptions)
        settings.changes
            // Main first: the filter closure is main-actor isolated, and a setting may be written off it.
            .receive(on: DispatchQueue.main)
            .filter { $0 == UserSettings.partnerEnabled.name }
            .sink { [weak self] _ in self?.reconcile() }
            .store(in: &subscriptions)
        // The endpoint binds after every feature has started, so an enabled partner waits for it.
        status.$port
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reconcile() }
            .store(in: &subscriptions)
        reconcile()
    }

    public override func stop() {
        subscriptions.removeAll()
    }

    public override func terminate() async {
        await lifecycleTask?.value
        await controller.prepareForQuit()
    }

    public func settingsPanel() -> ComposableSettings.SectionTabsPanel {
        PartnerSettingsPanel.make(controller: controller)
    }

    /// The system-wide key command that opens the window. Ships switched off.
    public func keyCommand() -> KeyCommandDescriptor {
        StenographerWindowKeyCommands.descriptor(
            windowID: Self.windowID, title: "Coding Partner", defaultShortcut: nil,
            present: { [weak self] in self?.showWindow() })
    }

    public func showWindow() {
        PartnerWindowController.present(controller: controller)
    }

    /// What an attention item's reference opens: its http(s) `url`, else its `path` as a file.
    static func referenceURL(_ reference: [String: String]) -> URL? {
        if let text = reference["url"], let url = URL(string: text),
           let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return url
        }
        if let path = reference["path"], !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        }
        return nil
    }

    // MARK: - Run state

    /// Starts the partner when it is enabled and the endpoint is up; stops it when it is disabled.
    private func reconcile() {
        let enabled = settings.get(UserSettings.partnerEnabled)
        let previous = lifecycleTask
        let controller = controller
        let status = status
        lifecycleTask = Task { @MainActor in
            await previous?.value
            if enabled {
                guard status.port != nil, status.token != nil else { return }
                switch controller.state {
                case .stopped, .failed: await controller.start()
                case .starting, .idle, .thinking: break
                }
            } else if controller.state != .stopped {
                await controller.stop()
            }
        }
    }
}

/// The partner's pane id, set on the main actor and read by MCP calls on any thread.
private final class CallerIDBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: String?
    var value: String? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

extension PartnerCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
