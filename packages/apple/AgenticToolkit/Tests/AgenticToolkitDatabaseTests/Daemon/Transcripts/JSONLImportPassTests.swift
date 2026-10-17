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
        let line = """
        {"type":"assistant","sessionId":"\(stem)","timestamp":"2026-04-14T10:00:00Z",\
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

    /// With no stored cutoff, `initialImportWindow` bounds how far back the first
    /// pass reaches: a transcript older than the window is not imported.
    func testInitialImportWindowSkipsOlderTranscripts() throws {
        try writeTranscript("old.jsonl", mtime: Date(timeIntervalSinceNow: -10 * 86_400))
        try writeTranscript("new.jsonl", mtime: Date(timeIntervalSinceNow: -60))

        let outcome = try pass(filesPerBatch: 10, window: 86_400).run()
        XCTAssertEqual(outcome.summary.filesScanned, 1, "only the file inside the window is eligible")
        let cursor = try database.setting(for: JSONLImportPass.lastRunKey) ?? ""
        XCTAssertFalse(cursor.isEmpty, "the pass records where it got to")
    }
}
