import XCTest
import SQLite3
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

final class JSONLImporterTests: XCTestCase {

    var tmp: URL!
    var database: DaemonDatabase!
    var dbPath: String!
    var jsonlRoot: URL!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("importer-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        // Pin the account resolver to a known, controlled account so the
        // account-attribution tests below assert an exact value rather than
        // whatever happens to be logged in on the machine running the tests.
        let claudeJSONPath = tmp.appendingPathComponent(".claude.json").path
        try #"{"oauthAccount": {"emailAddress": "import-test@acct.com"}}"#
            .write(toFile: claudeJSONPath, atomically: true, encoding: .utf8)
        dbPath = tmp.appendingPathComponent("test.db").path
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: dbPath, accountResolver: AccountResolver(claudeJSONPath: claudeJSONPath)
        ).db
        jsonlRoot = tmp.appendingPathComponent("projects")
        try FileManager.default.createDirectory(at: jsonlRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    // MARK: - Helpers

    private func writeJSONL(_ lines: [String], at relativePath: String) throws {
        let url = jsonlRoot.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private func assistantLine(
        session: String,
        messageId: String,
        tool: String? = nil,
        input: Int = 100,
        output: Int = 50,
        timestamp: String = "2026-04-14T10:00:00Z",
        model: String = "claude-sonnet-4-6",
        cwd: String = "/work/test"
    ) -> String {
        let content: String
        if let tool {
            content = #"[{"type":"tool_use","name":"\#(tool)","input":{}}]"#
        } else {
            content = "[]"
        }
        return """
        {"type":"assistant","sessionId":"\(session)","timestamp":"\(timestamp)",\
        "cwd":"\(cwd)","gitBranch":"main","message":{"id":"\(messageId)",\
        "model":"\(model)","usage":{"input_tokens":\(input),"output_tokens":\(output),\
        "cache_read_input_tokens":0,"cache_creation_input_tokens":0},"content":\(content)}}
        """
    }

    private func userLine(
        session: String,
        timestamp: String = "2026-04-14T10:00:00Z",
        cwd: String = "/work/test"
    ) -> String {
        #"{"type":"user","sessionId":"\#(session)","timestamp":"\#(timestamp)","cwd":"\#(cwd)"}"#
    }

    /// How the importer keys a byte cursor: the file's canonical path, which is
    /// what `FileManager`'s enumerator hands the sweep and need not be the
    /// spelling a test (or a hook payload) used to reach the same file.
    private func canonicalPath(_ relativePath: String) throws -> String {
        try XCTUnwrap(
            jsonlRoot.appendingPathComponent(relativePath)
                .resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
        )
    }

    private func runImport(options: JSONLImporter.Options = JSONLImporter.Options()) throws -> ImportSummary {
        let importer = JSONLImporter(sourceDirectory: jsonlRoot, database: database, options: options)
        return try importer.run()
    }

    // MARK: - Tests

    func testImportCreatesSessionAndEventsAndMetrics() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit", input: 1000, output: 200)
        ], at: "s1.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.filesScanned, 1)
        XCTAssertEqual(summary.turnsSeen, 2)
        XCTAssertEqual(summary.eventsInserted, 2)  // 1 UserPromptSubmit + 1 PreToolUse
        XCTAssertEqual(summary.sessionsCreated, 1)
        XCTAssertEqual(summary.metricsUpserted, 1)
        XCTAssertTrue(summary.errors.isEmpty)

        // Session was created
        let sessions = try database.fetchSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.sessionId, "s1")
        XCTAssertEqual(sessions.first?.status, "ended")

        // Events were inserted
        let events = try database.fetchEvents(sessionId: "s1")
        XCTAssertEqual(events.count, 2)

