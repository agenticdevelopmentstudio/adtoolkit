import XCTest
@testable import AgenticToolkitDatabase

/// Backstops the chunked-drain rescheduling contract.
///
/// `rerunImmediately` re-runs the pass at ZERO delay, and a pass that errored
/// deliberately holds the mtime cursor back (`JSONLImporter`) so the failed file
/// is re-offered rather than sealed behind the cursor. Chaining immediately after
/// a failure would re-select the identical batch, so a permanently-unreadable file
/// would spin the writer lane forever. A clean chunk must still chain immediately,
/// or a large backfill drains at one batch per interval.
final class JSONLImportPassTests: XCTestCase {

    private var tmp: URL!
    private var database: DaemonDatabase!
    private var dbPath: String!
    private var root: URL!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("import-pass-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let made = try TestDaemonDatabase.makeSessionDatabase()
        database = made.db
        dbPath = made.path
        root = tmp.appendingPathComponent("projects")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: dbPath)
        try? FileManager.default.removeItem(at: tmp)
    }

    private func writeTranscript(_ name: String, mtime: Date, readable: Bool = true) throws {
        let url = root.appendingPathComponent(name)
        let stem = name.replacingOccurrences(of: ".jsonl", with: "")
        // The turn is stamped at the file's mtime: the importer drops turns older
        // than `since`, so a fixed timestamp would hide whether a file was imported.
        let stamp = ISO8601DateFormatter().string(from: mtime)
        let line = """
        {"type":"assistant","sessionId":"\(stem)","timestamp":"\(stamp)",\
        "cwd":"/work","message":{"id":"m-\(stem)","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":10,"output_tokens":5},\
        "content":[{"type":"tool_use","name":"Edit","input":{}}]}}
        """
        try line.write(to: url, atomically: true, encoding: .utf8)
        var attrs: [FileAttributeKey: Any] = [.modificationDate: mtime]
        if !readable { attrs[.posixPermissions] = NSNumber(value: 0o000) }
        try FileManager.default.setAttributes(attrs, ofItemAtPath: url.path)
    }

    private func pass(filesPerBatch: Int, window: TimeInterval? = nil) -> JSONLImportPass {
        JSONLImportPass(
            database: database, sourceDirectory: root,
            filesPerBatch: filesPerBatch, initialImportWindow: window
        )
    }

    /// The hot-loop guard: an unreadable oldest file leaves the cursor parked,
    /// so an immediate re-enqueue would re-process the same batch forever.
    func testDoesNotChainImmediatelyWhenAFileFailed() throws {
        try writeTranscript("bad.jsonl", mtime: Date(timeIntervalSince1970: 1_700_000_000), readable: false)
        try writeTranscript("later.jsonl", mtime: Date(timeIntervalSince1970: 1_700_001_000))
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o644)],
                ofItemAtPath: root.appendingPathComponent("bad.jsonl").path
            )
        }

        let outcome = try pass(filesPerBatch: 1).run()
        XCTAssertFalse(outcome.rerunImmediately,
                       "an errored pass must not re-enqueue at zero delay — the next pass sees the same batch")

        let cursor = try database.setting(for: JSONLImportPass.lastRunKey) ?? ""
        XCTAssertTrue(cursor.isEmpty, "a held-back cutoff must never be seeded past the failed file")
    }

    /// A clean chunk with files remaining still chains at zero delay.
    func testChainsImmediatelyWhenChunkIsCleanAndMoreRemain() throws {
        try writeTranscript("a.jsonl", mtime: Date(timeIntervalSince1970: 1_700_000_000))
        try writeTranscript("b.jsonl", mtime: Date(timeIntervalSince1970: 1_700_001_000))

        let outcome = try pass(filesPerBatch: 1).run()
        XCTAssertTrue(outcome.rerunImmediately, "a clean partial drain re-enqueues immediately")

        let cursor = try database.setting(for: JSONLImportPass.lastRunKey) ?? ""
        XCTAssertFalse(cursor.isEmpty, "a clean chunk advances the cursor to its newest file")
    }

    /// Whole-second instant `seconds` ago, so the turn stamp and mtime agree exactly.
    private func ago(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: (Date().timeIntervalSince1970 - seconds).rounded())
    }

    private func storedCutoff() throws -> Date? {
        guard let raw = try database.setting(for: JSONLImportPass.lastRunKey), !raw.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }

    /// With no stored cutoff, `initialImportWindow` bounds how far back the first
    /// pass reaches: a transcript older than the window is not imported.
    func testInitialImportWindowSkipsOlderTranscripts() throws {
        try writeTranscript("old.jsonl", mtime: ago(10 * 86_400))
        let newMtime = ago(60)
        try writeTranscript("new.jsonl", mtime: newMtime)

        let outcome = try pass(filesPerBatch: 10, window: 86_400).run()
        XCTAssertEqual(outcome.summary.filesScanned, 1, "only the file inside the window is eligible")
        XCTAssertNotNil(try database.transcriptTurn(messageId: "m-new"), "the in-window file is imported")
        XCTAssertNil(try database.transcriptTurn(messageId: "m-old"), "the out-of-window file is not")

        let cutoff = try XCTUnwrap(try storedCutoff())
        XCTAssertEqual(cutoff.timeIntervalSince1970, newMtime.timeIntervalSince1970, accuracy: 2,
                       "the cutoff is the newest imported file's mtime")
        XCTAssertGreaterThan(cutoff, Date(timeIntervalSinceNow: -86_400))
    }

    /// With no window and no stored cutoff, everything is eligible, however old.
    func testNilWindowWithNoSettingImportsOldTranscripts() throws {
        let mtime = ago(40 * 86_400)
        try writeTranscript("ancient.jsonl", mtime: mtime)

        let outcome = try pass(filesPerBatch: 10, window: nil).run()
        XCTAssertEqual(outcome.summary.filesScanned, 1)
        XCTAssertNotNil(try database.transcriptTurn(messageId: "m-ancient"), "a 40-day-old file is imported")
        let cutoff = try XCTUnwrap(try storedCutoff())
        XCTAssertEqual(cutoff.timeIntervalSince1970, mtime.timeIntervalSince1970, accuracy: 2)
    }

    /// A stored cutoff beats the window, so a window can never rewind a resume point.
    func testStoredCutoffWinsOverInitialImportWindow() throws {
        let storedAt = ago(3_600)
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try database.setSetting(JSONLImportPass.lastRunKey, fractional.string(from: storedAt))

        // Inside the 90-day window, but before the stored cutoff.
        try writeTranscript("between.jsonl", mtime: ago(2 * 86_400))
        let recentMtime = ago(1_800)
        try writeTranscript("recent.jsonl", mtime: recentMtime)

        let outcome = try pass(filesPerBatch: 10, window: 90 * 86_400).run()
        XCTAssertEqual(outcome.summary.filesScanned, 1, "only the file after the stored cutoff is eligible")
        XCTAssertNotNil(try database.transcriptTurn(messageId: "m-recent"))
        XCTAssertNil(try database.transcriptTurn(messageId: "m-between"),
                     "the window must not reach behind a stored cutoff")

        let cutoff = try XCTUnwrap(try storedCutoff())
        XCTAssertEqual(cutoff.timeIntervalSince1970, recentMtime.timeIntervalSince1970, accuracy: 2)
        XCTAssertGreaterThan(cutoff, storedAt)
    }
}
