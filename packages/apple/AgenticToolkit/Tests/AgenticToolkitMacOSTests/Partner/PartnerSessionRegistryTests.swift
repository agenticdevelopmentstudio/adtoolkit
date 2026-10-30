import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Drives real shells: each test opens one in a temporary directory.
@MainActor
final class PartnerSessionRegistryTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var detector: ManualSessionEventDetector!
    private var registry: PartnerSessionRegistry!
    private var events: [PartnerInbound] = []

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerSessionRegistryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
        detector = ManualSessionEventDetector()
        registry = PartnerSessionRegistry(store: store, environment: { ["PARTNER_TEST": "1"] }, detector: detector)
        events = []
        registry.onEvent = { [unowned self] in events.append($0) }
    }

    override func tearDown() async throws {
        _ = registry.closeAll()
        registry = nil
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func waitUntil(_ timeout: TimeInterval = 3, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    func testOpenRunsTheFirstCommand() async {
        let session = registry.open(directory: directory.path, title: "t", firstCommand: "echo READY")
        await waitUntil { session.terminal.isRunning && (session.chat.screen()?.contains("READY") ?? false) }
        XCTAssertTrue(session.terminal.isRunning)
        XCTAssertTrue(session.chat.screen()?.contains("READY") ?? false, session.chat.screen() ?? "nil")
        XCTAssertEqual(registry.sessions.map(\.id), [session.id])
        XCTAssertEqual(detector.watched, [session.id])
    }

    func testEnvironmentNamesThePaneAndTheProject() {
        let session = registry.open(directory: directory.path, title: "t", firstCommand: nil)
        XCTAssertEqual(session.terminal.environment["ADKITCHEN_PANE_ID"], session.id.uuidString)
        XCTAssertEqual(session.terminal.environment["ADKITCHEN_PROJECT"], directory.path)
        XCTAssertEqual(session.terminal.environment["PARTNER_TEST"], "1")
    }

    func testCloseStoresTheFinalScreenAndClosedAt() async throws {
        let session = registry.open(directory: directory.path, title: "t", firstCommand: "echo READY")
        await waitUntil { session.chat.screen()?.contains("READY") ?? false }
        registry.close(id: session.id)
        XCTAssertTrue(registry.sessions.isEmpty)
        XCTAssertEqual(detector.watched, [])
        let record = try XCTUnwrap(store.sessions().first { $0.id == session.id.uuidString })
        XCTAssertNotNil(record.closedAt)
        XCTAssertFalse(record.finalScreen?.isEmpty ?? true)
        XCTAssertEqual(record.title, "t")
        XCTAssertEqual(record.directory, directory.path)
    }

    func testNewestFirstAndCloseAllReturnsEveryID() {
        let first = registry.open(directory: directory.path, title: "a", firstCommand: nil)
        let second = registry.open(directory: directory.path, title: "b", firstCommand: nil)
        XCTAssertEqual(registry.sessions.map(\.id), [second.id, first.id])
        XCTAssertEqual(Set(registry.closeAll()), [first.id.uuidString, second.id.uuidString])
        XCTAssertTrue(registry.sessions.isEmpty)
    }

    func testIdleAndExitBecomeEvents() async throws {
        let session = registry.open(directory: directory.path, title: "t", firstCommand: nil)
        detector.onIdle?(session.id)
        XCTAssertEqual(session.state, .idle)
        detector.onIdle?(session.id)
        detector.onExit?(session.id)
        XCTAssertEqual(session.state, .exited)
        XCTAssertEqual(events, [.sessionIdle(sessionID: session.id.uuidString, title: "t"),
                                .sessionExited(sessionID: session.id.uuidString, title: "t")])
        let record = try XCTUnwrap(store.sessions().first)
        XCTAssertNotNil(record.closedAt)
    }

    func testPurgeForgetsOldClosedSessions() throws {
        try store.upsert(.init(id: "old", title: "o", directory: "/",
                               openedAt: Date(timeIntervalSinceNow: -10 * 86_400),
                               closedAt: Date(timeIntervalSinceNow: -9 * 86_400)))
        try store.upsert(.init(id: "new", title: "n", directory: "/", openedAt: Date(), closedAt: Date()))
        registry.purge(retentionDays: 7)
        XCTAssertEqual(try store.sessions().map(\.id), ["new"])
    }
}
