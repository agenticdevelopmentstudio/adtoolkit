import Combine
import Foundation
import AgenticToolkitCore
import os

/// Runs the coding partner: one long-lived `claude` process fed one turn at a time.
///
/// Owns the partner's lifecycle (the live lock, the files claude reads, the
/// process and its reader), the queue of inbound events, the turn timeout, and
/// the owner's buttons on attention items. Turns are in
/// `PartnerController+Turns.swift`, the buttons in `PartnerController+Attention.swift`.
@MainActor
public final class PartnerController: ObservableObject {

    public enum State: Equatable, Sendable { case stopped, starting, idle, thinking, failed(String) }

    /// The app's MCP endpoint the partner's claude calls back into.
    public struct Endpoint: Sendable, Equatable {
        public var port: UInt16
        public var token: String

        public init(port: UInt16, token: String) {
            self.port = port
            self.token = token
        }
    }

    public enum ControllerError: Error, Equatable {
        case unknownItem(String)
        case unsupportedAction(AttentionActionKind)
    }

    @Published public private(set) var state: State = .stopped
    @Published public private(set) var queuedCount: Int = 0

    public let store: PartnerStore
    public let sessions: PartnerSessionRegistry
    public let notifier: PartnerNotifier
    public let chatSession: PartnerChatSession

    /// The pane id the partner's MCP calls carry; only calls with it may use the partner tools.
    public private(set) var callerID: String?

    /// jobID → summary appended to that job's tick. Awaited before the tick is queued.
    public var tickPreparers: [String: @MainActor () async -> String?] = [:]

    let paths: PartnerPaths
    let endpoint: @MainActor () -> Endpoint?
    let findClaude: () -> String?
    let makeProcess: @Sendable (PartnerProcessConfiguration, [String: String]) -> any PartnerProcessing
    let settings: SettingsStore
    let turnTimeout: (() -> Duration)?
    let pid: Int32
    let isPIDAlive: (Int32) -> Bool
    let now: () -> Date

    // Turn machinery, shared with the extensions.
    var queue = PartnerTurnQueue()
    var process: (any PartnerProcessing)?
    var configuration: PartnerProcessConfiguration?
    var environment: [String: String] = [:]
    var readerTask: Task<Void, Never>?
    var timeoutTask: Task<Void, Never>?
    /// Bumped whenever a process is replaced or stopped, so a late message or
    /// stream end from the one before is ignored.
    /// The lifecycle token: `start`'s launch, `stop` and every relaunch bump it, and each re-checks it after
    /// every `await`, so whichever of them was overtaken backs out without touching state.
    var generation = 0
    var isStopping = false
    /// A turn is being abandoned and its process replaced; a second interrupt or timeout is refused meanwhile.
    var isRelaunching = false
    /// The process has spoken for this session id, so claude has created it and a relaunch may resume it.
    /// Only an established id is stored.
    var sessionEstablished = false
    /// The current process has emitted a message.
    var processSpoke = false
    /// The current process answered with claude's lost-session result, which `handle` held back.
    var lostSessionSeen = false
    /// Once per start, a resumed process that claude says no longer has its session is replaced by a
    /// fresh session.
    var freshSessionAvailable = false
    /// A turn sent again to a replacement process: already in the transcript and the chat, so not recorded twice.
    var resentInbound: PartnerInbound?
    var currentInbound: PartnerInbound?
    /// Set when the willQuit turn's result arrives.
    var quitTurnFinished = false
    var refreshers: [PeriodicRefresher] = []
    var lastTick: [String: Date] = [:]
    /// Message ids chosen for a button's line before it is sent, by attribution source.
    var presetMessageIDs: [String: String] = [:]
    /// Items whose button line has been sent; the next message from the partner completes them.
    var awaitingDone: [String] = []

