import XCTest
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitDatabase

/// The `ai_interactions` log: storage semantics (insert-time prune, list truncation,
/// full-text detail) and the `DaemonAIChat.complete(feature:)` overload recording ok
/// and error rows without altering the completion's behavior.
final class AIInteractionLogTests: XCTestCase {

    var database: DaemonDatabase!
    var tmpPath: String!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    private func insertRow(
        feature: String = "summarize",
        sessionId: String = "sess-1",
        userPrompt: String = "prompt",
        response: String = "reply",
        outcome: String = "ok",
        error: String = ""
    ) throws {
        try database.insertAIInteraction(
            feature: feature, sessionId: sessionId, providerKind: "cli", configName: "",
            model: "haiku", systemPrompt: "sys", userPrompt: userPrompt,
            response: response, durationMs: 12, outcome: outcome, error: error
        )
    }

    // MARK: - Storage

    func testInsertAndListRoundTrip() throws {
        try insertRow()
        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.count, 1)
        let row = rows[0]
        XCTAssertEqual(row.feature, "summarize")
        XCTAssertEqual(row.sessionId, "sess-1")
        XCTAssertEqual(row.providerKind, "cli")
        XCTAssertEqual(row.model, "haiku")
        XCTAssertEqual(row.systemPrompt, "sys")
        XCTAssertEqual(row.userPrompt, "prompt")
        XCTAssertEqual(row.response, "reply")
        XCTAssertEqual(row.durationMs, 12)
        XCTAssertEqual(row.outcome, "ok")
        XCTAssertEqual(row.error, "")
        XCTAssertFalse(row.truncated)
        XCTAssertFalse(row.createdAt.isEmpty)
    }

    func testListTruncatesLongTextAndFlagsIt() throws {
        let long = String(repeating: "x", count: 400)
        try insertRow(userPrompt: long)
        try insertRow(sessionId: "sess-short")

        let rows = try database.fetchAIInteractions()
        // Newest first: the short row leads.
        XCTAssertEqual(rows[0].sessionId, "sess-short")
        XCTAssertFalse(rows[0].truncated)
        XCTAssertEqual(rows[1].userPrompt.count, 300, "list reads cut text fields to 300")
        XCTAssertTrue(rows[1].truncated)

        // The by-id read returns the full text.
        let full = try XCTUnwrap(database.fetchAIInteraction(id: rows[1].id))
        XCTAssertEqual(full.userPrompt, long)
        XCTAssertFalse(full.truncated)
    }

    func testFetchByIdNilWhenAbsent() throws {
        XCTAssertNil(try database.fetchAIInteraction(id: 12345))
    }

    func testInsertPrunesToNewest500() throws {
        for index in 0..<(DaemonDatabase.maxAIInteractionRows + 2) {
            try insertRow(sessionId: "sess-\(index)")
        }
        let rows = try database.fetchAIInteractions(limit: 1000)
        XCTAssertEqual(rows.count, DaemonDatabase.maxAIInteractionRows)
        XCTAssertEqual(rows.first?.sessionId, "sess-\(DaemonDatabase.maxAIInteractionRows + 1)",
                       "newest row survives")
        XCTAssertEqual(rows.last?.sessionId, "sess-2", "the two oldest rows were pruned")
    }

    // MARK: - Adapter recording (CLI path — no provider config in a fresh DB)

    func testCompleteRecordsOkRow() async throws {
        let reply = try await DaemonAIChat.complete(
            feature: .oversight, sessionId: "sess-ok",
            systemPrompt: "sys", userPrompt: "user", maxTokens: 8,
            database: database,
            cliRunner: { _, _, _, _ in "COMPACT: fine" }
        )
        XCTAssertEqual(reply, "COMPACT: fine")

        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].feature, "oversight")
        XCTAssertEqual(rows[0].sessionId, "sess-ok")
        XCTAssertEqual(rows[0].providerKind, "cli")
        XCTAssertEqual(rows[0].model, "haiku", "CLI path records the cli model")
        XCTAssertEqual(rows[0].userPrompt, "user")
        XCTAssertEqual(rows[0].response, "COMPACT: fine")
        XCTAssertEqual(rows[0].outcome, "ok")
    }

    func testCompleteRecordsErrorRowAndRethrows() async throws {
        struct FakeFailure: Error {}
        do {
            _ = try await DaemonAIChat.complete(
                feature: .summarize, sessionId: nil,
                systemPrompt: "sys", userPrompt: "user", maxTokens: 8,
                database: database,
                cliRunner: { _, _, _, _ in throw FakeFailure() }
            )
            XCTFail("the transport error must rethrow")
        } catch {
            // expected — recording must not swallow the error
        }

        let rows = try database.fetchAIInteractions()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].feature, "summarize")
        XCTAssertEqual(rows[0].sessionId, "", "nil sessionId stores as the '' convention")
        XCTAssertEqual(rows[0].outcome, "error")
        XCTAssertEqual(rows[0].response, "")
        XCTAssertFalse(rows[0].error.isEmpty, "the failure description is recorded")
    }
}