        // Metrics computed
        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.totalInputTokens, 1000)
        XCTAssertEqual(metrics.totalOutputTokens, 200)
        XCTAssertEqual(metrics.turnCount, 2)
        XCTAssertEqual(metrics.model, "claude-sonnet-4-6")
        // sonnet: 1000 * 3/M + 200 * 15/M = 0.003 + 0.003 = 0.006
        XCTAssertEqual(metrics.totalCostUsd, 0.006, accuracy: 0.0001)
    }

    func testImportIsIdempotent() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "s1.jsonl")

        _ = try runImport()
        let before = try database.fetchEvents(sessionId: "s1").count

        let second = try runImport()
        XCTAssertEqual(second.eventsInserted, 0)
        XCTAssertEqual(
            second.linesSeen, 0,
            "the byte cursor should make an unchanged file cost nothing to re-scan"
        )
        XCTAssertEqual(second.eventsSkipped, 0, "no lines re-read means nothing to dedup")

        let after = try database.fetchEvents(sessionId: "s1").count
        XCTAssertEqual(before, after, "re-import must not duplicate events")
    }

    func testAppendedLinesAreReadFromTheCursorNotFromTheTop() throws {
        try writeJSONL([userLine(session: "s1")], at: "s1.jsonl")
        let first = try runImport()
        XCTAssertEqual(first.linesSeen, 1)

        let url = jsonlRoot.appendingPathComponent("s1.jsonl")
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        let appended = "\n" + assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        try handle.write(contentsOf: Data(appended.utf8))
        try handle.close()

        let second = try runImport()
        XCTAssertEqual(second.linesSeen, 1, "only the appended line should be read")
        XCTAssertEqual(second.eventsInserted, 1)
        XCTAssertEqual(second.eventsSkipped, 0)
        XCTAssertEqual(
            second.bytesRead, Int64(appended.utf8.count),
            "bytesRead must count the appended tail only"
        )
        XCTAssertEqual(
            second.bytesSkipped, first.bytesRead,
            "bytesSkipped must be exactly what the first pass already ingested"
        )

        XCTAssertEqual(try transcriptLineCount(session: "s1"), 2)
        XCTAssertEqual(
            try transcriptLineColumn("entry_type", session: "s1", lineNo: 2), "assistant",
            "line numbering must continue past the cursor, not restart at 1"
        )
    }

    func testRewrittenFileIsReReadFromZeroAndDedups() throws {
        let lines = [
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ]
        try writeJSONL(lines, at: "s1.jsonl")
        _ = try runImport()
        let before = try database.fetchEvents(sessionId: "s1").count

        // An atomic rewrite swaps the inode, which invalidates the stored cursor:
        // the file must be re-read whole and the duplicate rows dropped by dedup,
        // not appended.
        try writeJSONL(lines, at: "s1.jsonl")

        let second = try runImport()
        XCTAssertEqual(second.linesSeen, 2, "a replaced file re-reads from byte zero")
        XCTAssertEqual(second.eventsInserted, 0)
        XCTAssertEqual(second.eventsSkipped, 2, "both events should dedup via message_id")
        XCTAssertEqual(
            second.bytesSkipped, 0, "a rejected cursor must skip nothing"
        )
        XCTAssertGreaterThan(second.bytesRead, 0)

        XCTAssertEqual(try database.fetchEvents(sessionId: "s1").count, before)
        XCTAssertEqual(
            try transcriptLineCount(session: "s1"), 2, "re-read lines must dedup, not duplicate"
        )
    }

    func testAssistantTurnsWithoutToolUseProduceNoEvent() throws {
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m1", tool: nil, input: 500, output: 100)
        ], at: "s1.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.eventsInserted, 0, "no tool_use → no synthetic event")
        XCTAssertEqual(summary.metricsUpserted, 1, "metrics still accumulate")

        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.totalInputTokens, 500)
        XCTAssertEqual(metrics.turnCount, 1)
    }

    func testMetricsAggregateAcrossMultipleTurns() throws {
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m1", tool: "Edit", input: 100, output: 10),
            assistantLine(session: "s1", messageId: "m2", tool: "Read", input: 200, output: 20),
            assistantLine(session: "s1", messageId: "m3", tool: "Bash", input: 300, output: 30)
        ], at: "s1.jsonl")

        _ = try runImport()
        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.totalInputTokens, 600)
        XCTAssertEqual(metrics.totalOutputTokens, 60)
        XCTAssertEqual(metrics.turnCount, 3)
    }

    func testSinceFilterSkipsOlderTurns() throws {
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m-old", tool: "Edit", timestamp: "2026-04-01T10:00:00Z"),
            assistantLine(session: "s1", messageId: "m-new", tool: "Read", timestamp: "2026-04-15T10:00:00Z")
        ], at: "s1.jsonl")

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let since = iso.date(from: "2026-04-10T00:00:00Z")
        let summary = try runImport(options: JSONLImporter.Options(since: since))

        // Only the newer turn counts.
        XCTAssertEqual(summary.turnsSeen, 1)
        XCTAssertEqual(summary.eventsInserted, 1)
        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.turnCount, 1)
    }

    func testDryRunDoesNotWrite() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "s1.jsonl")

        let summary = try runImport(options: JSONLImporter.Options(dryRun: true))
        // Summary still counts turns seen (they were processed), but nothing was written.
        XCTAssertEqual(summary.turnsSeen, 2)
        XCTAssertEqual(summary.eventsInserted, 0)
        XCTAssertEqual(summary.sessionsCreated, 0)
        XCTAssertEqual(summary.metricsUpserted, 0)

        XCTAssertEqual(try database.fetchSessions().count, 0)
    }

    func testDoesNotOverwriteExistingSessions() throws {
        // Simulate: a session already exists (richer row via hooks).
        _ = try database.ingestEvent(
            eventType: "SessionStart",
            timestamp: "2026-04-14T09:00:00Z",
            hookData: [
                "session_id": "s1", "cwd": "/original/cwd",
                "model": "opus", "pid": 123, "term_program": "iTerm2"
            ]
        )

        try writeJSONL([
            assistantLine(session: "s1", messageId: "m1", tool: "Edit", model: "sonnet", cwd: "/jsonl/cwd")
        ], at: "s1.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.sessionsCreated, 0, "existing session preserved")
        XCTAssertEqual(summary.sessionsTouched, 1)

        // Original session row survives.
        let session = try XCTUnwrap(database.fetchSession(sessionId: "s1"))
        XCTAssertEqual(session.cwd, "/original/cwd")
        XCTAssertEqual(session.model, "opus")
        XCTAssertEqual(session.pid, 123)

        // But metrics still got upserted from the JSONL data.
        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.turnCount, 1)
    }

    func testMultipleSessionsAcrossFiles() throws {
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "project-a/s1.jsonl")
        try writeJSONL([
            assistantLine(session: "s2", messageId: "m2", tool: "Read")
        ], at: "project-b/s2.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.filesScanned, 2)
        XCTAssertEqual(summary.sessionsCreated, 2)
        XCTAssertEqual(summary.metricsUpserted, 2)
    }

    func testMalformedJSONLSurvivesWithoutAborting() throws {
        try writeJSONL([
            "{not valid json}",
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "s1.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.turnsSeen, 1, "bad line skipped, good line imported")
        XCTAssertEqual(summary.eventsInserted, 1)
    }

    // MARK: - Account attribution (account_email stamping)

    private func scalarTextList(_ sql: String) throws -> [String] {
        var handle: OpaquePointer?
        guard sqlite3_open(dbPath, &handle) == SQLITE_OK else {
            XCTFail("scalarTextList: could not open \(dbPath ?? "?")")
            return []
        }
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else {
            XCTFail("scalarTextList: prepare failed: \(String(cString: sqlite3_errmsg(handle)))")
            return []
        }
        defer { sqlite3_finalize(stmt) }
        var results: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cStr = sqlite3_column_text(stmt, 0) {
                results.append(String(cString: cStr))
            } else {
                results.append("")
            }
        }
        return results
    }

    /// End-to-end guard for the importer's account attribution. Import-only
    /// sessions the daemon never saw live are now stamped best-effort with the
    /// import-time resolved account (`resolvedAccountForSession`, oauth here) and
    /// `auth_method='unknown'` — a later live token hook still heals the stub via
    /// the source-tagged upsert. transcript_turns / session_metrics carry the same
    /// resolved account (an aggregation key that must be concrete at write time).
    func testImportStampsConsistentAccountAcrossSessionTurnsAndMetrics() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit", input: 100, output: 50),
            assistantLine(session: "s1", messageId: "m2", tool: "Read", input: 200, output: 40)
        ], at: "s1.jsonl")

        _ = try runImport()

        XCTAssertEqual(
            try scalarTextList("SELECT account_email FROM sessions WHERE session_id = 's1'").first,
            "import-test@acct.com",
            "import-only session stub is stamped with the import-time resolved account"
        )
        XCTAssertEqual(
            try scalarTextList("SELECT auth_method FROM sessions WHERE session_id = 's1'").first,
            "unknown",
            "import-time attribution is tagged unknown (heal-by-token still possible)"
        )
        XCTAssertEqual(
            database.resolvedAccountForSession("s1"),
            "import-test@acct.com",
            "read-time attribution resolves to the same oauth account"
        )

        let turnAccounts = try scalarTextList(
            "SELECT account_email FROM transcript_turns WHERE session_id = 's1'"
        )
        XCTAssertEqual(turnAccounts.count, 3, "user + 2 assistant turns")
        XCTAssertTrue(
            turnAccounts.allSatisfy { $0 == "import-test@acct.com" },
            "every transcript_turns row for one session must share the same resolved account"
        )

        XCTAssertEqual(
            try scalarTextList("SELECT account_email FROM session_metrics WHERE session_id = 's1'").first,
            "import-test@acct.com"
        )
    }

    // MARK: - transcript_turns persistence (Phase 2)

    func testImportInsertsTranscriptTurns() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit", input: 100, output: 50),
            assistantLine(session: "s1", messageId: "m2", tool: nil, input: 200, output: 40)
        ], at: "s1.jsonl")

        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 3,
                       "all three turns (user + 2 assistant) land in transcript_turns")
    }

    func testTranscriptTurnsAreIdempotentOnReimport() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit"),
            assistantLine(session: "s1", messageId: "m2", tool: "Read")
        ], at: "s1.jsonl")

        _ = try runImport()
        let before = try database.transcriptTurnCount(sessionId: "s1")
        XCTAssertEqual(before, 3)

        _ = try runImport()
        let after = try database.transcriptTurnCount(sessionId: "s1")
        XCTAssertEqual(after, 3, "re-import must not duplicate turns (message_id + composite dedup)")
    }

    func testUserTurnDedupViaCompositeKey() throws {
        // Two user turns at the same timestamp in the same session — only one row.
        try writeJSONL([
            userLine(session: "s1", timestamp: "2026-04-14T10:00:00Z"),
            userLine(session: "s1", timestamp: "2026-04-14T10:00:00Z")
        ], at: "s1.jsonl")

        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 1,
                       "(session_id, timestamp, kind) composite key dedups user turns")
    }

    func testAssistantEmptyMidDedupsOnReimport() throws {
        // Assistant turns with empty message_id are deduped on
        // (session_id, timestamp, tool_name) (migration009). Re-importing
        // the same file is a no-op, but multi-tool-use sibling rows with
        // different tool_names stay distinct.
        let line = """
        {"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/work","gitBranch":"main","message":{"id":"","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":50,"output_tokens":10,"cache_read_input_tokens":0,\
        "cache_creation_input_tokens":0},"content":[]}}
        """
        try writeJSONL([line], at: "s1.jsonl")

        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 1)

        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 1,
                       "(session_id, timestamp, tool_name) collapses re-imports")
    }

    func testAssistantMultiToolUseRowsStayDistinct() throws {
        // Two sibling tool_use blocks from one assistant message share
        // (session_id, timestamp, empty message_id) but differ in
        // tool_name — both must persist.
        let readLine = assistantLine(session: "s1", messageId: "", tool: "Read",
                                     timestamp: "2026-04-14T10:00:00Z")
        let editLine = assistantLine(session: "s1", messageId: "", tool: "Edit",
                                     timestamp: "2026-04-14T10:00:00Z")
        try writeJSONL([readLine, editLine], at: "s1.jsonl")

        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 2,
                       "distinct tool_names preserve multi-tool-use siblings")
    }

    // MARK: - Scoped runs (`only:`)

    /// A hook names the file that changed, so the walk that exists to find it is
    /// skipped entirely — and with it every other file in the tree, whatever its
    /// mtime.
    func testAScopedRunReadsOnlyTheFileItWasHanded() throws {
        try writeJSONL([
            userLine(session: "named"),
            assistantLine(session: "named", messageId: "m1", tool: "Edit")
        ], at: "p/named.jsonl")
        try writeJSONL([
            userLine(session: "ignored"),
            assistantLine(session: "ignored", messageId: "m2", tool: "Edit")
        ], at: "p/ignored.jsonl")

        let summary = try runImport(options: JSONLImporter.Options(
            only: [jsonlRoot.appendingPathComponent("p/named.jsonl")]
        ))

        XCTAssertEqual(summary.filesScanned, 1)
        XCTAssertEqual(try transcriptLineCount(session: "named"), 2)
        XCTAssertEqual(try transcriptLineCount(session: "ignored"), 0,
                       "a file nobody named is the sweep's business, not this run's")
    }

    /// The cursor prune reads "not on disk" off the set of files the walk found.
    /// A scoped run's set is one file, so pruning against it would reclaim the
    /// cursor of every live transcript on the machine — and the next sweep would
    /// re-read all of them from byte zero.
    func testAScopedRunLeavesEveryOtherFilesCursorAlone() throws {
        try writeJSONL([assistantLine(session: "s1", messageId: "m1", tool: "Edit")], at: "p/s1.jsonl")
        try writeJSONL([assistantLine(session: "s2", messageId: "m2", tool: "Edit")], at: "p/s2.jsonl")
        _ = try runImport()
        let other = try canonicalPath("p/s2.jsonl")
        XCTAssertNotNil(try database.transcriptFileCursor(for: other), "sweep records a cursor per file")

        _ = try runImport(options: JSONLImporter.Options(
            only: [jsonlRoot.appendingPathComponent("p/s1.jsonl")]
        ))

        XCTAssertNotNil(try database.transcriptFileCursor(for: other),
                        "the unnamed file still exists; only the walk failed to mention it")
    }

    /// The metrics recompute is a whole-session aggregate: it costs the
    /// session's entire history whether the run added one line or a hundred
    /// thousand. A tail fires on every hook, so it has to be able to leave that
    /// to the five-minute sweep — while still writing the lines, which is what a
    /// tail is for.
    func testARunCanSkipTheMetricsRecomputeAndStillWriteItsLines() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "p/s1.jsonl")

        let summary = try runImport(options: JSONLImporter.Options(
            only: [jsonlRoot.appendingPathComponent("p/s1.jsonl")],
            refreshesSessionMetrics: false
        ))

        XCTAssertEqual(summary.metricsUpserted, 0)
        XCTAssertEqual(try transcriptLineCount(session: "s1"), 2,
                       "skipping the aggregate cost the tail the lines it exists to write")
    }

    /// And it is off only where it is asked for: a sweep still writes them.
    func testASweepStillRecomputesTheMetrics() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "p/s1.jsonl")

        XCTAssertEqual(try runImport().metricsUpserted, 1)
    }

    /// The cutoff is a watermark for a walk. A scoped run performs none, and its
    /// newest mtime is just the newest of the files it was handed — stored as the
    /// sweep's cursor it would seal off everything older that changed meanwhile.
    func testAScopedRunReportsNoCutoff() throws {
        try writeJSONL([assistantLine(session: "s1", messageId: "m1", tool: "Edit")], at: "p/s1.jsonl")

        let summary = try runImport(options: JSONLImporter.Options(
            only: [jsonlRoot.appendingPathComponent("p/s1.jsonl")]
        ))

        XCTAssertEqual(summary.filesScanned, 1)
        XCTAssertNil(summary.cutoffISO)
    }

    /// The two paths write the same rows through the same cursor, which is what
    /// makes it safe for both to be pointed at one file: whichever gets there
    /// first does the work, and the other finds the tail already consumed.
    func testASweepAfterAScopedRunFindsNothingLeftToDo() throws {
        try writeJSONL([
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit")
        ], at: "p/s1.jsonl")

        let scoped = try runImport(options: JSONLImporter.Options(
            only: [jsonlRoot.appendingPathComponent("p/s1.jsonl")]
        ))
        XCTAssertEqual(scoped.linesInserted, 2)

        let sweep = try runImport()
        XCTAssertEqual(sweep.linesSeen, 0, "the byte cursor the scoped run advanced is the sweep's")
        XCTAssertEqual(sweep.linesInserted, 0)
        XCTAssertEqual(try transcriptLineCount(session: "s1"), 2)
    }

    /// A file named by a hook that has since been deleted is dropped rather than
    /// dated `.distantPast` — the walk would not have returned it either.
    func testAScopedRunSkipsAFileThatIsNoLongerThere() throws {
        let summary = try runImport(options: JSONLImporter.Options(
            only: [jsonlRoot.appendingPathComponent("p/gone.jsonl")]
        ))

        XCTAssertEqual(summary.filesScanned, 0)
        XCTAssertTrue(summary.errors.isEmpty, "a vanished transcript is absence, not failure")
    }

    // MARK: - Chunked drain (Options.maxFiles + hasMore + cutoffISO)

    /// Backstops the v2.1.9 chunking contract: a pass capped at N files
    /// must process exactly N and surface `hasMore: true` so the task
    /// re-enqueues. Without this, a 34k-file backlog runs in one queue.sync
    /// and starves /health. mtimes are set explicitly and distinct so the
    /// cap boundary is deterministic and the equal-mtime extension (see
    /// `testEqualMtimeAtCapBoundaryNotSkipped`) doesn't pull a third file
    /// into the chunk.
    func testMaxFilesLimitsPassAndSetsHasMore() throws {
        try writeJSONL([assistantLine(session: "s1", messageId: "m1", tool: "Edit")], at: "p/s1.jsonl")
        try writeJSONL([assistantLine(session: "s2", messageId: "m2", tool: "Edit")], at: "p/s2.jsonl")
        try writeJSONL([assistantLine(session: "s3", messageId: "m3", tool: "Edit")], at: "p/s3.jsonl")
        let base = 1_700_000_000.0
        for (offset, name) in ["p/s1.jsonl", "p/s2.jsonl", "p/s3.jsonl"].enumerated() {
            try FileManager.default.setAttributes(
                [.modificationDate: Date(timeIntervalSince1970: base + Double(offset) * 1000)],
                ofItemAtPath: jsonlRoot.appendingPathComponent(name).path)
        }

        let summary = try runImport(options: JSONLImporter.Options(maxFiles: 2))
        XCTAssertEqual(summary.filesScanned, 2, "only `maxFiles` files processed per pass")
        XCTAssertTrue(summary.hasMore, "remaining file means caller must re-enqueue")
        XCTAssertNotNil(summary.cutoffISO, "cutoffISO must advance whenever a file is processed")
    }

    /// Guards the equal-mtime chunk-boundary hazard: two files sharing the
    /// boundary mtime must never be split across a chunk edge. If one were
    /// left behind, the next chunk's `mtime <= cutoff` filter would exclude
    /// it permanently — silent data loss. The importer extends the chunk to
    /// swallow the whole tie group even though it overruns `maxFiles`.
    func testEqualMtimeAtCapBoundaryNotSkipped() throws {
        try writeJSONL([assistantLine(session: "old", messageId: "mo", tool: "Edit")], at: "p/old.jsonl")
        try writeJSONL([assistantLine(session: "tieA", messageId: "ma", tool: "Edit")], at: "p/tie-a.jsonl")
        try writeJSONL([assistantLine(session: "tieB", messageId: "mb", tool: "Edit")], at: "p/tie-b.jsonl")

        let early = Date(timeIntervalSince1970: 1_700_000_000)
        let tie = Date(timeIntervalSince1970: 1_700_001_000)
        try FileManager.default.setAttributes([.modificationDate: early],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/old.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: tie],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/tie-a.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: tie],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/tie-b.jsonl").path)

        // cap=2 naively takes [old, one-tie] and would leave the other tie
        // file at exactly the cutoff mtime. The extension must pull both.
        let summary = try runImport(options: JSONLImporter.Options(maxFiles: 2))
        XCTAssertEqual(summary.filesScanned, 3, "equal-mtime boundary file pulled in, never skipped")
        XCTAssertFalse(summary.hasMore, "tie group fully consumed, nothing left")

        for session in ["old", "tieA", "tieB"] {
            XCTAssertNotNil(try database.metricsForSession(sessionId: session),
                            "\(session) must be imported, not dropped at the boundary")
        }

        // Resuming from the cutoff re-scans nothing and loses nothing.
        let cutoff = try XCTUnwrap(parseISO8601(summary.cutoffISO))
        let resume = try runImport(options: JSONLImporter.Options(since: cutoff, maxFiles: 2))
        XCTAssertEqual(resume.filesScanned, 0, "strict `> cutoff` leaves no leftover tie file")
    }

    /// Guards the multi-chunk metrics-clobber hazard: one session split
    /// across two files, drained in separate chunks (maxFiles=1). Because
    /// metrics are recomputed from the persisted transcript_turns, the
    /// second chunk's REPLACE upsert sums every turn instead of overwriting
    /// the first chunk's totals.
    func testMetricsSumAcrossChunksNotClobbered() throws {
        try writeJSONL([assistantLine(session: "s1", messageId: "m1", tool: "Edit", input: 100, output: 10)],
                       at: "a/s1.jsonl")
        try writeJSONL([assistantLine(session: "s1", messageId: "m2", tool: "Read", input: 200, output: 20)],
                       at: "b/s1.jsonl")
        let early = Date(timeIntervalSince1970: 1_700_000_000)
        let late = Date(timeIntervalSince1970: 1_700_001_000)
        try FileManager.default.setAttributes([.modificationDate: early],
            ofItemAtPath: jsonlRoot.appendingPathComponent("a/s1.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: late],
            ofItemAtPath: jsonlRoot.appendingPathComponent("b/s1.jsonl").path)

        let first = try runImport(options: JSONLImporter.Options(maxFiles: 1))
        XCTAssertEqual(first.filesScanned, 1)
        XCTAssertTrue(first.hasMore)

        let cutoff = try XCTUnwrap(parseISO8601(first.cutoffISO))
        let second = try runImport(options: JSONLImporter.Options(since: cutoff, maxFiles: 1))
        XCTAssertEqual(second.filesScanned, 1)
        XCTAssertFalse(second.hasMore)

        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.totalInputTokens, 300, "chunk 2 must not clobber chunk 1's tokens")
        XCTAssertEqual(metrics.totalOutputTokens, 30)
        XCTAssertEqual(metrics.turnCount, 2, "both turns counted across chunks")
    }

    /// When a session has turns from two models at the same latest
    /// timestamp, the representative `model` must be chosen deterministically
    /// (by model name) rather than by the unstable Dictionary iteration
    /// order. Tokens from both models are still summed and costed.
    func testRepresentativeModelTieIsDeterministic() throws {
        // Same session, same timestamp, two different models — a tie on
        // `lastTs`. Lexicographically, "...sonnet..." > "...opus..." so
        // sonnet is the deterministic winner regardless of import order.
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m-opus", tool: "Edit",
                          input: 100, output: 10, model: "claude-opus-4-7"),
            assistantLine(session: "s1", messageId: "m-sonnet", tool: "Read",
                          input: 200, output: 20, model: "claude-sonnet-4-6")
        ], at: "s1.jsonl")

        _ = try runImport()
        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.model, "claude-sonnet-4-6",
                       "tie on latest timestamp resolves to the greater model name, not dict order")
        XCTAssertEqual(metrics.totalInputTokens, 300, "both models' tokens summed")
        XCTAssertEqual(metrics.totalOutputTokens, 30)
        XCTAssertEqual(metrics.turnCount, 2)
    }

    func testHasMoreFalseWhenAllProcessed() throws {
        try writeJSONL([assistantLine(session: "s1", messageId: "m1", tool: "Edit")], at: "p/s1.jsonl")
        try writeJSONL([assistantLine(session: "s2", messageId: "m2", tool: "Edit")], at: "p/s2.jsonl")

        let summary = try runImport(options: JSONLImporter.Options(maxFiles: 10))
        XCTAssertEqual(summary.filesScanned, 2)
        XCTAssertFalse(summary.hasMore, "no more files → caller falls back to regular interval")
    }

    /// cutoffISO must equal the latest-processed file's mtime so the next
    /// chunk's `since` skips files we've already handled. We control mtime
    /// directly so the test is deterministic regardless of write order.
    func testCutoffISOIsLatestProcessedMtime() throws {
        try writeJSONL([assistantLine(session: "old", messageId: "mo", tool: "Edit")], at: "p/old.jsonl")
        try writeJSONL([assistantLine(session: "mid", messageId: "mm", tool: "Edit")], at: "p/mid.jsonl")
        try writeJSONL([assistantLine(session: "new", messageId: "mn", tool: "Edit")], at: "p/new.jsonl")

        let oldMtime = Date(timeIntervalSince1970: 1_700_000_000)
        let midMtime = Date(timeIntervalSince1970: 1_700_001_000)
        let newMtime = Date(timeIntervalSince1970: 1_700_002_000)
        try FileManager.default.setAttributes([.modificationDate: oldMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/old.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: midMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/mid.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: newMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/new.jsonl").path)

        // With maxFiles=2 we process the two oldest (old + mid); cutoff
        // must be `mid`'s mtime so the next chunk picks up `new`.
        let summary = try runImport(options: JSONLImporter.Options(maxFiles: 2))
        XCTAssertEqual(summary.filesScanned, 2)
        XCTAssertTrue(summary.hasMore)

        let cutoffDate = try XCTUnwrap(parseISO8601(summary.cutoffISO))
        XCTAssertEqual(cutoffDate.timeIntervalSince1970, midMtime.timeIntervalSince1970, accuracy: 0.001,
                       "cutoffISO is the latest mtime of the processed chunk, not the latest overall")
    }

    /// A resumed pass with `since = cutoffISO of the previous chunk` must
    /// strictly exclude that file (strict `>`, not `>=`). Otherwise the
    /// drain loops forever on a single file.
    func testSinceUsesStrictGreaterThan() throws {
        try writeJSONL([assistantLine(session: "a", messageId: "ma", tool: "Edit")], at: "p/a.jsonl")
        try writeJSONL([assistantLine(session: "b", messageId: "mb", tool: "Edit")], at: "p/b.jsonl")
        let firstMtime = Date(timeIntervalSince1970: 1_700_000_000)
        let secondMtime = Date(timeIntervalSince1970: 1_700_001_000)
        try FileManager.default.setAttributes([.modificationDate: firstMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/a.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: secondMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/b.jsonl").path)

        // Resume from a.jsonl's mtime — a must NOT re-import.
        let summary = try runImport(options: JSONLImporter.Options(since: firstMtime, maxFiles: 10))
        XCTAssertEqual(summary.filesScanned, 1, "strict > skips the file at exactly the cutoff")
    }

    /// A file the importer could not process must NOT be sealed behind the
    /// mtime cursor: the next pass filters out `mtime <= since`, so advancing
    /// past it would drop that session's transcript permanently. The cutoff
    /// stops at the newest file processed cleanly *before* the failure, and
    /// later files are still processed (the failure isn't fatal to the pass).
    func testCutoffHeldBackWhenAFileFails() throws {
        try writeJSONL([assistantLine(session: "good", messageId: "mg", tool: "Edit")], at: "p/good.jsonl")
        try writeJSONL([assistantLine(session: "bad", messageId: "mb", tool: "Edit")], at: "p/bad.jsonl")
        try writeJSONL([assistantLine(session: "later", messageId: "ml", tool: "Edit")], at: "p/later.jsonl")

        let goodMtime = Date(timeIntervalSince1970: 1_700_000_000)
        let badMtime = Date(timeIntervalSince1970: 1_700_001_000)
        let laterMtime = Date(timeIntervalSince1970: 1_700_002_000)
        try FileManager.default.setAttributes([.modificationDate: goodMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/good.jsonl").path)
        try FileManager.default.setAttributes([.modificationDate: laterMtime],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/later.jsonl").path)
        // Unreadable → `readText` throws when opening the handle. mtime is set
        // last: chmod would otherwise bump it.
        try FileManager.default.setAttributes(
            [.modificationDate: badMtime, .posixPermissions: NSNumber(value: 0o000)],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/bad.jsonl").path)

        let summary = try runImport()
        XCTAssertEqual(summary.filesScanned, 3, "every eligible file is still visited")
        XCTAssertEqual(summary.errors.count, 1, "the unreadable file is reported, not swallowed")

        let cutoff = try XCTUnwrap(parseISO8601(summary.cutoffISO))
        XCTAssertEqual(cutoff.timeIntervalSince1970, goodMtime.timeIntervalSince1970, accuracy: 0.001,
                       "cutoff stops before the failed file so the next pass re-scans it")
        XCTAssertNotNil(try database.metricsForSession(sessionId: "later"),
                        "a failure mid-batch must not abort the remaining files")

        // Resuming from that cutoff really does re-offer the failed file.
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o644)],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/bad.jsonl").path)
        let resume = try runImport(options: JSONLImporter.Options(since: cutoff))
        XCTAssertTrue(resume.errors.isEmpty, "readable now — no error second time")
        XCTAssertNotNil(try database.metricsForSession(sessionId: "bad"),
                        "the previously failed transcript is recovered on the next pass")
    }

    /// When the very first file fails there is no clean predecessor, so the
    /// cutoff must be nil — "don't move the cursor at all" — rather than the
    /// batch's newest mtime.
    func testCutoffIsNilWhenTheOnlyFileFails() throws {
        try writeJSONL([assistantLine(session: "bad", messageId: "mb", tool: "Edit")], at: "p/bad.jsonl")
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o000)],
            ofItemAtPath: jsonlRoot.appendingPathComponent("p/bad.jsonl").path)

        let summary = try runImport()
        XCTAssertEqual(summary.errors.count, 1)
        XCTAssertNil(summary.cutoffISO, "no clean file → the cursor stays where it was")
    }

    // MARK: - Wire-DTO version skew

    /// `ImportSummary` is the daemon→CLI JSON contract for `POST /import`.
    /// An older daemon that predates `has_more`/`cutoff_iso` must still
    /// decode in a newer CLI — the missing keys default rather than
    /// throwing `keyNotFound`. Mirrors the CLI's decoder config.
    func testImportSummaryDecodesWhenNewKeysAbsent() throws {
        let legacyJSON = """
        {
          "files_scanned": 4,
          "turns_seen": 12,
          "events_inserted": 9,
          "events_skipped": 3,
          "sessions_created": 1,
          "sessions_touched": 2,
          "metrics_upserted": 2,
          "errors": []
        }
        """

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let summary = try decoder.decode(ImportSummary.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(summary.filesScanned, 4)
        XCTAssertEqual(summary.metricsUpserted, 2)
        XCTAssertFalse(summary.hasMore, "absent has_more defaults to false, not a decode crash")
        XCTAssertNil(summary.cutoffISO, "absent cutoff_iso defaults to nil")
    }

    func testImportSummaryDecodesWithoutLineCounts() throws {
        // An older daemon/CLI peer omits the new fields; decode must default them to 0.
        let json = Data(#"{"filesScanned":2,"turnsSeen":5}"#.utf8)
        let summary = try JSONDecoder().decode(ImportSummary.self, from: json)
        XCTAssertEqual(summary.filesScanned, 2)
        XCTAssertEqual(summary.linesSeen, 0)
        XCTAssertEqual(summary.linesInserted, 0)
    }

    func testImportSummaryRoundTripsLineCounts() throws {
        let original = ImportSummary(filesScanned: 1, linesSeen: 42, linesInserted: 40)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ImportSummary.self, from: data)
        XCTAssertEqual(decoded.linesSeen, 42)
        XCTAssertEqual(decoded.linesInserted, 40)
    }

    func testInsertTranscriptLinesInsertsThenDedups() throws {
        let dir = jsonlRoot.appendingPathComponent("proj")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("s1.jsonl")
        let body = #"{"type":"user","sessionId":"s1","timestamp":"t1"}"# + "\n"
                 + #"{"type":"assistant","sessionId":"s1","timestamp":"t2","message":{"role":"assistant"}}"# + "\n"
        try body.write(to: file, atomically: true, encoding: .utf8)

        let raw = try JSONLScanner.scanRawLines(at: file)
        XCTAssertEqual(raw.count, 2)

        let first = try database.insertTranscriptLines(raw, filePath: file.path)
        XCTAssertEqual(first, 2)

        // Re-inserting the identical lines is a no-op: dedup on (session_id, line_hash).
        let second = try database.insertTranscriptLines(raw, filePath: file.path)
        XCTAssertEqual(second, 0)
    }

    private func parseISO8601(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }

    // MARK: - run() wires raw-line capture (Task 5)

    func testImportPersistsFullTranscriptLines() throws {
        try writeJSONL([
            #"{"type":"summary","summary":"Earlier session"}"#,
            userLine(session: "s1"),
            assistantLine(session: "s1", messageId: "m1", tool: "Edit", input: 10, output: 5)
        ], at: "s1.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.linesSeen, 3)      // summary + user + assistant
        XCTAssertEqual(summary.linesInserted, 3)
        XCTAssertEqual(try transcriptLineCount(session: "s1"), 3)

        // Re-running imports zero new lines (dedup on session_id + hash).
        let again = try runImport()
        XCTAssertEqual(again.linesInserted, 0)
        XCTAssertEqual(try transcriptLineCount(session: "s1"), 3)
    }

    func testImportDryRunInsertsNoTranscriptLines() throws {
        try writeJSONL([userLine(session: "sd")], at: "sd.jsonl")
        let importer = JSONLImporter(
            sourceDirectory: jsonlRoot,
            database: database,
            options: JSONLImporter.Options(dryRun: true)
        )
        let summary = try importer.run()
        XCTAssertEqual(summary.linesInserted, 0)
        XCTAssertEqual(try transcriptLineCount(session: "sd"), 0)
    }

    private func transcriptLineCount(session: String) throws -> Int {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(dbPath, &handle), SQLITE_OK)
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        // Test session ids are controlled literals — safe to interpolate.
        let sql = "SELECT count(*) FROM transcript_lines WHERE session_id = '\(session)'"
        XCTAssertEqual(sqlite3_prepare_v2(handle, sql, -1, &stmt, nil), SQLITE_OK)
        defer { sqlite3_finalize(stmt) }
        XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
        return Int(sqlite3_column_int(stmt, 0))
    }

    /// Reads one promoted column off a single `transcript_lines` row,
    /// identified by (session_id, line_no). Mirrors `transcriptLineCount`
    /// above — `column` is a caller-supplied literal (never user input);
    /// `session` is a controlled test literal, safe to interpolate.
    private func transcriptLineColumn(_ column: String, session: String, lineNo: Int) throws -> String {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(dbPath, &handle), SQLITE_OK)
        defer { sqlite3_close(handle) }
        var stmt: OpaquePointer?
        let sql = "SELECT \(column) FROM transcript_lines WHERE session_id = '\(session)' AND line_no = \(lineNo)"
        XCTAssertEqual(sqlite3_prepare_v2(handle, sql, -1, &stmt, nil), SQLITE_OK)
        defer { sqlite3_finalize(stmt) }
        XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
        guard let cStr = sqlite3_column_text(stmt, 0) else { return "" }
        return String(cString: cStr)
    }

    /// Claude Code resumes a session by replaying its earlier history into a
    /// NEW transcript file (a different stem than the original). Every
    /// replayed line still carries its ORIGINAL `sessionId` in the JSON — it
    /// is never rewritten to the new file's stem. Dedup on
    /// `(session_id, line_hash)` therefore keys off the line's own
    /// `sessionId`, not which file it was read from, so the copied history
    /// collapses onto the rows already inserted from the original file.
    func testImportDedupsCopiedHistoryAcrossResumedFiles() throws {
        // s1.jsonl: the original session's transcript.
        let copiedLine = userLine(session: "s1", timestamp: "2026-04-14T10:00:00Z")
        try writeJSONL([copiedLine], at: "s1.jsonl")

        // s2.jsonl: the resumed session — a new s2-only line, plus a
        // verbatim copy of the s1 line Claude Code replays on resume. The
        // copied line still carries `"sessionId":"s1"`, not "s2".
        let newLine = userLine(session: "s2", timestamp: "2026-04-14T11:00:00Z")
        try writeJSONL([newLine, copiedLine], at: "s2.jsonl")

        let summary = try runImport()
        XCTAssertEqual(summary.linesSeen, 3, "3 raw lines seen across both files")
        XCTAssertEqual(summary.linesInserted, 2,
                       "the copied s1 line dedups against its s1.jsonl original; only 2 are new")

        XCTAssertEqual(try transcriptLineCount(session: "s1"), 1,
                       "copied history line dedups by (session_id, line_hash) — not double-counted " +
                       "for appearing in both files")
        XCTAssertEqual(try transcriptLineCount(session: "s2"), 1,
                       "the s2-only line is present under session s2")
    }

    /// Asserts the promoted columns (`entry_type`, `role`, and the
    /// `session_id` file-stem fallback) reflect the raw line's own content —
    /// not just that a row landed. A `summary`-type entry carries no
    /// `sessionId`, so its `session_id` must fall back to the file stem.
    func testImportPersistsPromotedColumns() throws {
        let summaryLine = #"{"type":"summary","summary":"Earlier session"}"#
        let userTurn = #"{"type":"user","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z","message":{"role":"user"}}"#
        let assistantTurn = #"{"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:01:00Z","#
            + #""message":{"role":"assistant"}}"#
        try writeJSONL([summaryLine, userTurn, assistantTurn], at: "s1.jsonl")

        _ = try runImport()

        XCTAssertEqual(try transcriptLineColumn("entry_type", session: "s1", lineNo: 1), "summary")
        XCTAssertEqual(try transcriptLineColumn("session_id", session: "s1", lineNo: 1), "s1",
                       "sessionId-less summary line falls back to the file stem")

        XCTAssertEqual(try transcriptLineColumn("entry_type", session: "s1", lineNo: 2), "user")
        XCTAssertEqual(try transcriptLineColumn("role", session: "s1", lineNo: 2), "user")

        XCTAssertEqual(try transcriptLineColumn("entry_type", session: "s1", lineNo: 3), "assistant")
        XCTAssertEqual(try transcriptLineColumn("role", session: "s1", lineNo: 3), "assistant")
    }

    // MARK: - Subagent attribution (is_subagent / agent_id persistence)

    func testPersistsSubagentViaIsSidechainMarker() throws {
        let line = """
        {"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/w","isSidechain":true,"message":{"id":"m-sc","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":0,\
        "cache_creation_input_tokens":0},"content":[]}}
        """
        try writeJSONL([line], at: "s1.jsonl")

        _ = try runImport()
        let row = try XCTUnwrap(database.transcriptTurn(messageId: "m-sc"))
        XCTAssertTrue(row.isSubagent, "isSidechain marker must persist as is_subagent = 1")
        XCTAssertEqual(row.agentId, "", "sidechain flag alone carries no agent id")
    }

    func testPersistsSubagentViaAgentIdMarker() throws {
        let line = """
        {"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/w","agentId":"agent-42","message":{"id":"m-aid","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":0,\
        "cache_creation_input_tokens":0},"content":[]}}
        """
        try writeJSONL([line], at: "s1.jsonl")

        _ = try runImport()
        let row = try XCTUnwrap(database.transcriptTurn(messageId: "m-aid"))
        XCTAssertTrue(row.isSubagent, "record-level agentId must persist as is_subagent = 1")
        XCTAssertEqual(row.agentId, "agent-42")
    }

    func testPersistsSubagentViaFilePathMarker() throws {
        // Marker 3 is the file's location, not anything on the line itself.
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m-path", tool: "Bash")
        ], at: "proj/subagents/agent-1.jsonl")

        _ = try runImport()
        let row = try XCTUnwrap(database.transcriptTurn(messageId: "m-path"))
        XCTAssertTrue(row.isSubagent, "a /subagents/ transcript path must persist as is_subagent = 1")
        XCTAssertEqual(row.agentId, "", "path marker carries no agent id")
    }

    func testMainSessionTurnPersistsAsNotSubagent() throws {
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m-main", tool: "Bash")
        ], at: "proj/s1.jsonl")

        _ = try runImport()
        let row = try XCTUnwrap(database.transcriptTurn(messageId: "m-main"))
        XCTAssertFalse(row.isSubagent)
        XCTAssertEqual(row.agentId, "")
    }

    // MARK: - Agent dispatch metadata (agent_dispatches)

    private func dispatchLine(
        session: String = "parent",
        agentId: String = "agent-1",
        agentType: String = "general-purpose",
        status: String = "completed",
        totalTokens: Int = 5000,
        timestamp: String = "2026-04-14T10:05:00Z"
    ) -> String {
        """
        {"type":"user","sessionId":"\(session)","timestamp":"\(timestamp)","cwd":"/w",\
        "toolUseResult":{"agentId":"\(agentId)","agentType":"\(agentType)",\
        "status":"\(status)","totalTokens":\(totalTokens),"totalDurationMs":120000,\
        "totalToolUseCount":9}}
        """
    }

    func testDispatchMetadataPersistedFromToolUseResult() throws {
        try writeJSONL([dispatchLine()], at: "parent.jsonl")

        _ = try runImport()
        let row = try XCTUnwrap(database.agentDispatch(agentId: "agent-1"))
        XCTAssertEqual(row.sessionId, "parent")
        XCTAssertEqual(row.agentType, "general-purpose")
        XCTAssertEqual(row.startedAt, "2026-04-14T10:05:00Z")
        XCTAssertEqual(row.status, "completed")
        XCTAssertEqual(row.totalTokens, 5000)
        XCTAssertEqual(row.totalDurationMs, 120_000)
        XCTAssertEqual(row.totalToolUseCount, 9)
    }

    func testDispatchReimportUpsertsNotDuplicates() throws {
        try writeJSONL([dispatchLine(status: "running", totalTokens: 100)], at: "parent.jsonl")
        _ = try runImport()
        XCTAssertEqual(try database.agentDispatchCount(), 1)

        // Same-values re-import: still one row, values unchanged.
        _ = try runImport()
        XCTAssertEqual(try database.agentDispatchCount(), 1)
        XCTAssertEqual(try XCTUnwrap(database.agentDispatch(agentId: "agent-1")).status, "running")

        // The file grows a final record for the same agent_id — the upsert
        // refreshes the row in place (last write wins per agent_id).
        try writeJSONL([
            dispatchLine(status: "running", totalTokens: 100),
            dispatchLine(status: "completed", totalTokens: 9999)
        ], at: "parent.jsonl")
        _ = try runImport()
        XCTAssertEqual(try database.agentDispatchCount(), 1, "re-import must not duplicate dispatches")
        let row = try XCTUnwrap(database.agentDispatch(agentId: "agent-1"))
        XCTAssertEqual(row.status, "completed")
        XCTAssertEqual(row.totalTokens, 9999)
    }

    // MARK: - Session titles (custom-title / ai-title precedence)

    private func customTitleLine(session: String = "s1", title: String) -> String {
        #"{"type":"custom-title","sessionId":"\#(session)","customTitle":"\#(title)"}"#
    }

    private func aiTitleLine(session: String = "s1", title: String) -> String {
        #"{"type":"ai-title","sessionId":"\#(session)","aiTitle":"\#(title)"}"#
    }

    func testCustomTitleWinsOverAITitleWithinOneImport() throws {
        try writeJSONL([
            userLine(session: "s1"),
            customTitleLine(title: "Hand-picked"),
            aiTitleLine(title: "Robot guess")
        ], at: "s1.jsonl")

        _ = try runImport()
        let (title, source) = try database.sessionTranscriptTitle(sessionId: "s1")
        XCTAssertEqual(title, "Hand-picked")
        XCTAssertEqual(source, "custom")
    }

    func testAITitleNeverOverwritesPersistedCustomTitle() throws {
        try writeJSONL([userLine(session: "s1"), customTitleLine(title: "Hand-picked")], at: "s1.jsonl")
        _ = try runImport()

        // A later scan sees only an ai-title (e.g. Claude regenerated one).
        try writeJSONL([userLine(session: "s1"), aiTitleLine(title: "Robot guess")], at: "s2.jsonl")
        _ = try runImport()

        let (title, source) = try database.sessionTranscriptTitle(sessionId: "s1")
        XCTAssertEqual(title, "Hand-picked", "ai-title must not displace an existing custom title")
        XCTAssertEqual(source, "custom")
    }

    func testCustomTitleOverwritesPersistedAITitle() throws {
        try writeJSONL([userLine(session: "s1"), aiTitleLine(title: "Robot guess")], at: "s1.jsonl")
        _ = try runImport()
        XCTAssertEqual(try database.sessionTranscriptTitle(sessionId: "s1").source, "ai")

        try writeJSONL([userLine(session: "s1"), customTitleLine(title: "Hand-picked")], at: "s2.jsonl")
        _ = try runImport()

        let (title, source) = try database.sessionTranscriptTitle(sessionId: "s1")
        XCTAssertEqual(title, "Hand-picked", "a custom title may overwrite anything")
        XCTAssertEqual(source, "custom")
    }

    func testTitleOnlySessionDoesNotMaterializeARow() throws {
        // A title record carries a sessionId but no turns — importing it
        // must not create a phantom session (mirrors claude-usage's guard).
        try writeJSONL([customTitleLine(session: "ghost", title: "Nothing here")], at: "ghost.jsonl")

        _ = try runImport()
        XCTAssertNil(try database.fetchSession(sessionId: "ghost"))
    }

    // MARK: - Last-record-wins message_id dedup

    func testLastRecordWinsForSharedMessageId() throws {
        // Claude Code streams multiple partial records per API response,
        // all sharing message.id; only the last carries final usage tallies.
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m1", tool: "Bash", input: 10, output: 1),
            assistantLine(session: "s1", messageId: "m1", tool: nil, input: 100, output: 50)
        ], at: "s1.jsonl")

        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 1,
                       "partials sharing a message.id collapse to one turn")

        let row = try XCTUnwrap(database.transcriptTurn(messageId: "m1"))
        XCTAssertEqual(row.inputTokens, 100, "the FINAL record's usage must win, not the first's")
        XCTAssertEqual(row.outputTokens, 50)
        XCTAssertEqual(row.toolName, "Bash",
                       "a final record without a tool_use must not erase the earlier tool name")

        // session_metrics recomputes from the deduped turn.
        let metrics = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(metrics.totalInputTokens, 100)
        XCTAssertEqual(metrics.totalOutputTokens, 50)
        XCTAssertEqual(metrics.turnCount, 1)
    }

    func testLastRecordWinsReimportDoesNotInflate() throws {
        try writeJSONL([
            assistantLine(session: "s1", messageId: "m1", tool: "Bash", input: 10, output: 1),
            assistantLine(session: "s1", messageId: "m1", tool: nil, input: 100, output: 50)
        ], at: "s1.jsonl")

        _ = try runImport()
        let before = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))

        // Same-values re-import: the upsert writes back identical numbers.
        _ = try runImport()
        XCTAssertEqual(try database.transcriptTurnCount(sessionId: "s1"), 1)
        let after = try XCTUnwrap(database.metricsForSession(sessionId: "s1"))
        XCTAssertEqual(after.totalInputTokens, before.totalInputTokens)
        XCTAssertEqual(after.totalOutputTokens, before.totalOutputTokens)
        XCTAssertEqual(after.turnCount, before.turnCount)
        XCTAssertEqual(after.totalCostUsd, before.totalCostUsd, accuracy: 0.000001)
    }

    func testZeroUsageTrailingRecordDoesNotWipeFinalTallies() throws {
        // A usage-less partial after the tallied record (or a degenerate
        // re-import) must not zero out the persisted counts.
        let tallied = assistantLine(session: "s1", messageId: "m1", tool: "Bash", input: 100, output: 50)
        let zeroUsage = """
        {"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:00:01Z",\
        "cwd":"/work/test","message":{"id":"m1","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":0,"output_tokens":0,"cache_read_input_tokens":0,\
        "cache_creation_input_tokens":0},"content":[]}}
        """
        try writeJSONL([tallied, zeroUsage], at: "s1.jsonl")

        _ = try runImport()
        let row = try XCTUnwrap(database.transcriptTurn(messageId: "m1"))
        XCTAssertEqual(row.inputTokens, 100, "zero-usage newcomer skipped, final tallies kept")
        XCTAssertEqual(row.outputTokens, 50)
    }

}
