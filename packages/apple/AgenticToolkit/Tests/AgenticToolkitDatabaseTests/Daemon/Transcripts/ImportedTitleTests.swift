import XCTest
@testable import AgenticToolkitDatabase

/// Covers reading a session's `custom-title` out of the already-imported
/// `transcript_lines` instead of re-streaming the `.jsonl`.
///
/// The distinction these pin down is the one that makes the substitution safe:
/// an *authoritative* "this session has no title" (lines are stored, none is a
/// title) must be told apart from "the importer hasn't reached this session",
/// because only the first justifies skipping the file. Getting that wrong would
/// silently drop titles rather than merely cost memory.
final class ImportedTitleTests: XCTestCase {

    private var database: DaemonDatabase!
    private var tmpPath: String!

    override func setUpWithError() throws {
        let made = try TestDaemonDatabase.makeSessionDatabase()
        tmpPath = made.path
        database = made.db
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    // MARK: - Helpers

    private func line(
        _ lineNo: Int,
        session: String,
        type: String,
        json: String
    ) -> JSONLScanner.RawTranscriptLine {
        JSONLScanner.RawTranscriptLine(
            lineNo: lineNo,
            sessionId: session,
            entryUuid: UUID().uuidString,
            parentUuid: "",
            entryType: type,
            role: "",
            timestamp: "2026-07-30T00:00:00Z",
            isSidechain: false,
            rawJSON: json,
            isQueuedPrompt: QueuedPrompt.isQueuedPrompt(rawJSON: json)
        )
    }

    private func titleLine(_ lineNo: Int, session: String, title: String) -> JSONLScanner.RawTranscriptLine {
        line(lineNo, session: session, type: "custom-title",
             json: #"{"type":"custom-title","customTitle":"\#(title)","sessionId":"\#(session)"}"#)
    }

    private func chatterLine(_ lineNo: Int, session: String) -> JSONLScanner.RawTranscriptLine {
        line(lineNo, session: session, type: "assistant",
             json: #"{"type":"assistant","sessionId":"\#(session)"}"#)
    }

    // MARK: - Tests

    func testReturnsTheLatestTitleWhenSeveralWereSet() throws {
        let session = UUID().uuidString
        try database.insertTranscriptLines([
            titleLine(1, session: session, title: "first"),
            chatterLine(2, session: session),
            titleLine(3, session: session, title: "renamed"),
            chatterLine(4, session: session)
        ], filePath: "/tmp/\(session).jsonl")

        // "Latest" must match what a whole-file scan returned: the LAST occurrence,
        // not the first — a session retitled mid-run keeps its newest name.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .found("renamed"))
    }

    func testStoredLinesWithNoTitleAreAuthoritativelyAbsent() throws {
        let session = UUID().uuidString
        try database.insertTranscriptLines([
            chatterLine(1, session: session),
            chatterLine(2, session: session)
        ], filePath: "/tmp/\(session).jsonl")

        // `.absent`, not `.notImported`: this is what lets the startup pass stop
        // re-reading a large transcript that will never yield a title.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .absent)
    }

    func testUnknownSessionIsNotImportedRatherThanAbsent() throws {
        // No rows at all — the DB cannot answer, so the caller must fall back to
        // the file. Reporting `.absent` here would silently lose real titles.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: UUID().uuidString), .notImported)
    }

    func testTitlesAreScopedToTheirOwnSession() throws {
        let mine = UUID().uuidString
        let theirs = UUID().uuidString
        try database.insertTranscriptLines(
            [titleLine(1, session: theirs, title: "not mine")], filePath: "/tmp/\(theirs).jsonl")
        try database.insertTranscriptLines(
            [chatterLine(1, session: mine)], filePath: "/tmp/\(mine).jsonl")

        XCTAssertEqual(try database.latestCustomTitle(sessionId: mine), .absent)
        XCTAssertEqual(try database.latestCustomTitle(sessionId: theirs), .found("not mine"))
    }

    func testAMalformedTitleLineReadsAsAbsentNotAsACrash() throws {
        let session = UUID().uuidString
        try database.insertTranscriptLines([
            line(1, session: session, type: "custom-title", json: "{not json at all")
        ], filePath: "/tmp/\(session).jsonl")

        // Same tolerance the file-scanning path has: a line it can't decode is
        // skipped, and the session still counts as imported.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .absent)
    }

    func testAnEmptyTitleIsNotTreatedAsATitle() throws {
        let session = UUID().uuidString
        try database.insertTranscriptLines([
            titleLine(1, session: session, title: "")
        ], filePath: "/tmp/\(session).jsonl")

        // `enrich` only writes non-empty summaries; surfacing "" as `.found`
        // would make the caller overwrite a good summary with nothing.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .absent)
    }

    func testAnUnusableLastTitleFallsBackToTheLastUsableOne() throws {
        let session = UUID().uuidString
        try database.insertTranscriptLines([
            titleLine(1, session: session, title: "keep me"),
            titleLine(2, session: session, title: ""),
            line(3, session: session, type: "custom-title", json: "{not json at all")
        ], filePath: "/tmp/\(session).jsonl")

        // The file scan takes the last line that *parses to a non-empty title* and
        // skips the rest, so stopping at the last `custom-title` line full stop
        // would report `.absent` here — which the enricher trusts as authoritative
        // and writes no summary, losing a title the file scan finds.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .found("keep me"))
    }

    func testRawJSONParsingExtractsTheTitleField() {
        XCTAssertEqual(
            DaemonDatabase.customTitle(fromRawJSON: #"{"type":"custom-title","customTitle":"hello"}"#),
            "hello"
        )
        XCTAssertNil(DaemonDatabase.customTitle(fromRawJSON: #"{"type":"custom-title"}"#))
        XCTAssertNil(DaemonDatabase.customTitle(fromRawJSON: "garbage"))
    }
}
