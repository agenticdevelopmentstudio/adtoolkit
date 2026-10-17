import AgenticToolkitCore
import XCTest
import SQLite3
@testable import AgenticToolkitDatabase

/// The tailer's contract: a line written to a transcript is in the database
/// within about as long as it takes to read it, and a session writing
/// continuously costs one read per quiet period rather than one per hook.
///
/// The quiet period is set to a fraction of a second here. The pacing is what is
/// being asserted, not the two-second production value, and every assertion below
/// waits for a condition with a generous ceiling rather than sleeping a fixed
/// time — so a slow machine makes these slower, never flakier.
final class TranscriptTailerTests: XCTestCase {

    private var tmp: URL!
    private var dbPath: String!
    private var database: DaemonDatabase!
    private var transcript: URL!

    private let quietPeriod: Duration = .milliseconds(200)

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("tailer-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let claudeJSONPath = tmp.appendingPathComponent(".claude.json").path
        try #"{"oauthAccount": {"emailAddress": "tailer-test@acct.com"}}"#
            .write(toFile: claudeJSONPath, atomically: true, encoding: .utf8)
        dbPath = tmp.appendingPathComponent("test.db").path
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: dbPath, accountResolver: AccountResolver(claudeJSONPath: claudeJSONPath)
        ).db
        transcript = tmp.appendingPathComponent("projects/p/s1.jsonl")
        try FileManager.default.createDirectory(
            at: transcript.deletingLastPathComponent(), withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    // MARK: - Tests

    /// The whole point: no sweep ran, and the line is in the database.
    func testAHookPullsTheLineInWithoutASweep() async throws {
        try append(userLine(text: "why is it slow"))

        await tailer().noteActivity(transcriptPath: transcript.path, sessionId: "s1")

        try await eventually("the line is captured") { try self.lineCount() == 1 }
    }

    /// Hooks inside the quiet period do not each start a pass — that is what
    /// keeps a tool-heavy turn from becoming a read per tool call — and the line
    /// they announced is still not lost: one catch-up runs when the period ends.
    ///
    /// The negative half is safe to assert because the first pass has finished
    /// reading by the time its rows are visible, so nothing but a second pass can
    /// account for the second line appearing.
    func testHooksInsideTheQuietPeriodCollapseIntoOneCatchUp() async throws {
        try append(userLine(text: "first"))
        let tailer = tailer()

        await tailer.noteActivity(transcriptPath: transcript.path, sessionId: "s1")
        try await eventually("the first line is captured") { try self.lineCount() == 1 }

        try append(userLine(text: "second"))
        for _ in 0..<100 {
            await tailer.noteActivity(transcriptPath: transcript.path, sessionId: "s1")
        }

        try await Task.sleep(for: quietPeriod / 4)
        XCTAssertEqual(try lineCount(), 1, "a hook inside the period starts no pass of its own")

        try await eventually("the one owed pass runs when the period ends") {
            try self.lineCount() == 2
        }
    }

    /// Two sessions write at once; neither waits on the other's file.
    func testSessionsAreTailedIndependently() async throws {
        let second = tmp.appendingPathComponent("projects/p/s2.jsonl")
        try append(userLine(text: "from one"))
        try userLine(text: "from two", session: "s2").appending("\n")
            .write(to: second, atomically: true, encoding: .utf8)
        let tailer = tailer()

        await tailer.noteActivity(transcriptPath: transcript.path, sessionId: "s1")
        await tailer.noteActivity(transcriptPath: second.path, sessionId: "s2")

        try await eventually("both sessions land") {
            try self.lineCount(session: "s1") == 1 && self.lineCount(session: "s2") == 1
        }
    }

    /// A hook for a session whose transcript is gone (or was never written)
    /// is nothing to do, not a failure to report.
    func testAMissingTranscriptIsNotAnError() async throws {
        let tailer = tailer()

        await tailer.noteActivity(
            transcriptPath: tmp.appendingPathComponent("nope.jsonl").path, sessionId: "s1")
        await tailer.noteActivity(transcriptPath: "", sessionId: "s1")

        try await Task.sleep(for: quietPeriod * 2)
        XCTAssertEqual(try lineCount(), 0)
    }

    // MARK: - Metrics

    /// The tail consumes the file's bytes, so the five-minute sweep finds it
    /// unchanged and never touches it again. Whatever the tail declines to
    /// compute, nothing else will — so the session's totals are its to write.
    func testATailedSessionsMetricsAreWritten() async throws {
        try append(assistantLine(messageId: "m1"))

        await tailer().noteActivity(transcriptPath: transcript.path, sessionId: "s1")

        try await eventually("the metrics are written") { try self.turnCount() == 1 }
    }

    /// The recompute is a whole-session aggregate, so it runs on a clock of its
    /// own rather than on every pass. The clock is pushed out of reach here:
    /// the only thing that can bring the totals up to date is the refresh that
    /// runs when the writing stops.
    func testTheTotalsAreCompleteOnceTheWritingStops() async throws {
        let tailer = TranscriptTailer(
            database: database, quietPeriod: quietPeriod, metricsInterval: .seconds(3600))
        try append(assistantLine(messageId: "m1"))

        await tailer.noteActivity(transcriptPath: transcript.path, sessionId: "s1")
        try await eventually("the first turn is counted") { try self.turnCount() == 1 }

        // Inside the quiet period, so this rides the catch-up pass — which is
        // nowhere near due for a recompute of its own.
        try append(assistantLine(messageId: "m2"))
        await tailer.noteActivity(transcriptPath: transcript.path, sessionId: "s1")

        try await eventually("the second turn is counted once the burst ends") {
            try self.turnCount() == 2
        }
    }

    // MARK: - Helpers

    private func tailer() -> TranscriptTailer {
        TranscriptTailer(database: database, quietPeriod: quietPeriod)
    }

    private func assistantLine(messageId: String, session: String = "s1") -> String {
        """
        {"type":"assistant","sessionId":"\(session)","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/work/test","gitBranch":"main","message":{"id":"\(messageId)",\
        "model":"claude-sonnet-4-6","usage":{"input_tokens":100,"output_tokens":50,\
        "cache_read_input_tokens":0,"cache_creation_input_tokens":0},\
        "content":[{"type":"tool_use","name":"Edit","input":{}}]}}
        """
    }

    private func turnCount(session: String = "s1") throws -> Int {
        try scalar("SELECT coalesce(sum(turn_count), 0) FROM session_metrics "
                   + "WHERE session_id = '\(session)'")
    }

    private func userLine(text: String, session: String = "s1") -> String {
        """
        {"type":"user","sessionId":"\(session)","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/work/test","message":{"role":"user","content":"\(text)"}}
        """
    }

    private func append(_ line: String) throws {
        let existing = (try? String(contentsOf: transcript, encoding: .utf8)) ?? ""
        try (existing + line + "\n").write(to: transcript, atomically: true, encoding: .utf8)
    }

    private func lineCount(session: String = "s1") throws -> Int {
        try scalar("SELECT count(*) FROM transcript_lines WHERE session_id = '\(session)'")
    }

    /// Reads one integer out of the database the tailer is writing. The SQL is a
    /// controlled test literal.
    private func scalar(_ sql: String) throws -> Int {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(dbPath, &handle), SQLITE_OK)
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        XCTAssertEqual(sqlite3_prepare_v2(handle, sql, -1, &stmt, nil), SQLITE_OK)
        defer { sqlite3_finalize(stmt) }
        XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
        return Int(sqlite3_column_int(stmt, 0))
    }

    /// Polls until `condition` holds or the ceiling passes. The tailer's work is
    /// asynchronous by design, so there is no completion to await — but every
    /// condition here is reached in milliseconds when the code is right, which
    /// makes a wide ceiling free and a fixed sleep the only real flake risk.
    private func eventually(
        _ what: String,
        within ceiling: Duration = .seconds(10),
        condition: () throws -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: ceiling)
        while ContinuousClock.now < deadline {
            if try condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("timed out waiting for: \(what)")
    }
}
