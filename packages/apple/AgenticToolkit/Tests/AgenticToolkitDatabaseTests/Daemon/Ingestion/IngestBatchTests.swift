import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// Verifies `EventIngestor.ingestBatch` — the drain's fast path. It has to land a
/// whole batch in one main-DB transaction and still publish each event
/// individually afterwards, because a live feed is fed by those broadcasts and a
/// batched write must not turn it into a polling feed.
final class IngestBatchTests: XCTestCase {

    private var tmpDir: URL!
    private var database: DaemonDatabase!
    private var sink: RecordingSink!
    private var ingestion: EventIngestor!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("batch-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: tmpDir.appendingPathComponent("t.db").path
        ).db

        sink = RecordingSink()
        let drop = tmpDir.appendingPathComponent("drop")
        ingestion = EventIngestor(
            dropDirectory: drop,
            database: database,
            sink: sink,
            quarantine: QuarantineService(
                errorsDirectory: drop.appendingPathComponent("errors"), database: database
            ),
            tailerQueueLabel: "test.transcript-tailer"
        )
    }

    override func tearDownWithError() throws {
        ingestion = nil
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func event(_ type: String, session: String, tool: String = "Bash") -> ParsedEvent {
        ParsedEvent(
            eventType: type, timestamp: "2026-01-01T00:00:00Z",
            hookData: ["session_id": session, "tool_name": tool],
            context: nil, accountEmail: ""
        )
    }

    func testABatchLandsEveryEventAndBroadcastsEachOne() throws {
        try ingestion.ingestBatch([
            event("SessionStart", session: "s-b1"),
            event("PreToolUse", session: "s-b1"),
            event("PostToolUse", session: "s-b1")
        ])

        let stored = try database.fetchEvents(sessionId: "s-b1", eventType: nil, limit: 100)
        XCTAssertEqual(stored.count, 3)
        XCTAssertEqual(sink.eventTypes.count, 3)
    }

    /// Events from different sessions arrive interleaved in one spool batch;
    /// batching must not silently scope a pass to one session.
    func testABatchSpanningSessionsLandsUnderEachSession() throws {
        try ingestion.ingestBatch([
            event("PreToolUse", session: "s-b2"),
            event("PreToolUse", session: "s-b3"),
            event("PostToolUse", session: "s-b2")
        ])

        XCTAssertEqual(try database.fetchEvents(sessionId: "s-b2", eventType: nil, limit: 100).count, 2)
        XCTAssertEqual(try database.fetchEvents(sessionId: "s-b3", eventType: nil, limit: 100).count, 1)
    }

    func testAnEmptyBatchWritesNothingAndBroadcastsNothing() throws {
        try ingestion.ingestBatch([])

        XCTAssertTrue(sink.events.isEmpty)
    }

    /// A batch of one must behave exactly like `ingest`, because that is what a
    /// quiet daemon's drain does all day.
    func testASingleEventBatchMatchesTheSingleEventPath() throws {
        try ingestion.ingestBatch([event("PreToolUse", session: "s-b4", tool: "Read")])

        let stored = try database.fetchEvents(sessionId: "s-b4", eventType: "PreToolUse", limit: 10)
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(sink.events.count, 1)
        XCTAssertEqual(sink.events.first?.sessionId, "s-b4")
    }
}