    public init(store: PartnerStore, sessions: PartnerSessionRegistry, notifier: PartnerNotifier, paths: PartnerPaths,
                endpoint: @escaping @MainActor () -> Endpoint?,
                findClaude: @escaping () -> String? = { ClaudeCLI.findBinary() },
                makeProcess: @escaping @Sendable (PartnerProcessConfiguration, [String: String])
                    -> any PartnerProcessing = { PartnerProcess(configuration: $0, environment: $1) },
                settings: SettingsStore = UserSettings.shared,
                turnTimeout: (() -> Duration)? = nil,
                pid: Int32 = ProcessInfo.processInfo.processIdentifier,
                isPIDAlive: @escaping (Int32) -> Bool = { kill($0, 0) == 0 },
                now: @escaping () -> Date = Date.init) {
        self.store = store
        self.sessions = sessions
        self.notifier = notifier
        self.paths = paths
        self.endpoint = endpoint
        self.findClaude = findClaude
        self.makeProcess = makeProcess
        self.settings = settings
        self.turnTimeout = turnTimeout
        self.pid = pid
        self.isPIDAlive = isPIDAlive
        self.now = now

        let initial: [ChatMessage]
        do { initial = try store.transcript(limit: 500) } catch {
            Self.logger.error("Loading the partner transcript failed: \(error.localizedDescription)")
            initial = []
        }
        // The chat session is made before `self` is whole, so it reaches back through a weak box.
        let box = WeakController()
        chatSession = PartnerChatSession(
            initial: initial,
            send: { text in Task { @MainActor in box.controller?.enqueue(.owner(text: text, attribution: nil)) } },
            interrupt: { Task { @MainActor in await box.controller?.interruptTurn() } })
        box.controller = self
        sessions.onEvent = { [weak self] in self?.enqueue($0) }
    }

    // MARK: - Lifecycle

    /// Takes the live lock, writes the files claude reads, launches it and tells it it started.
    /// Does nothing unless ``UserSettings/partnerEnabled`` is on and the partner is stopped or failed.
    public func start() async {
        switch state {
        case .stopped, .failed: break
        case .starting, .idle, .thinking: return
        }
        guard settings.get(UserSettings.partnerEnabled) else { return }
        state = .starting

        do {
            guard try store.acquireLock(pid: pid, isAlive: isPIDAlive) else {
                let holder = (try? store.liveLock())?.pid
                let reason = "another Kitchen (pid \(holder.map(String.init) ?? "?")) is running the partner"
                fail(reason, notify: true)
                return
            }
        } catch {
            fail("could not take the partner lock: \(error.localizedDescription)", notify: true)
            return
        }
        guard let claude = findClaude() else { return failReleasingLock("claude not found") }
        guard let endpoint = endpoint() else { return failReleasingLock("automation endpoint is not running") }

        let callerID = UUID().uuidString
        let configuration: PartnerProcessConfiguration
        let jobs: [PartnerJob]
        do {
            try PartnerMCPConfig.write(port: endpoint.port, token: endpoint.token, callerID: callerID,
                                       to: paths.mcpConfig)
            let installer = PartnerGuidelinesInstaller(paths: paths)
            jobs = installer.loadGuidelines(jobs: self.jobs())
            try installer.writeJobFiles(jobs: jobs)
            try installer.writeSystemPrompt(jobs: jobs)
            try installer.installSkills(jobs: jobs)
            // A new id is stored only once the process speaks (`handle`): claude creates the session on
            // its first turn, and resuming an id it never created fails every start after.
            let stored = try store.sessionID()
            sessionEstablished = stored != nil
            freshSessionAvailable = true
            configuration = PartnerProcessConfiguration(
                executable: claude, sessionID: stored ?? UUID(), resume: stored != nil,
                model: settings.get(UserSettings.partnerModel),
                permissionMode: settings.get(UserSettings.partnerPermissionMode),
                allowedTools: Self.allowedTools(settings.get(UserSettings.partnerAllowedTools)),
                mcpConfigPath: paths.mcpConfig.path, systemPromptPath: paths.systemPrompt.path,
                workingDirectory: paths.directory.path)
        } catch {
            return failReleasingLock("could not prepare the partner: \(error.localizedDescription)")
        }

        self.callerID = callerID
        environment = ["PATH": ClaudeCLI.searchPath(claudeDirectory: ClaudeCLI.directory(ofBinary: claude))]
        do {
            try await launch(configuration)
        } catch is CancellationError {
            return  // A stop overtook the launch and owns the state now.
        } catch {
            return failReleasingLock("could not launch claude: \(error.localizedDescription)")
        }
        state = .idle
        chatSession.setState(.ready)

        queue.enqueueFirst(.lifecycle(.started(resumed: configuration.resume, goneSessions: closeGoneSessions())))
        queuedCount = queue.count
        startSchedules(jobs: jobs)
        purge()
        runNextTurnIfIdle()
    }

