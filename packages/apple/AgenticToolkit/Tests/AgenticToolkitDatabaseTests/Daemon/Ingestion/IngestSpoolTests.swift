import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// Verifies the capture queue's contract: events go in whole, come back out in
/// arrival order, leave only when the caller says so, and a permanent failure
/// is counted rather than acted on.
final class IngestSpoolTests: XCTestCase {

    private var tmpDir: URL!
    private var spool: IngestSpool!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-spool-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        spool = try IngestSpool(path: tmpDir.appendingPathComponent("ingest.db").path)
    }

    override func tearDownWithError() throws {
        spool = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func event(
        _ type: String = "PreToolUse",
        session: String = "s-1",
        context: [String: Any]? = nil
    ) -> ParsedEvent {
        ParsedEvent(
            eventType: type,
            timestamp: "2026-01-01T00:00:00Z",
            hookData: ["session_id": session, "tool_name": "Bash"],
            context: context,
            accountEmail: "a@b.c"
        )
    }

    // MARK: - In and out

    func testPendingBatchReturnsEventsInArrivalOrder() throws {
        try spool.enqueue(event("SessionStart"))
        try spool.enqueue(event("PreToolUse"))
        try spool.enqueue(event("PostToolUse"))

        let batch = try spool.pendingBatch(limit: 10)
        XCTAssertEqual(batch.map(\.eventType), ["SessionStart", "PreToolUse", "PostToolUse"])
        XCTAssertEqual(batch.map(\.attempts), [0, 0, 0])
    }

    func testPendingBatchHonoursTheLimitAndKeepsTheOldest() throws {
        for index in 0..<5 { try spool.enqueue(event("E\(index)")) }

        let batch = try spool.pendingBatch(limit: 2)
        XCTAssertEqual(batch.map(\.eventType), ["E0", "E1"])
    }

    /// The spool stores the drop-file envelope verbatim so the drain can reuse
    /// the parser every other capture path already uses. If this round trip ever
    /// stops being lossless, the spool has grown a second format.
    func testEnvelopeRoundTripsThroughTheDropFileParser() throws {
        try spool.enqueue(event("PreToolUse", session: "s-rt", context: ["cwd": "/tmp/p"]))

        let row = try XCTUnwrap(try spool.pendingBatch(limit: 1).first)
        let json = try XCTUnwrap(String(data: row.envelope, encoding: .utf8))
        guard case .event(let parsed) = ParseResult.parse(envelopeJSON: json) else {
            return XCTFail("envelope did not parse back into an event")
        }
        XCTAssertEqual(parsed.eventType, "PreToolUse")
        XCTAssertEqual(parsed.timestamp, "2026-01-01T00:00:00Z")
        XCTAssertEqual(parsed.sessionId, "s-rt")
        XCTAssertEqual(parsed.accountEmail, "a@b.c")
        XCTAssertEqual(parsed.context?["cwd"] as? String, "/tmp/p")
    }

    func testCompleteRemovesOnlyTheNamedEvents() throws {
        try spool.enqueue(event("A"))
        try spool.enqueue(event("B"))
        try spool.enqueue(event("C"))
        let batch = try spool.pendingBatch(limit: 10)

        try spool.complete(ids: [batch[0].id, batch[2].id])

        XCTAssertEqual(try spool.pendingBatch(limit: 10).map(\.eventType), ["B"])
    }

    func testCompleteWithNoIdsIsANoOp() throws {
        try spool.enqueue(event())
        try spool.complete(ids: [])
        XCTAssertEqual(spool.pendingCount(), 1)
    }

    // MARK: - Failure accounting

    func testRecordFailureCountsAttemptsAndReportsExhaustionOnTheLast() throws {
        try spool.enqueue(event())
        let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first).id

        for attempt in 1..<IngestSpool.maxAttempts {
            XCTAssertFalse(
                try spool.recordFailure(id: id, reason: "boom"),
                "attempt \(attempt) of \(IngestSpool.maxAttempts) should not exhaust"
            )
        }
        XCTAssertTrue(try spool.recordFailure(id: id, reason: "boom"))
        XCTAssertEqual(try spool.pendingBatch(limit: 1).first?.attempts, IngestSpool.maxAttempts)
    }

    /// A row that vanished under the drain reads as exhausted, so the caller
    /// quarantines the copy it is holding instead of looping on it forever.
    func testRecordFailureOnAVanishedRowReadsAsExhausted() throws {
        try spool.enqueue(event())
        let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first).id
        try spool.complete(ids: [id])

        XCTAssertTrue(try spool.recordFailure(id: id, reason: "gone"))
    }

    // MARK: - Status

    func testStatusReportsPendingCountAndOldestAge() throws {
        XCTAssertEqual(try spool.status().pending, 0)
        XCTAssertNil(try spool.status().oldestPendingAgeSeconds)

        let oldest = Date(timeIntervalSinceNow: -30)
        try spool.enqueue(event("old"), now: oldest)
        try spool.enqueue(event("new"), now: Date())

        let status = try spool.status(now: oldest.addingTimeInterval(30))
        XCTAssertEqual(status.pending, 2)
        XCTAssertEqual(try XCTUnwrap(status.oldestPendingAgeSeconds), 30, accuracy: 1)
    }

    /// The schema is a `CREATE TABLE IF NOT EXISTS` and must stay one: reopening
    /// the same file has to be a no-op that keeps everything already queued.
    func testReopeningAnExistingSpoolKeepsItsEvents() throws {
        try spool.enqueue(event("kept"))
        spool = nil

        let reopened = try IngestSpool(path: tmpDir.appendingPathComponent("ingest.db").path)
        XCTAssertEqual(try reopened.pendingBatch(limit: 10).map(\.eventType), ["kept"])
    }
}
