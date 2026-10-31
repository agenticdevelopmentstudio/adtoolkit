import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// A partner process the test drives: it records what was sent and yields
/// whatever the test pushes.
final class FakePartnerProcess: PartnerProcessing, @unchecked Sendable {
    let configuration: PartnerProcessConfiguration
    private let lock = NSLock()
    private var sentTexts: [String] = []
    private var running = false
    private var terminated = false
    private var stderr = ""
    private let stream: AsyncStream<ClaudeStreamMessage>
    private let continuation: AsyncStream<ClaudeStreamMessage>.Continuation

    /// How a fake process ends on its own, right after starting.
    enum Ending: Sendable {
        /// It runs until the test ends it.
        case none
        /// It exits having said nothing.
        case silently
        /// It does what real claude does for a `--resume` id it does not have: one error `result`
        /// (the captured line), the captured stderr, exit.
        case unknownSession
    }

    private let gate: StartGate?
    private let ending: Ending

    init(configuration: PartnerProcessConfiguration, gate: StartGate? = nil, ending: Ending = .none) {
        self.configuration = configuration
        self.gate = gate
        self.ending = ending
        (stream, continuation) = AsyncStream.makeStream(of: ClaudeStreamMessage.self)
    }

    var sent: [String] { lock.withLock { sentTexts } }
    var wasTerminated: Bool { lock.withLock { terminated } }

    var isLive: Bool { lock.withLock { running } }

    func start() async throws {
        await gate?.wait()
        switch ending {
        case .none:
            lock.withLock { running = true }
        case .silently:
            continuation.finish()
        case .unknownSession:
            let line = try ClaudeStreamFixtures.unknownSessionResultLine()
            let text = try ClaudeStreamFixtures.unknownSessionStderr()
            continuation.yield(try ClaudeStreamMessage.decode(line))
            lock.withLock { stderr = text }
            continuation.finish()
        }
    }
    func send(_ text: String) async throws { lock.withLock { sentTexts.append(text) } }
    func messages() -> AsyncStream<ClaudeStreamMessage> { stream }
    func terminate() async {
        lock.withLock { terminated = true; running = false }
        continuation.finish()
    }
    var isRunning: Bool { get async { lock.withLock { running } } }
    func standardErrorText() async -> String { lock.withLock { stderr } }

    func push(_ message: ClaudeStreamMessage) { continuation.yield(message) }

    /// The process dies on its own, leaving `stderr` behind.
    func crash(stderr text: String) {
        lock.withLock { stderr = text; running = false }
        continuation.finish()
    }
}

/// Holds a fake process's `start()` until the test opens it.
final class StartGate: @unchecked Sendable {
    private let lock = NSLock()
    private var opened = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var arrivals = 0

    /// How many starts have reached the gate.
    var arrived: Int { lock.withLock { arrivals } }

    func wait() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let pass = lock.withLock {
                arrivals += 1
                if opened { return true }
                waiters.append(continuation)
                return false
            }
            if pass { continuation.resume() }
        }
    }

    func open() {
        let waiting = lock.withLock {
            opened = true
            defer { waiters = [] }
            return waiters
        }
        for waiter in waiting { waiter.resume() }
    }
}

/// Every process the controller made, in order.
final class FakeProcessLog: @unchecked Sendable {
    private let lock = NSLock()
    private var made: [FakePartnerProcess] = []
    private var startGate: StartGate?
    private var endingFor: (@Sendable (PartnerProcessConfiguration) -> FakePartnerProcess.Ending)?
    /// How processes made from now on end, by their configuration.
    var ending: (@Sendable (PartnerProcessConfiguration) -> FakePartnerProcess.Ending)? {
        get { lock.withLock { endingFor } }
        set { lock.withLock { endingFor = newValue } }
    }
    /// Processes made from now on wait at this gate in `start()`.
    var gate: StartGate? {
        get { lock.withLock { startGate } }
        set { lock.withLock { startGate = newValue } }
    }
    var all: [FakePartnerProcess] { lock.withLock { made } }
    func add(_ process: FakePartnerProcess) { lock.withLock { made.append(process) } }
}

