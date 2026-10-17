import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import SQLite3

/// Covers the read that backs the Conversations window: the global newest-first
/// feed over `transcript_lines`, its attribution join, and the work-output
/// filter.
///
/// The classification rules themselves live in `ConversationExtractorTests`;
/// what is pinned here is everything the database adds on top — ordering,
/// paging, which session a line is labelled with, and the work-output filter
/// that leaves the feed holding the conversation and nothing else.
final class ConversationFeedTests: XCTestCase {

    private var database: DaemonDatabase!
    private var store: ConversationStore!
    private var tmpPath: String!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
        store = ConversationStore(database: opened.db)
    }

    override func tearDownWithError() throws {
        store = nil
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    // MARK: - Helpers

    private func line(
        _ lineNo: Int,
        session: String,
        type: String,
        at timestamp: String,
        json: String
    ) -> JSONLScanner.RawTranscriptLine {
        JSONLScanner.RawTranscriptLine(
            lineNo: lineNo,
            sessionId: session,
            entryUuid: UUID().uuidString,
            parentUuid: "",
            entryType: type,
            role: type,
            timestamp: timestamp,
            isSidechain: false,
            rawJSON: json,
            isQueuedPrompt: QueuedPrompt.isQueuedPrompt(rawJSON: json)
        )
    }

    private func prompt(_ lineNo: Int, session: String, at timestamp: String, _ text: String)
    -> JSONLScanner.RawTranscriptLine {
        line(lineNo, session: session, type: "user", at: timestamp,
             json: #"{"type":"user","message":{"role":"user","content":"\#(text)"}}"#)
    }

    private func reply(_ lineNo: Int, session: String, at timestamp: String, _ text: String)
    -> JSONLScanner.RawTranscriptLine {
        line(lineNo, session: session, type: "assistant", at: timestamp,
             json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                 + #""content":[{"type":"text","text":"\#(text)"}]}}"#)
    }

    private func progress(_ lineNo: Int, session: String, at timestamp: String, _ text: String)
    -> JSONLScanner.RawTranscriptLine {
        line(lineNo, session: session, type: "assistant", at: timestamp,
             json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","#
                 + #""content":[{"type":"text","text":"\#(text)"}]}}"#)
    }

    private func makeSession(cwd: String, branch: String) throws -> String {
        let session = UUID().uuidString
        try database.createSessionStubIfMissing(
            sessionId: session,
            cwd: cwd,
            model: "claude-opus-5",
            startedAt: "2026-09-01T00:00:00Z",
            lastActivityAt: "2026-09-01T00:00:00Z",
            gitBranch: branch,
            accountEmail: ""
        )
        return session
    }

    private func feed(
        limit: Int = 50, work: Bool = false, before: String? = nil, session: String? = nil
    ) throws -> [ConversationEntryDTO] {
        try store.conversationEntries(
            limit: limit, includeWorkOutput: work, before: before, sessionId: session)
    }

    // MARK: - The feed itself

    func testTheFeedInterleavesEverySessionNewestFirst() throws {
        // The window is a group chat, not a per-session log: two sessions talking
        // at once have to come back on one timeline, ordered by when things were
        // said and not by which session said them.
        let first = try makeSession(cwd: "/src/alpha", branch: "main")
        let second = try makeSession(cwd: "/src/beta", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: first, at: "2026-09-01T10:00:00Z", "alpha asks"),
            reply(2, session: first, at: "2026-09-01T10:00:02Z", "alpha answers")
        ], filePath: "/tmp/\(first).jsonl")
        try database.insertTranscriptLines([
            prompt(1, session: second, at: "2026-09-01T10:00:01Z", "beta asks")
        ], filePath: "/tmp/\(second).jsonl")

        XCTAssertEqual(try feed().map(\.text), ["alpha answers", "beta asks", "alpha asks"])
    }

    func testEachLineIsLabelledWithTheSessionItCameFrom() throws {
        // Attribution travels with the entry because the feed spans sessions —
        // a row the window can't label is a row it can't render.
        let session = try makeSession(cwd: "/Users/me/Development/stenographer", branch: "conversations")
        try database.updateSessionTranscriptTitle(
            sessionId: session, title: "conversations window", source: "custom")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], filePath: "/tmp/\(session).jsonl")

        let entry = try XCTUnwrap(try feed().first)
        XCTAssertEqual(entry.sessionId, session)
        XCTAssertEqual(entry.projectName, "stenographer")
        XCTAssertEqual(entry.gitBranch, "conversations")
        XCTAssertEqual(entry.sessionName, "conversations window")
    }

    func testAnUntitledSessionIsLabelledWithWhateverItHas() throws {
        // Titles arrive late — the enricher writes one when the session ends. A
        // live session is exactly the one a human most wants to see, so it has to
        // render with an empty name rather than be held back.
        let session = try makeSession(cwd: "/src/gamma", branch: "")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], filePath: "/tmp/\(session).jsonl")

        let entry = try XCTUnwrap(try feed().first)
        XCTAssertEqual(entry.projectName, "gamma")
        XCTAssertEqual(entry.sessionName, "")
        XCTAssertEqual(entry.gitBranch, "")
    }

    func testASummaryIsNotAName() throws {
        // The summarizer's line says what a session is doing. Headed as its
        // name, an unnamed session read as one called "writing a file".
        let session = try makeSession(cwd: "/src/adh-tools", branch: "main")
        database.updateSessionSummary("writing test_status_cmd.py", sessionId: session)
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try XCTUnwrap(try feed().first).sessionName, "")
    }

    // MARK: - Prompts typed while the agent works

    private func queued(_ lineNo: Int, session: String, at timestamp: String, _ text: String)
    -> JSONLScanner.RawTranscriptLine {
        line(lineNo, session: session, type: "attachment", at: timestamp,
             json: #"{"type":"attachment","attachment":{"type":"queued_command","prompt":"\#(text)","#
                 + #""commandMode":"prompt","origin":{"kind":"human"}}}"#)
    }

    func testAPromptTypedMidTurnTakesItsPlaceInTheFeed() throws {
        let session = try makeSession(cwd: "/src/alpha", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "start"),
            queued(2, session: session, at: "2026-09-01T10:00:05Z", "and also this"),
            reply(3, session: session, at: "2026-09-01T10:00:09Z", "done both")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed().map(\.text), ["done both", "and also this", "start"])
        XCTAssertEqual(try feed(session: session).map(\.text), ["done both", "and also this", "start"])
        XCTAssertEqual(try feed().first(where: { $0.text == "and also this" })?.kind, "prompt")
    }

    func testAMidTurnPromptStaysInItsOwnConversation() throws {
        let first = try makeSession(cwd: "/src/alpha", branch: "main")
        let second = try makeSession(cwd: "/src/beta", branch: "main")
        try database.insertTranscriptLines([
            queued(1, session: first, at: "2026-09-01T10:00:05Z", "only alpha")
        ], filePath: "/tmp/\(first).jsonl")
        try database.insertTranscriptLines([
            prompt(1, session: second, at: "2026-09-01T10:00:00Z", "beta")
        ], filePath: "/tmp/\(second).jsonl")

        XCTAssertEqual(try feed(session: second).map(\.text), ["beta"])
        XCTAssertEqual(try feed(session: first).map(\.text), ["only alpha"])
    }

    func testAMidTurnPromptOlderThanAFullPageWaitsForTheNextOne() throws {
        let session = try makeSession(cwd: "/src/alpha", branch: "main")
        try database.insertTranscriptLines([
            queued(1, session: session, at: "2026-09-01T09:00:00Z", "early"),
            prompt(2, session: session, at: "2026-09-01T10:00:00Z", "one"),
            prompt(3, session: session, at: "2026-09-01T10:00:01Z", "two")
        ], filePath: "/tmp/\(session).jsonl")

        let first = try feed(limit: 2)
        XCTAssertEqual(first.map(\.text), ["two", "one"])
        XCTAssertEqual(try feed(limit: 2, before: first.last?.timestamp).map(\.text), ["early"])
    }

    func testTheBackfillFindsMidTurnPromptsStoredBeforeTheImporterKnewThem() throws {
        let session = try makeSession(cwd: "/src/alpha", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "start"),
            queued(2, session: session, at: "2026-09-01T10:00:05Z", "late addition")
        ], filePath: "/tmp/\(session).jsonl")
        // What a database written before migration044 holds: the line, and no
        // record of it being a prompt.
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tmpPath, &handle), SQLITE_OK)
        XCTAssertEqual(sqlite3_exec(handle, "DELETE FROM conversation_queued_prompts", nil, nil, nil), SQLITE_OK)
        sqlite3_close(handle)
        XCTAssertEqual(try feed().map(\.text), ["start"])

        while database.backfillQueuedPromptsBatch(idSpan: 1) {}

        XCTAssertEqual(try feed().map(\.text), ["late addition", "start"])
        XCTAssertFalse(database.backfillQueuedPromptsBatch(), "a finished backfill stays finished")
    }

    func testTheBackfillFindsPromptsAnOlderDaemonStoredAfterItStarted() throws {
        // Two branches' daemons can take turns on one database, and the older
        // one stores lines without recording which are mid-turn prompts. Those
        // land ABOVE where the backfill started walking down from.
        let session = try makeSession(cwd: "/src/alpha2", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "start")
        ], filePath: "/tmp/\(session).jsonl")
        while database.backfillQueuedPromptsBatch(idSpan: 1) {}

        try database.insertTranscriptLines([
            queued(2, session: session, at: "2026-09-01T10:00:05Z", "stored by the old daemon")
        ], filePath: "/tmp/\(session).jsonl")
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tmpPath, &handle), SQLITE_OK)
        XCTAssertEqual(sqlite3_exec(handle, "DELETE FROM conversation_queued_prompts", nil, nil, nil), SQLITE_OK)
        sqlite3_close(handle)

        XCTAssertTrue(database.backfillQueuedPromptsBatch(idSpan: 1), "the new line is left to look at")
        while database.backfillQueuedPromptsBatch(idSpan: 1) {}
        XCTAssertEqual(try feed().map(\.text), ["stored by the old daemon", "start"])
    }

    // MARK: - The work-output filter

    func testNarrationIsNotInTheConversationAtAll() throws {
        // "Reading the query plan." is the agent talking about its own work. A
        // window for watching people and agents talk has no room for it: what a
        // reader wants under their question is the answer.
        let session = try makeSession(cwd: "/src/delta", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(2, session: session, at: "2026-09-01T10:00:01Z", "Reading the query plan.")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed().map(\.text), ["why is it slow"])
        XCTAssertEqual(try feed(work: true).map(\.text),
                       ["Reading the query plan.", "why is it slow"],
                       "the filter hides it; it is still there for anyone who asks")
    }

    func testTheQuestionAndItsAnswerLandNextToEachOther() throws {
        // The point of hiding narration: a turn that spent six lines getting
        // there reads as one question and one answer.
        let session = try makeSession(cwd: "/src/delta2", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(2, session: session, at: "2026-09-01T10:00:01Z", "Reading the query plan."),
            progress(3, session: session, at: "2026-09-01T10:00:02Z", "Now the index definitions."),
            reply(4, session: session, at: "2026-09-01T10:00:03Z", "It was a missing index.")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed().map(\.text), ["It was a missing index.", "why is it slow"])
        XCTAssertEqual(try feed(work: true).map(\.text), [
            "It was a missing index.", "Now the index definitions.",
            "Reading the query plan.", "why is it slow"
        ])
    }

    func testASessionThatHasOnlyNarratedSaysNothingYet() throws {
        // A session mid-turn contributes no row at all. That it is working is a
        // real thing a reader wants to know, and it is not the conversation —
        // whatever surfaces it, it is not a line in here.
        let first = try makeSession(cwd: "/src/nu", branch: "main")
        let second = try makeSession(cwd: "/src/xi", branch: "main")
        try database.insertTranscriptLines([
            progress(1, session: first, at: "2026-09-01T10:00:00Z", "first is reading the plan"),
            progress(2, session: second, at: "2026-09-01T10:00:01Z", "second is running tests")
        ], filePath: "/tmp/both.jsonl")

        XCTAssertTrue(try feed().isEmpty)
    }

    func testHidingNarrationDoesNotHideWhatCameAfterIt() throws {
        // The filter drops lines, not rows around them: a page whose newest
        // entry is narration still returns the prompt underneath it.
        let session = try makeSession(cwd: "/src/omicron", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(2, session: session, at: "2026-09-01T10:00:01Z", "reading the plan")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed().map(\.text), ["why is it slow"])
    }

    func testAskingForMoreThanExistsReturnsWhatExists() throws {
        // The read scans more rows than it returns, because kind is only known
        // after parsing. A transcript with nothing showable in it must still
        // terminate.
        let session = try makeSession(cwd: "/src/epsilon", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "assistant", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","#
                     + #""content":[{"type":"thinking","thinking":"weighing it"}]}}"#)
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertTrue(try feed(limit: 500).isEmpty)
    }

    func testASessionAProgramIsDrivingIsNotInTheFeedAtAll() throws {
        // `claude -p` under a script: the "prompt" is the program's 30,000-word
        // instructions and the "reply" is the JSON it asked for. Both sides are
        // machinery, and either one alone fills a window this size.
        let session = try makeSession(cwd: "/src/lambda", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "user", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"user","entrypoint":"sdk-cli","message":{"role":"user","#
                     + #""content":"You are reviewing writing the way a careful editor would."}}"#),
            line(2, session: session, type: "assistant", at: "2026-09-01T10:00:01Z",
                 json: #"{"type":"assistant","entrypoint":"sdk-cli","message":{"role":"assistant","#
                     + #""stop_reason":"end_turn","content":[{"type":"text","text":"[{\"title\":\"x\"}]"}]}}"#),
            prompt(3, session: session, at: "2026-09-01T10:00:02Z", "and this one I typed")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed(work: true).map(\.text), ["and this one I typed"])
    }

    func testAnEditorIntegrationIsAPersonTyping() throws {
        // The rule keys on the `sdk-` prefix, not on an allow-list, so a new
        // editor front end shows up and a new SDK binding does not.
        let session = try makeSession(cwd: "/src/mu", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "user", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"user","entrypoint":"claude-desktop","message":{"role":"user","#
                     + #""content":"from the desktop app"}}"#)
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed().map(\.text), ["from the desktop app"])
    }

    // MARK: - One conversation on its own

    func testNarrowingToASessionReturnsThatSessionAndNothingElse() throws {
        let first = try makeSession(cwd: "/src/rho", branch: "main")
        let second = try makeSession(cwd: "/src/sigma", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: first, at: "2026-09-01T10:00:00Z", "rho asks"),
            reply(2, session: first, at: "2026-09-01T10:00:02Z", "rho answers")
        ], filePath: "/tmp/\(first).jsonl")
        try database.insertTranscriptLines([
            prompt(1, session: second, at: "2026-09-01T10:00:01Z", "sigma asks")
        ], filePath: "/tmp/\(second).jsonl")

        XCTAssertEqual(try feed(session: first).map(\.text), ["rho answers", "rho asks"])
        XCTAssertEqual(try feed(session: second).map(\.text), ["sigma asks"])
    }

    /// The whole reason the narrowing is a parameter and not a filter over the
    /// merged answer. The merged feed is a *page* — the newest few hundred lines
    /// across every session — so a quiet conversation's share of it is whatever
    /// happens to fit. Sieving that would show a reader a conversation with most
    /// of itself missing; asking the database for it returns it whole.
    func testAQuietSessionComesBackWholeEvenWhenTheMergedPageHasNoneOfIt() throws {
        let quiet = try makeSession(cwd: "/src/tau", branch: "main")
        let loud = try makeSession(cwd: "/src/upsilon", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: quiet, at: "2026-09-01T10:00:00Z", "quiet asks"),
            reply(2, session: quiet, at: "2026-09-01T10:00:01Z", "quiet answers")
        ], filePath: "/tmp/\(quiet).jsonl")
        try database.insertTranscriptLines(
            (0..<40).map { index in
                prompt(index + 1, session: loud,
                       at: "2026-09-01T11:00:\(String(format: "%02d", index))Z", "loud \(index)")
            }, filePath: "/tmp/\(loud).jsonl")

        let page = try feed(limit: 10)
        XCTAssertFalse(page.contains { $0.sessionId == quiet },
                       "the fixture is wrong: the quiet session has to be off the merged page")
        XCTAssertEqual(try feed(limit: 10, session: quiet).map(\.text),
                       ["quiet answers", "quiet asks"])
    }

    func testANarrowedReadPagesBackwardsTheSameWay() throws {
        // The scoped read takes its order from a different index, so the paging
        // cursor has to keep working across that change — same `before`, same
        // newest-first pages.
        let session = try makeSession(cwd: "/src/phi", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "one"),
            prompt(2, session: session, at: "2026-09-01T10:00:01Z", "two"),
            prompt(3, session: session, at: "2026-09-01T10:00:02Z", "three")
        ], filePath: "/tmp/\(session).jsonl")

        let page = try feed(limit: 2, session: session)
        XCTAssertEqual(page.map(\.text), ["three", "two"])
        let older = try XCTUnwrap(page.last).timestamp
        XCTAssertEqual(try feed(limit: 2, before: older, session: session).map(\.text), ["one"])
    }

    func testAnEmptySessionIdIsTheMergedFeed() throws {
        // The window passes whatever the row carried; a row with no source id is
        // not a request for a conversation called "".
        let session = try makeSession(cwd: "/src/chi", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed(session: "").map(\.text), ["hi"])
    }

    func testTheWorkOutputFilterStillAppliesWhenNarrowed() throws {
        let session = try makeSession(cwd: "/src/psi", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(2, session: session, at: "2026-09-01T10:00:01Z", "reading the plan"),
            reply(3, session: session, at: "2026-09-01T10:00:02Z", "a missing index")
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed(session: session).map(\.text),
                       ["a missing index", "why is it slow"])
        XCTAssertEqual(try feed(work: true, session: session).map(\.text),
                       ["a missing index", "reading the plan", "why is it slow"])
    }

    // MARK: - Paging

    func testPagingBackwardsPicksUpWhereThePageEnded() throws {
        let session = try makeSession(cwd: "/src/zeta", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:00Z", "one"),
            prompt(2, session: session, at: "2026-09-01T10:00:01Z", "two"),
            prompt(3, session: session, at: "2026-09-01T10:00:02Z", "three")
        ], filePath: "/tmp/\(session).jsonl")

        let page = try feed(limit: 2)
        XCTAssertEqual(page.map(\.text), ["three", "two"])
        let older = try XCTUnwrap(page.last).timestamp
        XCTAssertEqual(try feed(limit: 2, before: older).map(\.text), ["one"])
    }

    func testTheLimitIsCountedInLinesNotRows() throws {
        // A thinking block and the text after it come out of one row, so the
        // limit has to be counted in lines, not rows. An entry that is bigger
        // than the limit all by itself still comes back whole — see the
        // mid-entry test below for why half of one is worse than a page that
        // overshoots by a line.
        let session = try makeSession(cwd: "/src/eta", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "assistant", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                     + #""content":[{"type":"thinking","thinking":"weighing it"},"#
                     + #"{"type":"text","text":"go with B"}]}}"#)
        ], filePath: "/tmp/\(session).jsonl")

        XCTAssertEqual(try feed(limit: 1, work: true).count, 2, "the lone entry is not cut in half")
        XCTAssertEqual(try feed(work: true).map(\.kind), ["reply", "thinking"])
    }

    func testIdsAreUniqueAcrossBlocksOfTheSameEntry() throws {
        let session = try makeSession(cwd: "/src/theta", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "assistant", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                     + #""content":[{"type":"thinking","thinking":"weighing it"},"#
                     + #"{"type":"text","text":"go with B"}]}}"#)
        ], filePath: "/tmp/\(session).jsonl")

        let ids = try feed(work: true).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// A block's id is a property of the transcript, not of what the caller
    /// asked to see. Numbering after the filter moved every id whenever the
    /// window's "show work output" toggle moved, and the window read that as a
    /// feed full of brand-new rows.
    func testAnIdDoesNotMoveWhenTheWorkOutputFilterChanges() throws {
        let session = try makeSession(cwd: "/src/iota", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "assistant", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                     + #""content":[{"type":"thinking","thinking":"weighing it"},"#
                     + #"{"type":"text","text":"go with B"}]}}"#)
        ], filePath: "/tmp/\(session).jsonl")

        let shown = try XCTUnwrap(try feed().first)
        let withWork = try XCTUnwrap(try feed(work: true).first { $0.kind == "reply" })
        XCTAssertEqual(shown.id, withWork.id)
    }

    /// The id is `transcript_lines.id * 1000 + blockIndex`, so a block index of
    /// 1000 is the next entry's block 0. Capping the blocks *after* the
    /// work-output filter counts only the blocks the caller wanted, so an entry
    /// whose thousandth block is the first one kept sails past the cap and
    /// lands on top of the next entry's identity.
    func testAnEntryLongerThanTheIdStrideCannotCollideWithTheNextOne() throws {
        let session = try makeSession(cwd: "/src/lambda", branch: "main")
        let thinking = (0..<1000)
            .map { #"{"type":"thinking","thinking":"step \#($0)"}"# }
            .joined(separator: ",")
        try database.insertTranscriptLines([
            line(1, session: session, type: "assistant", at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                     + #""content":[\#(thinking),{"type":"text","text":"go with B"}]}}"#),
            reply(2, session: session, at: "2026-09-01T10:00:01Z", "and here is why")
        ], filePath: "/tmp/\(session).jsonl")

        let ids = try feed().map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count,
                       "two rows are fighting over one id")
    }

    /// The merged read orders by `timestamp`; a read narrowed to one session has
    /// to as well, or the same feed reads newest-first in one mode and by
    /// insertion order in the other. They differ whenever a file is imported out
    /// of order or a line is backfilled.
    func testANarrowedReadIsOrderedByTimeNotByInsertion() throws {
        let session = try makeSession(cwd: "/src/mu", branch: "main")
        try database.insertTranscriptLines([
            prompt(1, session: session, at: "2026-09-01T10:00:02Z", "asked second"),
            prompt(2, session: session, at: "2026-09-01T10:00:01Z", "asked first")
        ], filePath: "/tmp/\(session).jsonl")

        let texts = try feed(session: session).map(\.text)
        XCTAssertEqual(texts, ["asked second", "asked first"],
                       "the narrowed read fell back on insertion order")
    }

    /// Pages are cut on `timestamp`, and every block of one entry shares one —
    /// so a page that stopped mid-entry didn't defer the rest, it lost it: the
    /// next page asks for `timestamp <` that same value. The entry has to be
    /// held back whole instead.
    func testAPageEndsOnAnEntryBoundaryAndTheNextPageHasTheWholeEntry() throws {
        let session = try makeSession(cwd: "/src/kappa", branch: "main")
        try database.insertTranscriptLines([
            line(1, session: session, type: "assistant", at: "2026-09-01T10:00:01Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                     + #""content":[{"type":"thinking","thinking":"weighing it"},"#
                     + #"{"type":"text","text":"go with B"}]}}"#),
            prompt(2, session: session, at: "2026-09-01T10:00:02Z", "newest")
        ], filePath: "/tmp/\(session).jsonl")

        let page = try feed(limit: 2, work: true)
        XCTAssertEqual(page.map(\.text), ["newest"], "the two-line entry is held back whole")

        let older = try XCTUnwrap(page.last).timestamp
        XCTAssertEqual(try feed(limit: 2, work: true, before: older).map(\.text),
                       ["go with B", "weighing it"])
    }
}
