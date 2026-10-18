import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// Verifies the ingest failure policy: transient DB errors leave the drop file
/// in place for retry, while permanent errors (and unparseable input) quarantine
/// it into `errors/` with a `.meta.json` reason sidecar.
final class IngestionQuarantineTests: XCTestCase {

    private var tmpDir: URL!
    private var dropDir: URL!
    private var errorsDir: URL!
    private var database: DaemonDatabase!
    private var handler: EventIngestor!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: "/tmp/iq-\(suffix)")
        dropDir = tmpDir.appendingPathComponent("drop")
        errorsDir = dropDir.appendingPathComponent("errors")
        try FileManager.default.createDirectory(at: dropDir, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: tmpDir.appendingPathComponent("t.db").path
        ).db
        handler = EventIngestor(
            dropDirectory: dropDir,
            database: database,
            sink: RecordingSink(),
            quarantine: QuarantineService(errorsDirectory: errorsDir, database: database),
            tailerQueueLabel: "test.transcript-tailer"
        )
    }

    override func tearDownWithError() throws {
        handler = nil
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    /// Writes a drop file and backdates its creation date past the scan's
    /// 0.1s freshness skip so `drainDirectoryOnce` processes it immediately.
    private func writeDrop(_ name: String, _ json: String) throws -> URL {
        let url = dropDir.appendingPathComponent(name)
        try json.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.creationDate: Date(timeIntervalSinceNow: -5)], ofItemAtPath: url.path
        )
        return url
    }

    private func errorFiles() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: errorsDir.path)) ?? []
    }

    private let validEvent =
        #"{"event":"PreToolUse","timestamp":"2026-01-01T00:00:00Z","hook_data":{"session_id":"s-iq-1"}}"#

    func testUnparseableFileIsQuarantinedWithReason() throws {
        let url = try writeDrop("100-bad.json", "this is not json")
        handler.drainDirectoryOnce()

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "source removed")
        let files = errorFiles()
        XCTAssertTrue(files.contains("error-100-bad.json"))
        let metaURL = errorsDir.appendingPathComponent("error-100-bad.json.meta.json")
        let meta = try JSONDecoder().decode(
            QuarantineMeta.self, from: Data(contentsOf: metaURL)
        )
        XCTAssertFalse(meta.reason.isEmpty)
    }

    func testBadFileGoesToTheConfiguredErrorsDirectoryNotDropErrors() throws {
        let elsewhere = tmpDir.appendingPathComponent("support/errors")
        let custom = EventIngestor(
            dropDirectory: dropDir,
            database: database,
            sink: RecordingSink(),
            quarantine: QuarantineService(errorsDirectory: elsewhere, database: database),
            tailerQueueLabel: "test.transcript-tailer"
        )
        let url = try writeDrop("105-elsewhere.json", "this is not json")
        custom.drainDirectoryOnce()

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "source removed")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: elsewhere.appendingPathComponent("error-105-elsewhere.json").path))
        XCTAssertTrue(errorFiles().isEmpty, "nothing lands in <drop>/errors")
    }

    func testValidSessionlessEventIsSkippedNotQuarantined() throws {
        // A StatusLine drop: valid JSON + event, but no session_id. It must be
        // discarded (source removed) WITHOUT quarantining — quarantining a non-error
        // is what lit the menubar badge.
        let statusLine =
            #"{"event":"StatusLine","timestamp":"t","hook_data":{"term_session_id":"w0:U","term_program":"iTerm.app"}}"#
        let url = try writeDrop("104-statusline.json", statusLine)
        handler.drainDirectoryOnce()

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "untrackable drop removed")
        XCTAssertTrue(errorFiles().isEmpty, "session-less valid event must NOT be quarantined")
    }

    func testPermanentIngestErrorIsQuarantinedWithSqliteCode() throws {
        handler.ingestOverride = { _ in throw DaemonDatabaseError.stepFailed(message: "constraint", code: 19) }
        let url = try writeDrop("101-perm.json", validEvent)
        handler.drainDirectoryOnce()

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "source removed")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: errorsDir.appendingPathComponent("error-101-perm.json").path),
            "event file moved into errors/ (not just deleted)"
        )
        let metaURL = errorsDir.appendingPathComponent("error-101-perm.json.meta.json")
        let meta = try JSONDecoder().decode(
            QuarantineMeta.self, from: Data(contentsOf: metaURL)
        )
        XCTAssertEqual(meta.sqliteCode, 19)
        XCTAssertEqual(meta.eventType, "PreToolUse")
        XCTAssertEqual(meta.sessionId, "s-iq-1")
    }

    func testTransientIngestErrorLeavesFileForRetry() throws {
        handler.ingestOverride = { _ in throw DaemonDatabaseError.stepFailed(message: "busy", code: 5) }
        let url = try writeDrop("102-transient.json", validEvent)
        handler.drainDirectoryOnce()

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "transient: file left in place")
        XCTAssertTrue(errorFiles().isEmpty, "transient: nothing quarantined")
    }

    func testPermanentQuarantineRecordsDBLogRow() throws {
        handler.ingestOverride = { _ in throw DaemonDatabaseError.stepFailed(message: "constraint", code: 19) }
        _ = try writeDrop("103-log.json", validEvent)
        handler.drainDirectoryOnce()

        let row = try database.recentIngestionErrors().first { $0.filename == "error-103-log.json" }
        XCTAssertNotNil(row, "quarantine mirrored the failure into the DB log")
        XCTAssertEqual(row?.retryCount, 0, "first quarantine has no retries yet")
        XCTAssertEqual(row?.status, "failing")
        XCTAssertEqual(row?.sqliteCode, 19)
        XCTAssertEqual(row?.eventType, "PreToolUse")
    }

    // MARK: - Empty drop files (a writer that died mid-write)

    func testEmptyDropFileIsDiscardedNotQuarantined() throws {
        // A 0-byte spill is what a non-atomic write leaves behind when the daemon
        // is killed between creating the file and filling it. Quarantining it
        // burns the retry budget on a file that can never parse, and then the
        // menubar badge stays lit forever over no event at all.
        let url = try writeDrop("105-empty.json", "")
        handler.drainDirectoryOnce()

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "empty drop removed")
        XCTAssertTrue(errorFiles().isEmpty, "an empty drop must NOT be quarantined")
    }

    func testEmptyDropFileIsLoggedAsLost() throws {
        _ = try writeDrop("106-empty.json", "   \n ")
        handler.drainDirectoryOnce()

        let row = try database.recentIngestionErrors().first { $0.filename == "106-empty.json" }
        XCTAssertEqual(row?.status, "lost", "the loss is recorded, just not as a live failure")
        XCTAssertNotNil(row?.resolvedAt, "terminal on arrival — nothing left to retry")
        XCTAssertEqual(row?.retryCount, 0)
    }

    func testLostRowsDoNotLightTheBadge() throws {
        _ = try writeDrop("107-empty.json", "")
        handler.drainDirectoryOnce()

        let service = QuarantineService(errorsDirectory: errorsDir, database: database)
        XCTAssertEqual(service.counts().exhausted, 0, "badge counts quarantine files, and there are none")
        XCTAssertEqual(service.counts().total, 0)
    }
}