    /// Ends the process and releases the lock. Queued events stay for the next start.
    public func stop() async {
        isStopping = true
        defer { isStopping = false }
        generation += 1
        tearDown()
        if let process {
            await process.terminate()
        }
        await readerTask?.value
        readerTask = nil
        process = nil
        currentInbound = nil
        callerID = nil
        releaseLock()
        state = .stopped
        chatSession.setState(.closed)
    }

    /// Stops and starts again, re-reading the guidelines files.
    public func restart() async {
        await stop()
        await start()
    }

    /// The store's jobs. Built-in jobs missing from the store are seeded from their defaults first.
    public func jobs() -> [PartnerJob] {
        do {
            var stored = try store.jobs()
            let missing = PartnerJobDefaults.all.filter { job in !stored.contains { $0.id == job.id } }
            if !missing.isEmpty {
                for job in missing { try store.upsert(job) }
                stored = try store.jobs()
            }
            return stored
        } catch {
            Self.logger.error("Reading partner jobs failed: \(error.localizedDescription)")
            return PartnerJobDefaults.all
        }
    }

    // MARK: - Process

    /// Makes, starts and starts reading a process for `configuration`, replacing any before it.
    /// Throws `CancellationError`, with the new process terminated, if a stop or another launch overtook it.
    func launch(_ configuration: PartnerProcessConfiguration) async throws {
        generation += 1
        let generation = generation
        let process = makeProcess(configuration, environment)
        try await process.start()
        guard generation == self.generation, !isStopping else {
            await process.terminate()
            throw CancellationError()
        }
        self.configuration = configuration
        self.process = process
        processSpoke = false
        lostSessionSeen = false
        let stream = process.messages()
        readerTask = Task { [weak self] in
            for await message in stream {
                self?.handle(message, generation: generation)
            }
            await self?.readerEnded(process: process, generation: generation)
        }
    }

    /// The stream ended without a stop: the process died. Fails, with stderr's tail in the notice.
    private func readerEnded(process: any PartnerProcessing, generation: Int) async {
        guard generation == self.generation, !isStopping else { return }
        if await process.isRunning { await process.terminate() }
        let stderr = await process.standardErrorText().trimmingCharacters(in: .whitespacesAndNewlines)
        guard generation == self.generation, !isStopping else { return }
        // claude no longer has the session: it said so in a result (which `handle` held back) or on
        // stderr. A silent exit (killed, out of memory, a crash at startup) is a failure and keeps the
        // session, so the conversation is not thrown away.
        if freshSessionAvailable, let configuration, configuration.resume,
           lostSessionSeen || stderr.contains(ClaudeStreamMessage.lostSessionText) {
            return await startFreshSession(replacing: configuration, stderr: stderr)
        }
        self.generation += 1
        self.process = nil
        currentInbound = nil
        tearDown()
        releaseLock()
        fail("partner process exited", notify: true, detail: String(stderr.suffix(2_000)))
    }

    /// claude reported it no longer has the resumed session. Forgets it, says so,
    /// and launches a new session, once per start, so a claude that keeps exiting still ends in failure.
    private func startFreshSession(replacing previous: PartnerProcessConfiguration, stderr: String) async {
        freshSessionAvailable = false
        isRelaunching = true
        defer { isRelaunching = false }
        timeoutTask?.cancel()
        timeoutTask = nil
        let interrupted = currentInbound
        currentInbound = nil
        sessionEstablished = false
        do { try store.setSessionID(nil) } catch {
            Self.logger.error("Clearing the partner session id failed: \(error.localizedDescription)")
        }
        let tail = stderr.isEmpty ? "" : "\n\(stderr.suffix(2_000))"
        do {
            try notifier.notify(title: "Partner started a new conversation",
                                body: "The earlier conversation could not be resumed.\(tail)",
                                createdBy: Self.createdBy)
        } catch {
            Self.logger.error("Recording a lost partner session failed: \(error.localizedDescription)")
        }

        var configuration = previous
        configuration.sessionID = UUID()
        configuration.resume = false
        do {
            try await launch(configuration)
        } catch is CancellationError {
            return  // A stop or restart overtook it and owns the state now.
        } catch {
            process = nil
            tearDown()
            releaseLock()
            fail("could not launch claude: \(error.localizedDescription)", notify: true)
            return
        }
        // The turn in flight went to the dead process: send it again, still open in the chat and
        // already in the transcript, with a `started` notice now saying the session is new.
        var resend = interrupted
        if case .lifecycle(.started(_, let gone))? = interrupted {
            resend = .lifecycle(.started(resumed: false, goneSessions: gone))
        }
        if let resend {
            queue.enqueueFirst(resend)
            resentInbound = resend
        }
        setQueuedCount(queue.count)
        setState(.idle)
        runNextTurnIfIdle()
    }

