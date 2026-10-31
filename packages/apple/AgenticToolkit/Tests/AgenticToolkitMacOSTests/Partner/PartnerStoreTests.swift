import Combine
import SQLite3
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class PartnerStoreTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var cancellables: Set<AnyCancellable> = []

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: databasePath)
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private var databasePath: String { directory.appendingPathComponent("Partner.db").path }

    private func tableNames() throws -> Set<String> {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open_v2(databasePath, &handle, SQLITE_OPEN_READONLY, nil), SQLITE_OK)
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(handle, "SELECT name FROM sqlite_master WHERE type = 'table'", -1, &stmt, nil)
        var names: Set<String> = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            names.insert(String(cString: sqlite3_column_text(stmt, 0)))
        }
        return names
    }

    /// Runs `sql` on a separate raw connection and returns the first column of each row as text.
    @discardableResult
    private func rawQuery(_ sql: String) throws -> [String] {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open_v2(databasePath, &handle, SQLITE_OPEN_READWRITE, nil), SQLITE_OK)
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        XCTAssertEqual(sqlite3_prepare_v2(handle, sql, -1, &stmt, nil), SQLITE_OK)
        var values: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            values.append(sqlite3_column_text(stmt, 0).map { String(cString: $0) } ?? "")
        }
        return values
    }

    func testStoredVersionMatchesCurrentSchemaVersion() throws {
        XCTAssertEqual(try rawQuery("SELECT MAX(version) FROM schema_migrations"),
                       [String(PartnerStore.currentSchemaVersion)])
        store = nil
        store = try PartnerStore(path: databasePath)
        XCTAssertEqual(try rawQuery("SELECT COUNT(*) FROM schema_migrations"), ["2"])
    }

    func testNewerSchemaFileFailsToOpen() throws {
        store = nil
        try rawQuery("INSERT INTO schema_migrations (version) VALUES (99)")
        XCTAssertThrowsError(try PartnerStore(path: databasePath)) { error in
            guard case PartnerStoreError.newerSchema(let found, let supported) = error else {
                return XCTFail("unexpected error \(error)")
            }
            XCTAssertEqual(found, 99)
            XCTAssertEqual(supported, PartnerStore.currentSchemaVersion)
        }
    }

    func testDatabaseFilesAreOwnerOnly() throws {
        try store.append(ChatMessage(role: .user, text: "secret"))
        store = nil
        store = try PartnerStore(path: databasePath)
        for suffix in ["", "-wal", "-shm"] where FileManager.default.fileExists(atPath: databasePath + suffix) {
            let attributes = try FileManager.default.attributesOfItem(atPath: databasePath + suffix)
            XCTAssertEqual(attributes[.posixPermissions] as? Int, 0o600, "permissions of Partner.db\(suffix)")
        }
    }

    func testTwoStoresOnOneFileCannotBothAcquireTheLock() throws {
        let other = try PartnerStore(path: databasePath)
        XCTAssertTrue(try store.acquireLock(pid: 100, isAlive: { _ in true }))
        XCTAssertFalse(try other.acquireLock(pid: 200, isAlive: { _ in true }))
        XCTAssertEqual(try other.liveLock()?.pid, 100)
    }

    func testConcurrentAcquireAcrossStoresHasOneWinner() throws {
        let stores = [store!, try PartnerStore(path: databasePath)]
        for round in 0..<20 {
            try rawQuery("DELETE FROM partner_lock")
            let results = LockedResults()
            DispatchQueue.concurrentPerform(iterations: 2) { index in
                let won = (try? stores[index].acquireLock(pid: Int32(1000 + index), isAlive: { _ in true })) ?? false
                results.add(won)
            }
            XCTAssertEqual(results.values.filter { $0 }.count, 1, "round \(round)")
        }
    }

    func testMigrationCreatesTablesAndVersion() throws {
        let expected: Set<String> = [
            "attention_item", "attention_action", "partner_message", "job", "partner_session",
            "tool_call", "partner_lock", "partner_setting", "schema_migrations", "review", "review_setting"
        ]
        XCTAssertTrue(expected.isSubset(of: try tableNames()))
        store = nil
        store = try PartnerStore(path: databasePath)
        XCTAssertTrue(expected.isSubset(of: try tableNames()))
        XCTAssertEqual(PartnerStore.currentSchemaVersion, 2)
    }

    func testDefaultPathNamesPartnerDB() {
        let home = URL(fileURLWithPath: "/tmp/home")
        XCTAssertTrue(PartnerStore.defaultPath(inHome: home, token: "kitchen").hasSuffix("/.kitchen/Partner.db"))
    }

    func testAttentionRoundTripAndOrdering() throws {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let question = AttentionItem(id: "q", kind: .question, text: "Which?", reference: ["review": "r1"],
                                     createdBy: "partner", createdAt: base, updatedAt: base)
        var note = AttentionItem(id: "n", kind: .notification, text: "FYI",
                                 createdBy: "partner", createdAt: base.addingTimeInterval(10),
                                 updatedAt: base.addingTimeInterval(10))
        try store.insert(question)
        try store.insert(note)
        note.state = .done
        note.completedAt = base.addingTimeInterval(20)
        try store.update(note)

        let items = try store.attentionItems(includeDoneCompletedAfter: .distantPast)
        XCTAssertEqual(items.map(\.id), ["q", "n"])
        XCTAssertEqual(items[0], question)
        XCTAssertEqual(try store.attentionItem(id: "n")?.state, .done)
        XCTAssertNil(try store.attentionItem(id: "missing"))
        XCTAssertEqual(try store.attentionItems(includeDoneCompletedAfter: nil).map(\.id), ["q"])

        let action = AttentionAction(id: "a", itemID: "q", action: .discuss, at: base, messageID: "m1")
        try store.record(action)
        XCTAssertEqual(try store.actions(itemID: "q"), [action])
        XCTAssertTrue(try store.actions(itemID: "n").isEmpty)
    }

    func testPurgeDoneRemovesOnlyOldDone() throws {
        let base = Date(timeIntervalSince1970: 2_000_000)
        func item(_ id: String, _ state: AttentionState, completed: Date?) -> AttentionItem {
            AttentionItem(id: id, kind: .notification, text: id, state: state, createdBy: "p",
                          createdAt: base, updatedAt: base, completedAt: completed)
        }
        try store.insert(item("old", .done, completed: base.addingTimeInterval(-100)))
        try store.insert(item("new", .done, completed: base.addingTimeInterval(100)))
        try store.insert(item("open", .open, completed: nil))
        try store.record(AttentionAction(itemID: "old", action: .resolved))
        XCTAssertEqual(try store.purgeDone(completedBefore: base), 1)
        XCTAssertNil(try store.attentionItem(id: "old"))
        XCTAssertTrue(try store.actions(itemID: "old").isEmpty)
        XCTAssertNotNil(try store.attentionItem(id: "new"))
        XCTAssertNotNil(try store.attentionItem(id: "open"))
    }

    func testTranscriptKeepsAttributionAndOrder() throws {
        let attribution = ChatMessage.Attribution(
            sourceID: "attention:1", context: ["proj", "main"], name: "Review", iconSymbol: "eye",
            appIdentity: "ghostty")
        let user = ChatMessage(id: "u", role: .user, text: "hi", timestamp: Date(timeIntervalSince1970: 5),
                               attribution: attribution)
        let reply = ChatMessage(id: "a", role: .assistant, text: "hello", timestamp: Date(timeIntervalSince1970: 1))
        try store.append(user)
        try store.append(reply)
        try store.append(ChatMessage(id: "n", role: .notice, text: "note"))
        try store.append(ChatMessage(id: "e", role: .error, text: "bad"))

        let all = try store.transcript(limit: 10)
        XCTAssertEqual(all.map(\.id), ["u", "a", "n", "e"])
        XCTAssertEqual(all.map(\.role), [.user, .assistant, .notice, .error])
        XCTAssertEqual(all[0].attribution, attribution)
        XCTAssertNil(all[1].attribution)
        XCTAssertEqual(all[0].timestamp.timeIntervalSince1970, 5, accuracy: 0.001)
        XCTAssertEqual(try store.transcript(limit: 2).map(\.id), ["n", "e"])
        try store.clearTranscript()
        XCTAssertTrue(try store.transcript(limit: 10).isEmpty)
    }

    func testJobsUpsertKeepsStepsJSON() throws {
        let step = PartnerJobStep(name: "s", environment: .claude, command: "/review", condition: "always")
        var job = PartnerJob(id: "j", name: "Crawl", isEnabled: true, scheduleSeconds: 1800,
                             guidelines: "be kind", steps: [step], isBuiltIn: true)
        try store.upsert(job)
        XCTAssertEqual(try store.jobs(), [job])
        job.isEnabled = false
        job.scheduleSeconds = nil
        job.steps = []
        try store.upsert(job)
        XCTAssertEqual(try store.jobs(), [job])
        try store.deleteJob(id: "j")
        XCTAssertTrue(try store.jobs().isEmpty)
    }

    func testSessionsAndPurge() throws {
        let base = Date(timeIntervalSince1970: 3_000_000)
        var closed = PartnerStore.SessionRecord(id: "c", title: "Closed", directory: "/a", openedAt: base,
                                                closedAt: base.addingTimeInterval(10), finalScreen: "bye",
                                                reviewID: "r")
        let open = PartnerStore.SessionRecord(id: "o", title: "Open", directory: "/b",
                                              openedAt: base.addingTimeInterval(5))
        try store.upsert(closed)
        try store.upsert(open)
        XCTAssertEqual(Set(try store.sessions().map(\.id)), ["c", "o"])
        closed.title = "Renamed"
        try store.upsert(closed)
        XCTAssertEqual(try store.sessions().first { $0.id == "c" }, closed)
        XCTAssertEqual(try store.purgeSessions(closedBefore: base.addingTimeInterval(100)), 1)
        XCTAssertEqual(try store.sessions().map(\.id), ["o"])
    }

    func testSettingsAndSessionID() throws {
        XCTAssertNil(try store.sessionID())
        let id = UUID()
        try store.setSessionID(id)
        XCTAssertEqual(try store.sessionID(), id)
        try store.setSessionID(nil)
        XCTAssertNil(try store.sessionID())
        try store.setValue("v", forKey: "k")
        XCTAssertEqual(try store.value(forKey: "k"), "v")
        try store.setValue(nil, forKey: "k")
        XCTAssertNil(try store.value(forKey: "k"))
    }

    func testToolCallLog() throws {
        try store.logToolCall(caller: nil, name: "open", arguments: "{}", isError: true)
        try store.logToolCall(caller: "pane-1", name: "close", arguments: "{}", isError: false)
        let rows = try rawQuery(
            "SELECT name || ':' || COALESCE(caller, '-') || ':' || is_error FROM tool_call ORDER BY id")
        XCTAssertEqual(rows, ["open:-:1", "close:pane-1:0"])
    }

    func testLockRefusesLivePidAndTakesOverDeadOne() throws {
        XCTAssertNil(try store.liveLock())
        XCTAssertTrue(try store.acquireLock(pid: 100, isAlive: { _ in true }))
        XCTAssertEqual(try store.liveLock()?.pid, 100)
        XCTAssertFalse(try store.acquireLock(pid: 200, isAlive: { _ in true }))
        XCTAssertTrue(try store.acquireLock(pid: 200, isAlive: { _ in false }))
        XCTAssertEqual(try store.liveLock()?.pid, 200)
        try store.releaseLock(pid: 100)
        XCTAssertEqual(try store.liveLock()?.pid, 200)
        try store.releaseLock(pid: 200)
        XCTAssertNil(try store.liveLock())
    }

    func testChangesPublishAfterWrite() throws {
        var received: [PartnerStore.Change] = []
        store.changes.sink { received.append($0) }.store(in: &cancellables)
        try store.insert(AttentionItem(kind: .question, text: "q", createdBy: "p"))
        try store.append(ChatMessage(role: .user, text: "x"))
        try store.upsert(PartnerJob(id: "j", name: "n", isEnabled: true, guidelines: "", steps: []))
        try store.setValue("v", forKey: "k")
        try store.upsert(PartnerStore.SessionRecord(id: "s", title: "t", directory: "/", openedAt: Date()))
        XCTAssertEqual(received, [.attention, .transcript, .jobs, .settings, .sessions])
    }
}

private final class LockedResults: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Bool] = []
    func add(_ value: Bool) { lock.lock(); storage.append(value); lock.unlock() }
    var values: [Bool] { lock.lock(); defer { lock.unlock() }; return storage }
}