@MainActor
final class PartnerControllerTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var settings: SettingsStore!
    private var registry: PartnerSessionRegistry!
    private var notifier: PartnerNotifier!
    private var paths: PartnerPaths!
    private var log: FakeProcessLog!
    private var controller: PartnerController?

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerControllerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
        settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                 secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        settings.set(true, for: UserSettings.partnerEnabled)
        notifier = PartnerNotifier(store: store, settings: settings, post: { _, _ in })
        registry = PartnerSessionRegistry(store: store, environment: { [:] }, detector: ManualSessionEventDetector())
        paths = PartnerPaths(home: directory, token: "kitchen-test")
        log = FakeProcessLog()
    }

    override func tearDown() async throws {
        await controller?.stop()
        controller = nil
        _ = registry.closeAll()
        registry = nil; notifier = nil; store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeController(
        endpoint: PartnerController.Endpoint? = .init(port: 1, token: "t"),
        turnTimeout: (() -> Duration)? = nil,
        isPIDAlive: @escaping (Int32) -> Bool = { _ in false }
    ) -> PartnerController {
        let log = log!
        let made = PartnerController(
            store: store, sessions: registry, notifier: notifier, paths: paths,
            endpoint: { endpoint },
            findClaude: { "/bin/true" },
            makeProcess: { configuration, _ in
                let process = FakePartnerProcess(configuration: configuration, gate: log.gate,
                                                 ending: log.ending?(configuration) ?? .none)
                log.add(process)
                return process
            },
            settings: settings, turnTimeout: turnTimeout, pid: 4242, isPIDAlive: isPIDAlive)
        controller = made
        return made
    }

    private func waitUntil(_ timeout: TimeInterval = 3, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private var process: FakePartnerProcess { log.all.last! }
    private static let result = ClaudeStreamMessage(kind: .result, subtype: "success")
    private static func assistant(_ text: String) -> ClaudeStreamMessage {
        ClaudeStreamMessage(kind: .assistant, blocks: [.init(kind: .text, text: text)])
    }

    /// Starts, then answers the started notice so the partner is idle.
    private func startIdle(_ controller: PartnerController) async {
        await controller.start()
        await waitUntil { process.sent.count == 1 }
        process.push(Self.result)
        await waitUntil { controller.state == .idle }
    }

    func testStartWritesMcpConfigAndPromptThenSendsStartedLifecycle() async throws {
        let controller = makeController()
        await controller.start()
        let attributes = try FileManager.default.attributesOfItem(atPath: paths.mcpConfig.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.systemPrompt.path))
        await waitUntil { !process.sent.isEmpty }
        XCTAssertTrue(process.sent.first?.contains("started") ?? false, "\(process.sent)")
        XCTAssertNotNil(controller.callerID)
        XCTAssertEqual(controller.state, .thinking)
    }

    func testStartUsesEditedGuidelinesFromJobFiles() async throws {
        try FileManager.default.createDirectory(at: paths.jobsDirectory, withIntermediateDirectories: true)
        try "Always answer in haiku.".write(to: paths.jobsDirectory.appendingPathComponent("general.md"),
                                            atomically: true, encoding: .utf8)
        let controller = makeController()
        await controller.start()
        let prompt = try String(contentsOf: paths.systemPrompt, encoding: .utf8)
        XCTAssertTrue(prompt.contains("Always answer in haiku."), prompt)
    }

    func testTurnsAreSerialisedAndNextSentAfterResult() async {
        let controller = makeController()
        await controller.start()
        await waitUntil { process.sent.count == 1 }
        controller.enqueue(.owner(text: "one", attribution: nil))
        controller.enqueue(.owner(text: "two", attribution: nil))
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(process.sent.count, 1)
        XCTAssertEqual(controller.queuedCount, 2)
        process.push(Self.result)
        await waitUntil { process.sent.count == 2 }
        XCTAssertEqual(process.sent.last, "one")
        XCTAssertEqual(controller.queuedCount, 1)
        process.push(Self.result)
        await waitUntil { process.sent.count == 3 }
        XCTAssertEqual(process.sent.last, "two")
        XCTAssertEqual(controller.queuedCount, 0)
    }

    func testErrorResultReturnsToIdle() async {
        let controller = makeController()
        var failures: [String] = []
        let events = controller.chatSession.events()
        let reader = Task { @MainActor in
            for await event in events {
                if case .turnFailed(let error) = event { failures.append(error.message) }
            }
        }
        await controller.start()
        await waitUntil { process.sent.count == 1 }
        process.push(ClaudeStreamMessage(kind: .result, subtype: "error_during_execution", isError: true,
                                         resultText: "it broke"))
        await waitUntil { controller.state == .idle && !failures.isEmpty }
        XCTAssertEqual(controller.state, .idle)
        XCTAssertEqual(failures, ["it broke"])
        reader.cancel()
    }

    func testTurnTimeoutTerminatesResumesAndNotifies() async throws {
        var calls = 0
        let controller = makeController(turnTimeout: {
            calls += 1
            return calls == 1 ? .milliseconds(200) : .seconds(60)
        })
        await controller.start()
        let first = process
        await waitUntil { first.sent.count == 1 }
        first.push(Self.assistant("Looking."))
        await waitUntil { log.all.count == 2 }
        XCTAssertTrue(first.wasTerminated)
        XCTAssertEqual(log.all.count, 2)
        XCTAssertTrue(process.configuration.resume)
        XCTAssertEqual(process.configuration.sessionID, first.configuration.sessionID)
        let items = try store.attentionItems(includeDoneCompletedAfter: nil)
        XCTAssertTrue(items.contains { $0.kind == .notification && $0.text.contains("timed out") }, "\(items)")
        await waitUntil { process.sent.count == 1 }
        XCTAssertTrue(process.sent.first?.contains("turn timeout") ?? false, "\(process.sent)")
        process.push(Self.result)
        await waitUntil { controller.state == .idle }
        XCTAssertEqual(controller.state, .idle)
    }

    func testSecondPartnerRefusedByLiveLock() async throws {
        XCTAssertTrue(try store.acquireLock(pid: 999, isAlive: { _ in true }))
        let controller = makeController(isPIDAlive: { $0 == 999 })
        await controller.start()
        guard case .failed(let reason) = controller.state else {
            return XCTFail("expected failed, got \(controller.state)")
        }
        XCTAssertTrue(reason.contains("another"), reason)
        XCTAssertTrue(reason.contains("999"), reason)
        XCTAssertTrue(log.all.isEmpty)
        XCTAssertEqual(try store.liveLock()?.pid, 999)
    }

    func testConfirmSendsOwnerVoiceAndMarksDoneOnNextMessage() async throws {
        let controller = makeController()
        await startIdle(controller)
        let item = AttentionItem(kind: .question, text: "Ship it?", createdBy: "partner")
        try store.insert(item)
        try controller.performButton(.confirm, itemID: item.id)
        await waitUntil { process.sent.count == 2 }
        XCTAssertEqual(process.sent.last, "Confirmed: Ship it?")
        XCTAssertEqual(try store.attentionItem(id: item.id)?.state, .sent)
        process.push(Self.assistant("Shipping."))
        await waitUntil { (try? store.attentionItem(id: item.id)?.state) == .done }
        let done = try XCTUnwrap(store.attentionItem(id: item.id))
        XCTAssertEqual(done.state, .done)
        XCTAssertNotNil(done.completedAt)
        let actions = try store.actions(itemID: item.id)
        XCTAssertEqual(actions.map(\.action), [.confirm])
        let messageID = try XCTUnwrap(actions.first?.messageID)
        let sentMessage = try XCTUnwrap(store.transcript(limit: 20).first { $0.id == messageID })
        XCTAssertEqual(sentMessage.text, "Confirmed: Ship it?")
        XCTAssertEqual(sentMessage.attribution?.sourceID, "attention:\(item.id)")
        XCTAssertEqual(sentMessage.attribution?.name, "Confirm")
    }

    func testBeginDiscussionQuotesTheItem() async throws {
        let controller = makeController()
        let item = AttentionItem(kind: .question, text: "Line one\nLine two", createdBy: "partner")
        try store.insert(item)
        let quoted = try controller.beginDiscussion(itemID: item.id)
        XCTAssertEqual(quoted, "> Line one\n> Line two\n\n")
        XCTAssertEqual(try store.attentionItem(id: item.id)?.state, .discussing)
        XCTAssertEqual(try store.actions(itemID: item.id).map(\.action), [.discuss])
    }

    func testSessionEventsFromRegistryAreEnqueued() async {
        let controller = makeController()
        await startIdle(controller)
        registry.onEvent?(.sessionIdle(sessionID: "s1", title: "Repo"))
        await waitUntil { process.sent.count == 2 }
        XCTAssertTrue(process.sent.last?.contains("went idle") ?? false, "\(process.sent)")
    }

    func testMissingEndpointFails() async {
        let controller = makeController(endpoint: nil)
        await controller.start()
        XCTAssertEqual(controller.state, .failed("automation endpoint is not running"))
        XCTAssertTrue(log.all.isEmpty)
    }

    func testProcessCrashFailsWithStderrInTheNotification() async throws {
        let controller = makeController()
        await startIdle(controller)
        process.crash(stderr: "boom\n")
        await waitUntil { controller.state == .failed("partner process exited") }
        XCTAssertEqual(controller.state, .failed("partner process exited"))
        let items = try store.attentionItems(includeDoneCompletedAfter: nil)
        XCTAssertTrue(items.contains { $0.text.contains("boom") }, "\(items)")
    }

    // MARK: - Lifecycle races

    func testStopDuringTimeoutRelaunchLeavesNothingRunning() async throws {
        var calls = 0
        let controller = makeController(turnTimeout: {
            calls += 1
            return calls == 1 ? .milliseconds(200) : .seconds(60)
        })
        await controller.start()
        let first = process
        await waitUntil { first.sent.count == 1 }
        first.push(Self.assistant("Looking."))
        let gate = StartGate()
        log.gate = gate
        await waitUntil { gate.arrived == 1 }
        XCTAssertEqual(gate.arrived, 1, "the timeout relaunch never reached start()")
        await controller.stop()
        gate.open()
        await waitUntil { log.all.last?.wasTerminated == true }
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(controller.state, .stopped)
        XCTAssertTrue(log.all.allSatisfy { !$0.isLive }, "a claude process is still running")
        XCTAssertNil(try store.liveLock())
    }

    func testTwoInterruptsMakeOneRelaunch() async throws {
        let controller = makeController()
        await controller.start()
        await waitUntil { process.sent.count == 1 }
        process.push(Self.assistant("Looking."))
        let gate = StartGate()
        log.gate = gate
        let first = Task { await controller.interruptTurn() }
        await waitUntil { gate.arrived == 1 }
        let second = Task { await controller.interruptTurn() }
        try? await Task.sleep(for: .milliseconds(100))
        gate.open()
        await first.value
        await second.value
        XCTAssertEqual(log.all.count, 2)
        XCTAssertEqual(controller.state, .idle)
        XCTAssertTrue(log.all.last?.isLive ?? false)
    }

    func testFirstLaunchThatDiesSilentlyDoesNotResumeNextTime() async throws {
        let controller = makeController()
        await controller.start()
        await waitUntil { process.sent.count == 1 }
        process.crash(stderr: "not logged in")
        await waitUntil { controller.state == .failed("partner process exited") }
        XCTAssertNil(try store.sessionID())
        await controller.start()
        XCTAssertEqual(log.all.count, 2)
        XCTAssertEqual(log.all.last?.configuration.resume, false)
    }

    func testSessionIsStoredOnceTheProcessSpeaks() async throws {
        let controller = makeController()
        await controller.start()
        await waitUntil { process.sent.count == 1 }
        XCTAssertNil(try store.sessionID())
        process.push(Self.result)
        await waitUntil { controller.state == .idle }
        XCTAssertEqual(try store.sessionID(), process.configuration.sessionID)
    }

    func testAllowedToolsDefaultKeepsParenthesisedEntriesWhole() {
        XCTAssertEqual(PartnerController.allowedTools(settings.get(UserSettings.partnerAllowedTools)), [
            "mcp__adkitchen", "Bash(git log *)", "Bash(git show *)", "Bash(git diff *)",
            "Bash(git status *)", "Bash(git branch *)", "Read"
        ])
        XCTAssertEqual(PartnerController.allowedTools("Read\tBash(git log *)\n  Edit "),
                       ["Read", "Bash(git log *)", "Edit"])
    }

    // MARK: - A session claude no longer knows

    private static let lostSessionNotice = "could not be resumed"

    private func notices() throws -> [AttentionItem] {
        try store.attentionItems(includeDoneCompletedAfter: nil).filter { $0.kind == .notification }
    }

    /// The fresh process got the started notice, answered it, and the partner is idle on the new session.
    private func assertFreshSessionAfterLost(_ lost: UUID, _ controller: PartnerController) async throws {
        await waitUntil { log.all.count == 2 && process.sent.count == 1 }
        XCTAssertEqual(log.all.count, 2)
        XCTAssertEqual(log.all.first?.configuration.resume, true)
        XCTAssertEqual(log.all.first?.configuration.sessionID, lost)
        XCTAssertEqual(process.configuration.resume, false)
        XCTAssertNotEqual(process.configuration.sessionID, lost)
        XCTAssertTrue(process.sent.first?.contains("started") ?? false, "\(process.sent)")
        process.push(Self.result)
        await waitUntil { controller.state == .idle }
        XCTAssertEqual(controller.state, .idle)
        XCTAssertEqual(try store.sessionID(), process.configuration.sessionID)
        let notices = try notices()
        XCTAssertEqual(notices.count, 1, "\(notices)")
        XCTAssertTrue(notices.first?.text.contains(Self.lostSessionNotice) ?? false, "\(notices)")
    }

    func testUnknownSessionResultStartsAFreshSessionOnce() async throws {
        let lost = UUID()
        try store.setSessionID(lost)
        log.ending = { $0.resume ? .unknownSession : .none }
        let controller = makeController()
        await controller.start()
        try await assertFreshSessionAfterLost(lost, controller)
        let transcript = try store.transcript(limit: 50)
        XCTAssertFalse(transcript.contains { $0.text.contains("No conversation found") }, "\(transcript)")
    }

    func testResumeThatExitsSilentlyStartsAFreshSessionOnce() async throws {
        let lost = UUID()
        try store.setSessionID(lost)
        log.ending = { $0.resume ? .unknownSession : .none }
        let controller = makeController()
        await controller.start()
        try await assertFreshSessionAfterLost(lost, controller)
    }

    /// Killed, out of memory, crashed at startup: claude said nothing about the session, so it is kept.
    func testResumeThatExitsSilentlyFailsAndKeepsSession() async throws {
        let kept = UUID()
        try store.setSessionID(kept)
        log.ending = { $0.resume ? .silently : .none }
        let controller = makeController()
        await controller.start()
        await waitUntil { controller.state == .failed("partner process exited") }
        XCTAssertEqual(controller.state, .failed("partner process exited"))
        XCTAssertEqual(log.all.count, 1)
        XCTAssertEqual(try store.sessionID(), kept)
        XCTAssertFalse(try notices().contains { $0.text.contains(Self.lostSessionNotice) })
    }

    func testStderrSayingNoConversationStartsAFreshSession() async throws {
        let lost = UUID()
        try store.setSessionID(lost)
        let controller = makeController()
        await controller.start()
        let first = process
        await waitUntil { first.sent.count == 1 }
        first.push(ClaudeStreamMessage(kind: .systemInit, sessionID: lost.uuidString))
        first.crash(stderr: try ClaudeStreamFixtures.unknownSessionStderr())
        try await assertFreshSessionAfterLost(lost, controller)
    }

    func testReSentTurnIsRecordedOnce() async throws {
        try store.setSessionID(UUID())
        log.ending = { $0.resume ? .unknownSession : .none }
        let controller = makeController()
        await controller.start()
        await waitUntil { log.all.count == 2 && process.sent.count == 1 }
        XCTAssertEqual(log.all.count, 2)
        process.push(Self.result)
        await waitUntil { controller.state == .idle }
        XCTAssertEqual(try store.transcript(limit: 50).filter { $0.role == .user }.count, 1)
        var events = controller.chatSession.events().makeAsyncIterator()
        guard case .transcriptLoaded(let shown)? = await events.next() else { return XCTFail("no transcript") }
        XCTAssertEqual(shown.filter { $0.role == .user }.count, 1, "\(shown)")
    }

    func testClaudeThatKeepsExitingStillFails() async throws {
        try store.setSessionID(UUID())
        log.ending = { $0.resume ? .unknownSession : .silently }
        let controller = makeController()
        await controller.start()
        await waitUntil { controller.state == .failed("partner process exited") }
        XCTAssertEqual(controller.state, .failed("partner process exited"))
        XCTAssertEqual(log.all.count, 2)
        XCTAssertEqual(log.all.last?.configuration.resume, false)
    }
}
