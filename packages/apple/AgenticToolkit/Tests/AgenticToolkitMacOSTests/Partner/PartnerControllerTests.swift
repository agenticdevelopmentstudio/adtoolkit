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

    init(configuration: PartnerProcessConfiguration) {
        self.configuration = configuration
        (stream, continuation) = AsyncStream.makeStream(of: ClaudeStreamMessage.self)
    }

    var sent: [String] { lock.withLock { sentTexts } }
    var wasTerminated: Bool { lock.withLock { terminated } }

    func start() async throws { lock.withLock { running = true } }
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

/// Every process the controller made, in order.
final class FakeProcessLog: @unchecked Sendable {
    private let lock = NSLock()
    private var made: [FakePartnerProcess] = []
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
                let process = FakePartnerProcess(configuration: configuration)
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
}