    // MARK: - State

    func setState(_ newState: State) { state = newState }
    func setQueuedCount(_ count: Int) { queuedCount = count }

    func fail(_ reason: String, notify: Bool, detail: String = "") {
        Self.logger.error("Partner failed: \(reason, privacy: .public)")
        state = .failed(reason)
        chatSession.setState(.failed(ChatError(message: reason, isRetryable: true)))
        guard notify else { return }
        let body = detail.isEmpty ? reason : "\(reason)\n\(detail)"
        do {
            try notifier.notify(title: "Coding partner stopped", body: body, createdBy: Self.createdBy)
        } catch {
            Self.logger.error("Recording a partner failure failed: \(error.localizedDescription)")
        }
    }

    private func failReleasingLock(_ reason: String) {
        releaseLock()
        fail(reason, notify: true)
    }

    func releaseLock() {
        do { try store.releaseLock(pid: pid) } catch {
            Self.logger.error("Releasing the partner lock failed: \(error.localizedDescription)")
        }
    }

    /// Cancels the timers that feed or police turns.
    func tearDown() {
        timeoutTask?.cancel()
        timeoutTask = nil
        for refresher in refreshers { refresher.stop() }
        refreshers = []
    }

    // MARK: - Start helpers

    /// Stored sessions still open from an earlier run, marked closed now. Sessions this run opened are kept.
    private func closeGoneSessions() -> [String] {
        let live = Set(sessions.sessions.map(\.id.uuidString))
        do {
            let gone = try store.sessions().filter { $0.closedAt == nil && !live.contains($0.id) }
            for var record in gone {
                record.closedAt = now()
                try store.upsert(record)
            }
            return gone.map(\.id)
        } catch {
            Self.logger.error("Closing gone partner sessions failed: \(error.localizedDescription)")
            return []
        }
    }

    private func startSchedules(jobs: [PartnerJob]) {
        for job in jobs where job.isEnabled {
            guard let seconds = job.scheduleSeconds, seconds > 0 else { continue }
            let refresher = PeriodicRefresher(interval: TimeInterval(seconds))
            let jobID = job.id
            let jobName = job.name
            refresher.start(for: self) { controller in
                let summary = await controller.tickPreparers[jobID]?()
                let previous = controller.lastTick[jobID]
                controller.lastTick[jobID] = controller.now()
                controller.enqueue(.tick(jobID: jobID, jobName: jobName, previousTick: previous, summary: summary))
            }
            refreshers.append(refresher)
        }
    }

    private func purge() {
        let days = settings.get(UserSettings.partnerAttentionRetentionDays)
        do {
            _ = try store.purgeDone(completedBefore: now().addingTimeInterval(-TimeInterval(days) * 86_400))
        } catch {
            Self.logger.error("Purging done attention items failed: \(error.localizedDescription)")
        }
        sessions.purge(retentionDays: days)
    }

    /// Splits the allowed-tools setting on whitespace outside parentheses, so `Bash(git log *)` stays one entry.
    static func allowedTools(_ setting: String) -> [String] {
        var tools: [String] = []
        var current = ""
        var depth = 0
        for character in setting {
            switch character {
            case "(": depth += 1; current.append(character)
            case ")": depth = max(depth - 1, 0); current.append(character)
            case _ where character.isWhitespace && depth == 0:
                if !current.isEmpty { tools.append(current) }
                current = ""
            default: current.append(character)
            }
        }
        if !current.isEmpty { tools.append(current) }
        return tools
    }

    static let createdBy = "app"
}

extension PartnerController: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// Lets the chat session's closures reach the controller that owns it.
private final class WeakController: @unchecked Sendable {
    @MainActor weak var controller: PartnerController?
}
