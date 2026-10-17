import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The composed capture-to-database path: a captured event is spooled, the drain
/// writes it, and the sink hears about it. Nothing is written to the main
/// database before the drain starts.
final class IngestionPipelineTests: XCTestCase {

    private var tmpDir: URL!
    private var database: DaemonDatabase!
    private var sink: RecordingSink!
    private var pipeline: IngestionPipeline!

    override func setUpWithError() throws {
        // Unix socket paths cap at 104 bytes on macOS, so keep the directory short.
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: "/tmp/pipe-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: tmpDir.appendingPathComponent("t.db").path
        ).db
        sink = RecordingSink()
        let drop = tmpDir.appendingPathComponent("drop")
        pipeline = IngestionPipeline(
            paths: .init(
                dropDirectory: drop,
                errorsDirectory: drop.appendingPathComponent("errors"),
                socketPath: tmpDir.appendingPathComponent("s").path
            ),
            spool: try IngestSpool(path: tmpDir.appendingPathComponent("ingest.db").path),
            database: database,
            sink: sink,
            queueLabel: { "test.\($0)" },
            decode: { _ in throw SocketDecodeFailure.malformed }
        )
    }

    override func tearDown() async throws {
        await pipeline.stop()
        pipeline = nil
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func event(session: String) -> ParsedEvent {
        ParsedEvent(
            eventType: "PreToolUse", timestamp: "2026-01-01T00:00:00Z",
            hookData: ["session_id": session, "tool_name": "Bash"],
            context: nil, accountEmail: ""
        )
    }

    func testACapturedEventIsSpooledAndNotWrittenUntilTheDrainStarts() throws {
        try pipeline.capture(event(session: "s-p1"))

        XCTAssertEqual(pipeline.spool.pendingCount(), 1)
        XCTAssertTrue(try database.fetchEvents(sessionId: "s-p1", eventType: nil, limit: 10).isEmpty)
        XCTAssertTrue(sink.events.isEmpty)
    }

    func testTheDrainWritesASpooledEventAndPublishesIt() async throws {
        try pipeline.capture(event(session: "s-p2"))
        pipeline.startDraining()

        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while ContinuousClock.now < deadline {
            if try database.fetchEvents(sessionId: "s-p2", eventType: nil, limit: 10).count == 1 { break }
            try await Task.sleep(for: .milliseconds(20))
        }

        XCTAssertEqual(try database.fetchEvents(sessionId: "s-p2", eventType: nil, limit: 10).count, 1)
        XCTAssertEqual(sink.events.first?.sessionId, "s-p2")
    }

    func testRetryIngestWritesStraightToTheDatabase() throws {
        try pipeline.retryIngest(event(session: "s-p3"))

        XCTAssertEqual(try database.fetchEvents(sessionId: "s-p3", eventType: nil, limit: 10).count, 1)
        XCTAssertEqual(pipeline.spool.pendingCount(), 0)
    }

    func testWriteDropFileFallbackLeavesAReadableEnvelope() throws {
        let dir = tmpDir.appendingPathComponent("spill")
        try IngestionPipeline.writeDropFile(event(session: "s-p4"), into: dir)

        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertEqual(files.count, 1)
        XCTAssertTrue(files[0].hasPrefix("spill-"))
        let raw = try String(contentsOf: dir.appendingPathComponent(files[0]), encoding: .utf8)
        guard case .event(let reread) = EventIngestor.parseEventFile(rawJson: raw) else {
            return XCTFail("the spill file must parse back into an event")
        }
        XCTAssertEqual(reread.eventType, "PreToolUse")
    }
}
