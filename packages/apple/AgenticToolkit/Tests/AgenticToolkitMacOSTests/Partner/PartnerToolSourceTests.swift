import SQLite3
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class PartnerToolSourceTests: XCTestCase {

    private var directory: URL!
    private var databasePath: String!
    private var store: PartnerStore!
    private var registry: PartnerSessionRegistry!
    private var source: PartnerToolSource!
    private var posts: [(String, String)] = []

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerToolSourceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databasePath = directory.appendingPathComponent("Partner.db").path
        store = try PartnerStore(path: databasePath)
        registry = PartnerSessionRegistry(store: store, environment: { [:] }, detector: ManualSessionEventDetector())
        posts = []
        let settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                     secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let notifier = PartnerNotifier(store: store, settings: settings,
                                       post: { [unowned self] in posts.append(($0, $1)) })
        source = PartnerToolSource(callerID: { "c1" }, store: store, sessions: registry,
                                   projects: { [.init(id: "p", name: "n", path: "/x")] }, notifier: notifier)
    }

    override func tearDown() async throws {
        _ = registry.closeAll()
        source = nil; registry = nil; store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func call(_ name: String, _ args: [String: Any] = [:], caller: String? = "c1") async throws
        -> (content: String, isError: Bool) {
        await source.callTool(name: name, argumentsJSON: try JSONSerialization.data(withJSONObject: args),
                              caller: caller)
    }

    private func json(_ text: String) throws -> Any { try JSONSerialization.jsonObject(with: Data(text.utf8)) }

    private func toolCallCount() -> Int {
        var handle: OpaquePointer?
        sqlite3_open_v2(databasePath, &handle, SQLITE_OPEN_READONLY, nil)
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(handle, "SELECT COUNT(*) FROM tool_call", -1, &stmt, nil)
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : -1
    }

    func testRefusesEveryCallerButThePartner() async throws {
        let refused = try await call("partner_attention_list", caller: "pane-9")
        XCTAssertTrue(refused.isError)
        XCTAssertTrue(refused.content.contains("refused"))
        let allowed = try await call("partner_attention_list")
        XCTAssertFalse(allowed.isError, allowed.content)
        XCTAssertEqual(toolCallCount(), 2)
        let nobody = try await call("partner_attention_list", caller: nil)
        XCTAssertTrue(nobody.isError, "a nil caller is not the partner")
    }

    func testDefinitionsNameTheTwelveTools() async {
        let names = await source.toolDefinitions().map(\.name).sorted()
        XCTAssertEqual(names, [
            "partner_attention_create", "partner_attention_list", "partner_attention_update", "partner_notify",
            "partner_projects_list", "partner_session_close", "partner_session_interrupt", "partner_session_list",
            "partner_session_open", "partner_session_run", "partner_session_screen", "partner_session_wait"
        ])
    }

    func testAttentionCreateInsertsAndListReturnsIt() async throws {
        let created = try await call("partner_attention_create",
                                     ["kind": "question", "text": "Q?", "reference": ["review": "r1"]])
        XCTAssertFalse(created.isError, created.content)
        let id = try XCTUnwrap((try json(created.content) as? [String: Any])?["id"] as? String)
        let list = try await call("partner_attention_list")
        XCTAssertTrue(list.content.contains("Q?"))
        XCTAssertTrue(list.content.contains(id))
        let done = try await call("partner_attention_update", ["id": id, "done": true])
        XCTAssertFalse(done.isError, done.content)
        XCTAssertEqual(try store.attentionItem(id: id)?.state, .done)
    }

    func testNotifyRecordsItemAndPosts() async throws {
        let result = try await call("partner_notify", ["title": "T", "body": "B"])
        XCTAssertFalse(result.isError, result.content)
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts.first?.0, "T")
        let items = try store.attentionItems(includeDoneCompletedAfter: nil)
        XCTAssertEqual(items.map(\.kind), [.notification])
    }

    func testProjectsList() async throws {
        let result = try await call("partner_projects_list")
        XCTAssertTrue(result.content.contains("\"name\":\"n\""), result.content)
    }

    func testSessionOpenRunScreenClose() async throws {
        let opened = try await call("partner_session_open", ["directory": directory.path])
        XCTAssertFalse(opened.isError, opened.content)
        let id = try XCTUnwrap((try json(opened.content) as? [String: Any])?["session"] as? String)
        let run = try await call("partner_session_run",
                                 ["session": id, "command": "echo HI", "settle": 1, "timeout": 10])
        XCTAssertTrue(run.content.contains("HI"), run.content)
        let screen = try await call("partner_session_screen", ["session": id])
        XCTAssertTrue(screen.content.contains("HI"), screen.content)
        let list = try await call("partner_session_list")
        XCTAssertTrue(list.content.contains(id))
        let closed = try await call("partner_session_close", ["session": id])
        XCTAssertFalse(closed.isError, closed.content)
        XCTAssertNotNil(try store.sessions().first { $0.id == id }?.closedAt)
    }
}
