import AppKit
import Combine
import KeyboardShortcuts
import os
import UniformTypeIdentifiers
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

    /// How long the partner's quit turn may run: three fifths of the app's flush budget (5 s gives 3 s), so
    /// its `stop()` and the features terminated after it still fit inside that budget.
    public static let quitTurnLimit = ApplicationShutdownCoordinator.defaultFlushBudget * 3 / 5

    typealias MakeController = @MainActor (
        _ store: PartnerStore, _ sessions: PartnerSessionRegistry, _ notifier: PartnerNotifier,
        _ paths: PartnerPaths, _ endpoint: @escaping @MainActor () -> PartnerController.Endpoint?
    ) -> PartnerController

    public let controller: PartnerController

    private let status: AutomationServerStatus
    private let settings: SettingsStore
    private let registerTools: @MainActor (any ChatToolSource) -> Void
    private let projects: @MainActor () -> [PartnerToolSource.Project]
    private let toolSource: PartnerToolSource
    /// The code-reviews job: the tools' service and the crawl run before each of its ticks.
    let reviews: ReviewService
    let codeReviewsScheduler: CodeReviewsScheduler
    /// Running reviews left by an earlier run are requeued once per process, by the process that holds the
    /// partner lock: another Debug copy's live reviews are not this process's to requeue.
    private var toolsRegistered = false
    private var subscriptions: Set<AnyCancellable> = []
    /// Starts and stops run one after another, never interleaved.
    private var lifecycleTask: Task<Void, Never>?
    /// The quit turn and the stop after it; `terminate()` may be awaited more than once.
    private var quitTask: Task<Void, Never>?
    private let quitLimit: Duration
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
                  detector: detector, settings: UserSettings.shared, quitLimit: Self.quitTurnLimit,
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
         settings: SettingsStore, quitLimit: Duration = PartnerCoordinator.quitTurnLimit,
         makeController: MakeController) {
        self.status = status
        self.settings = settings
        self.quitLimit = quitLimit
        self.registerTools = registerTools
        self.projects = projects
        let sessions = PartnerSessionRegistry(
            store: store, environment: { terminalEnvironment() },
            detector: detector ?? QuietPeriodDetector(settle: {
                TimeInterval(settings.get(UserSettings.partnerIdleSettleSeconds))
            }))
        let notifier = PartnerNotifier(store: store, settings: settings)
        controller = makeController(store, sessions, notifier, paths, {
            status.port.flatMap { port in status.token.map { PartnerController.Endpoint(port: port, token: $0) } }
        })
        reviews = ReviewService(store: store, sessions: sessions, notifier: notifier, paths: paths,
                                settings: settings, steps: { Self.codeReviewSteps(store: store) })
        codeReviewsScheduler = CodeReviewsScheduler(store: store, projects: projects, settings: settings)
        let scheduler = codeReviewsScheduler
        controller.tickPreparers[PartnerJobDefaults.codeReviewsID] = { await scheduler.crawlAndSummarise() }
        let box = callerIDBox
        toolSource = PartnerToolSource(callerID: { box.value }, store: store, sessions: sessions,
                                       projects: projects, notifier: notifier, reviews: reviews)
        super.init()
        featureName = "Coding Partner"
        // On every start, once this process holds the lock and before its first tick lists the queue: a
        // restart may begin a fresh conversation, which cannot see the reviews the old one left running.
        controller.onLockAcquired = { [weak self] in self?.requeueInterruptedReviews() }

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
            // Neither call activates the Kitchen.
            switch Self.referenceAction(reference) {
            case .open(let url): NSWorkspace.shared.open(url)
            case .reveal(let url): NSWorkspace.shared.activateFileViewerSelecting([url])
            case .ignore(let reason):
                Self.logger.notice("Ignored an attention reference: \(reason, privacy: .public)")
            }
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
        settings.changes
            .receive(on: DispatchQueue.main)
            .filter { $0 == UserSettings.partnerReviewsCrawlIntervalMinutes.name }
            .sink { [weak self] _ in self?.applyCrawlInterval() }
            .store(in: &subscriptions)
        // A job write (Reset to default, a schedule typed on the Jobs tab) is brought back to the setting.
        // The rewrite is itself a jobs change, which finds the schedule already right and stops.
        controller.store.changes
            .receive(on: DispatchQueue.main)
            .filter { $0 == .jobs }
            .sink { [weak self] _ in
                self?.applyCrawlInterval()
                // Any other enable, disable or schedule edit reaches the running timers too.
                self?.controller.syncSchedules()
            }
            .store(in: &subscriptions)
        applyCrawlInterval()
        // The endpoint binds after every feature has started, so an enabled partner waits for it.
        status.$port
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reconcile() }
            .store(in: &subscriptions)
        status.$failureReason
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

    /// Sends the quit turn, waits at most ``quitTurnLimit`` for it, then stops the partner either way, and
    /// closes every open session so its final screen is stored before the shells die with the app.
    ///
    /// The host terminates the partner before the automation endpoint, so the turn's `partner_*` calls
    /// still reach it. A start or stop still queued is cancelled rather than awaited: the controller's
    /// `stop()` overtakes a launch in flight, and waiting for one would spend the budget.
    public override func terminate() async {
        if quitTask == nil {
            lifecycleTask?.cancel()
            let controller = controller
            let limit = quitLimit
            quitTask = Task { @MainActor in
                await controller.prepareForQuit(waitingAtMost: limit)
                _ = controller.sessions.closeAll()
            }
        }
        await quitTask?.value
    }

    public func settingsPanel() -> ComposableSettings.SectionTabsPanel {
        PartnerSettingsPanel.make(controller: controller, projects: projects)
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

    /// What clicking an attention item's reference does.
    enum ReferenceAction: Equatable {
        /// Hand it to its default app.
        case open(URL)
        /// Show it selected in Finder, unopened.
        case reveal(URL)
        /// Do nothing; the reason is logged.
        case ignore(String)
    }

    /// Types a click may hand to their default app: documents that app shows rather than runs.
    static let showableTypes: [UTType] = [.text, .image, .pdf, .sourceCode]
    /// Types refused even when they are also showable: a script is source code and text too, and a
    /// configuration profile is XML that installs.
    static let launchingTypes: [UTType] = [.script, .executable, .applicationBundle, .package, .bundle]
    static let launchingIdentifiers: Set<String> = ["com.apple.mobileconfig", "com.apple.configprofile"]

    /// Whether a file with extension `pathExtension` is a type that only shows when opened. An unknown
    /// extension (a dynamic type) is not.
    static func opensAsDocument(pathExtension: String) -> Bool {
        guard !pathExtension.isEmpty, let type = UTType(filenameExtension: pathExtension) else { return false }
        return showableTypes.contains { type.conforms(to: $0) }
            && !launchingTypes.contains { type.conforms(to: $0) }
            && !launchingIdentifiers.contains(type.identifier)
    }

    /// References come from the partner's tool calls, which text in any repo or session it reads can steer,
    /// so only what is safe to open on one click is opened.
    ///
    /// - An http(s) `url` opens. Any other scheme (`file:` spelled as a URL, `javascript:`, a custom scheme)
    ///   is ignored; a `path` beside it is still judged on its own.
    /// - An absolute `path` (after `~` expansion) that resolves, through symlinks, to a regular file that is
    ///   not executable, not a package and whose type is showable (``opensAsDocument(pathExtension:)``)
    ///   under both its own and its target's extension opens.
    /// - Any other existing path is revealed in Finder. A relative or missing path is ignored.
    static func referenceAction(_ reference: [String: String],
                                fileManager: FileManager = .default) -> ReferenceAction {
        var reasons: [String] = []
        if let text = reference["url"] {
            if let url = URL(string: text), let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https", url.host?.isEmpty == false {
                return .open(url)
            }
            reasons.append("url with scheme \(URL(string: text)?.scheme ?? "none") is not http(s)")
        }
        if let path = reference["path"], !path.isEmpty {
            let expanded = (path as NSString).expandingTildeInPath
            guard expanded.hasPrefix("/") else { return .ignore("path \(path) is not absolute") }
            let url = URL(fileURLWithPath: expanded).standardizedFileURL
            let resolved = url.resolvingSymlinksInPath()
            guard let attributes = try? fileManager.attributesOfItem(atPath: resolved.path) else {
                return .ignore("path \(path) does not exist")
            }
            let isRegular = attributes[.type] as? FileAttributeType == .typeRegular
            let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue ?? 0o777
            let opens = isRegular
                && permissions & 0o111 == 0
                && opensAsDocument(pathExtension: resolved.pathExtension)
                && opensAsDocument(pathExtension: url.pathExtension)
                && !NSWorkspace.shared.isFilePackage(atPath: resolved.path)
            return opens ? .open(resolved) : .reveal(url)
        }
        return .ignore(reasons.isEmpty ? "no url or path" : reasons.joined(separator: "; "))
    }

    // MARK: - Code reviews

    /// The stored code-reviews job's steps (the owner may have edited them), else the shipped ones.
    private static func codeReviewSteps(store: PartnerStore) -> [PartnerJobStep] {
        do {
            if let job = try store.jobs().first(where: { $0.id == PartnerJobDefaults.codeReviewsID }) {
                return job.steps
            }
        } catch {
            logger.error("Reading the code-reviews job failed: \(error.localizedDescription, privacy: .public)")
        }
        return PartnerJobDefaults.codeReviews().steps
    }

    /// The code-reviews job's schedule follows ``UserSettings/partnerReviewsCrawlIntervalMinutes``: the stored
    /// job is rewritten and its timer restarted. Internal for tests.
    func applyCrawlInterval() {
        let seconds = max(settings.get(UserSettings.partnerReviewsCrawlIntervalMinutes), 1) * 60
        // `jobs()` seeds the job when it has never been stored, so the first change still lands.
        guard var job = controller.jobs().first(where: { $0.id == PartnerJobDefaults.codeReviewsID }),
              job.scheduleSeconds != seconds else { return }
        job.scheduleSeconds = seconds
        do {
            try controller.store.upsert(job)
        } catch {
            Self.logger.error(
                "Saving the code-reviews schedule failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        controller.restartSchedule(jobID: job.id)
    }

    /// A review left `running` with no open session (the app quit, or the session closed) goes back to the
    /// queue.
    private func requeueInterruptedReviews() {
        do {
            let count = try reviews.requeueInterrupted()
            if count > 0 { Self.logger.notice("Requeued \(count) interrupted reviews") }
        } catch {
            Self.logger.error("Requeueing interrupted reviews failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Run state

    /// Starts the partner when it is enabled and the endpoint is up; stops it when it is disabled.
    private func reconcile() {
        // Once the quit has begun, the partner stays stopped whatever the setting says.
        guard quitTask == nil else { return }
        let enabled = settings.get(UserSettings.partnerEnabled)
        let previous = lifecycleTask
        let controller = controller
        let status = status
        lifecycleTask = Task { @MainActor in
            await previous?.value
            // Cancelled by `terminate()`: nothing may start after the quit.
            guard !Task.isCancelled else { return }
            if enabled {
                guard status.port != nil, status.token != nil else {
                    controller.reportWaitingForEndpoint(status.failureReason)
                    return
                }
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
