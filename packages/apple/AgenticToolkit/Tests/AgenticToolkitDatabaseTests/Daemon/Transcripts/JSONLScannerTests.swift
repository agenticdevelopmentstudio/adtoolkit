import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase
import Foundation

final class JSONLScannerTests: XCTestCase {

    func testParsesAssistantTurnWithTokensAndToolName() throws {
        let line = """
        {"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/work","gitBranch":"main","message":{"id":"m-abc",\
        "model":"claude-sonnet-4-6","usage":{"input_tokens":100,\
        "output_tokens":50,"cache_read_input_tokens":20,"cache_creation_input_tokens":5},\
        "content":[{"type":"tool_use","name":"Edit","input":{}}]}}
        """
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertEqual(turn.kind, .assistant)
        XCTAssertEqual(turn.sessionId, "s1")
        XCTAssertEqual(turn.timestamp, "2026-04-14T10:00:00Z")
        XCTAssertEqual(turn.cwd, "/work")
        XCTAssertEqual(turn.gitBranch, "main")
        XCTAssertEqual(turn.model, "claude-sonnet-4-6")
        XCTAssertEqual(turn.messageId, "m-abc")
        XCTAssertEqual(turn.inputTokens, 100)
        XCTAssertEqual(turn.outputTokens, 50)
        XCTAssertEqual(turn.cacheReadTokens, 20)
        XCTAssertEqual(turn.cacheCreationTokens, 5)
        XCTAssertEqual(turn.toolName, "Edit")
    }

    func testParsesUserTurnWithMinimalFields() throws {
        let line = #"{"type":"user","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z","cwd":"/work"}"#
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertEqual(turn.kind, .user)
        XCTAssertEqual(turn.sessionId, "s1")
        XCTAssertEqual(turn.inputTokens, 0)
        XCTAssertEqual(turn.toolName, "")
    }

    func testRejectsMissingType() {
        let line = #"{"sessionId":"s1","timestamp":"2026-04-14T10:00:00Z"}"#
        XCTAssertNil(JSONLScanner.parse(line))
    }

    func testRejectsUnknownType() {
        let line = #"{"type":"system","sessionId":"s1"}"#
        XCTAssertNil(JSONLScanner.parse(line))
    }

    func testRejectsMissingSessionId() {
        let line = #"{"type":"assistant","timestamp":"2026-04-14T10:00:00Z"}"#
        XCTAssertNil(JSONLScanner.parse(line))
    }

    func testRejectsMalformedJSON() {
        XCTAssertNil(JSONLScanner.parse("not json {"))
        XCTAssertNil(JSONLScanner.parse(""))
    }

    func testTolerantOfMissingOptionalFields() throws {
        // Old Claude version: no gitBranch, no usage block.
        let line = #"""
        {"type":"assistant","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z",\#
        "cwd":"/w","message":{"model":"claude-opus-4-5","id":"m-1"}}
        """#
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertEqual(turn.inputTokens, 0)
        XCTAssertEqual(turn.outputTokens, 0)
        XCTAssertEqual(turn.toolName, "")
        XCTAssertEqual(turn.gitBranch, "")
    }

    func testTakesFirstToolUseWhenMultiple() throws {
        let line = """
        {"type":"assistant","sessionId":"s","timestamp":"t","cwd":"/w",\
        "message":{"id":"m","model":"x","usage":{"input_tokens":1,\
        "output_tokens":1,"cache_read_input_tokens":0,"cache_creation_input_tokens":0},\
        "content":[{"type":"text","text":"hi"},{"type":"tool_use","name":"Read"},\
        {"type":"tool_use","name":"Edit"}]}}
        """
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertEqual(turn.toolName, "Read")
    }

    func testParseFileSkipsBadLinesAndReturnsGoodTurns() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("jsonl-\(UUID().uuidString).jsonl")
        let assistantLine = """
        {"type":"assistant","sessionId":"s","timestamp":"2026-04-14T10:00:01Z",\
        "cwd":"/w","message":{"id":"m1","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":0,\
        "cache_creation_input_tokens":0},"content":[{"type":"tool_use","name":"Bash"}]}}
        """
        let content = """
        {"type":"user","sessionId":"s","timestamp":"2026-04-14T10:00:00Z","cwd":"/w"}
        not json at all
        \(assistantLine)

        {"type":"ignored"}
        """
        try content.write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let turns = try JSONLScanner.parseFile(at: tmp)
        XCTAssertEqual(turns.count, 2)
        XCTAssertEqual(turns[0].kind, .user)
        XCTAssertEqual(turns[1].kind, .assistant)
        XCTAssertEqual(turns[1].toolName, "Bash")
    }

    func testDiscoverFilesRecurses() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("discover-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let nested = root.appendingPathComponent("project-a/sessions")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "".write(to: root.appendingPathComponent("a.jsonl"), atomically: true, encoding: .utf8)
        try "".write(to: nested.appendingPathComponent("b.jsonl"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("ignored.txt"), atomically: true, encoding: .utf8)

        let found = JSONLScanner.discoverFiles(under: root)
        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(found.map(\.lastPathComponent), ["a.jsonl", "b.jsonl"])
    }

    func testDiscoverFilesReportsEachFilesModificationDate() throws {
        // The importer selects and orders its batch by these dates, and now takes
        // them from the directory walk instead of re-`stat`ing every one of the
        // ~8,500 transcripts on a real machine. A wrong date here would silently
        // park or over-advance the import cursor, so it is worth pinning.
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("discover-mtime-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let older = root.appendingPathComponent("older.jsonl")
        let newer = root.appendingPathComponent("newer.jsonl")
        try "".write(to: older, atomically: true, encoding: .utf8)
        try "".write(to: newer, atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("ignored.txt"), atomically: true, encoding: .utf8)

        let olderDate = Date(timeIntervalSince1970: 1_700_000_000)
        let newerDate = Date(timeIntervalSince1970: 1_800_000_000)
        try FileManager.default.setAttributes([.modificationDate: olderDate], ofItemAtPath: older.path)
        try FileManager.default.setAttributes([.modificationDate: newerDate], ofItemAtPath: newer.path)

        let found = JSONLScanner.discoverFilesWithModificationDates(under: root)
        XCTAssertEqual(found.map(\.url.lastPathComponent), ["newer.jsonl", "older.jsonl"],
                       "sorted by path, as `discoverFiles` has always been")
        let byName = Dictionary(uniqueKeysWithValues: found.map { ($0.url.lastPathComponent, $0.modified) })
        XCTAssertEqual(byName["older.jsonl"]?.timeIntervalSince1970, olderDate.timeIntervalSince1970)
        XCTAssertEqual(byName["newer.jsonl"]?.timeIntervalSince1970, newerDate.timeIntervalSince1970)
    }

    // MARK: - scanRawLines

    func testScanRawLinesCapturesEveryLineType() throws {
        let lines = [
            #"{"type":"summary","summary":"Prior work"}"#,
            // swiftlint:disable:next line_length
            #"{"type":"user","sessionId":"s1","timestamp":"2026-04-14T10:00:00Z","message":{"role":"user","content":"hi"}}"#,
            // swiftlint:disable:next line_length
            #"{"type":"assistant","sessionId":"s1","uuid":"u-2","parentUuid":"u-1","timestamp":"2026-04-14T10:00:01Z","message":{"role":"assistant","model":"claude-sonnet-4-6"}}"#
        ]
        let url = try writeTempJSONL(lines, stem: "s1")
        let raw = try JSONLScanner.scanRawLines(at: url)

        XCTAssertEqual(raw.count, 3)  // summary line INCLUDED (parse() would drop it)
        XCTAssertEqual(raw[0].entryType, "summary")
        XCTAssertEqual(raw[0].sessionId, "s1")   // summary has no sessionId → file-stem fallback
        XCTAssertEqual(raw[0].rawJSON, lines[0]) // verbatim
        XCTAssertEqual(raw[0].lineNo, 1)

        XCTAssertEqual(raw[1].entryType, "user")
        XCTAssertEqual(raw[1].role, "user")
        XCTAssertEqual(raw[1].sessionId, "s1")
        XCTAssertEqual(raw[1].lineNo, 2)

        XCTAssertEqual(raw[2].entryUuid, "u-2")
        XCTAssertEqual(raw[2].parentUuid, "u-1")
        XCTAssertEqual(raw[2].role, "assistant")
    }

    func testScanRawLinesKeepsMalformedLineVerbatim() throws {
        let lines = [
            "this is not json",
            #"{"type":"user","sessionId":"s9","timestamp":"t"}"#
        ]
        let url = try writeTempJSONL(lines, stem: "s9")
        let raw = try JSONLScanner.scanRawLines(at: url)

        XCTAssertEqual(raw.count, 2)
        XCTAssertEqual(raw[0].rawJSON, "this is not json")
        XCTAssertEqual(raw[0].entryType, "")     // no metadata extractable
        XCTAssertEqual(raw[0].sessionId, "s9")   // file-stem fallback
        XCTAssertEqual(raw[1].sessionId, "s9")
    }

    func testScanRawLinesMarksSidechain() throws {
        let url = try writeTempJSONL([
            #"{"type":"user","sessionId":"s2","isSidechain":true,"timestamp":"t"}"#
        ], stem: "s2")
        let raw = try JSONLScanner.scanRawLines(at: url)
        XCTAssertTrue(raw[0].isSidechain)
    }

    private func writeTempJSONL(_ lines: [String], stem: String) throws -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("scanner-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(stem).jsonl")
        try (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Pricing

    func testCostCalculationSonnet() {
        let cost = TranscriptPricing.cost(
            model: "claude-sonnet-4-6",
            inputTokens: 1_000_000,
            outputTokens: 0,
            cacheReadTokens: 0,
            cacheCreationTokens: 0
        )
        XCTAssertEqual(cost, 3.00, accuracy: 0.001)
    }

    func testCostCalculationUnknownModelIsZero() {
        let cost = TranscriptPricing.cost(
            model: "nonsense",
            inputTokens: 1_000_000,
            outputTokens: 1_000_000,
            cacheReadTokens: 0,
            cacheCreationTokens: 0
        )
        XCTAssertEqual(cost, 0.0, accuracy: 0.001)
    }

    func testCostCalculationCacheReadDiscount() {
        // 1M cache_read tokens at 10% of input rate ($1.00/M for haiku) = $0.10
        let cost = TranscriptPricing.cost(
            model: "claude-haiku-4-5",
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: 1_000_000,
            cacheCreationTokens: 0
        )
        XCTAssertEqual(cost, 0.10, accuracy: 0.001)
    }

    func testCostCalculationFableCacheReadIsQuarterRate() {
        // Fable 5.1 alone bills cache reads at 0.025x: 1M × $10 × 0.025 = $0.25
        let cost = TranscriptPricing.cost(
            model: "claude-fable-5-1",
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: 1_000_000,
            cacheCreationTokens: 0
        )
        XCTAssertEqual(cost, 0.25, accuracy: 0.001)
    }

    func testCacheWriteMultiplierFollowsTTL() {
        // 1M cache_creation tokens on opus-5 ($5/M input): 1.25× at 5m, 2× at 1h.
        // The 1h tokens are a *subset* of the total, the way the transcript
        // reports them (`cache_creation.ephemeral_1h_input_tokens` alongside a
        // `cache_creation_input_tokens` that already includes it).
        let fiveMinute = TranscriptPricing.cost(
            model: "claude-opus-5",
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: 0,
            cacheCreationTokens: 1_000_000
        )
        XCTAssertEqual(fiveMinute, 6.25, accuracy: 0.001)

        let oneHour = TranscriptPricing.cost(
            model: "claude-opus-5",
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: 0,
            cacheCreationTokens: 1_000_000,
            cacheCreation1hTokens: 1_000_000
        )
        XCTAssertEqual(oneHour, 10.00, accuracy: 0.001)

        // Half and half: 500k × 1.25× + 500k × 2× = $3.125 + $5.00.
        let mixed = TranscriptPricing.cost(
            model: "claude-opus-5",
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: 0,
            cacheCreationTokens: 1_000_000,
            cacheCreation1hTokens: 500_000
        )
        XCTAssertEqual(mixed, 8.125, accuracy: 0.001)

        XCTAssertEqual(
            TranscriptPricing.cacheWriteCost(model: "claude-opus-5", tokens: 1_000_000, ttl: "1h"),
            10.00,
            accuracy: 0.001
        )
    }

    func testCacheWriteCostClampsA1hComponentThatExceedsItsTotal() {
        // The two numbers come from different JSONL fields, so a total that lags
        // its own 1h component is possible; billing the difference as *negative*
        // 5-minute tokens would credit money back. Clamped, this is 1M at 2×.
        let cost = TranscriptPricing.cost(
            model: "claude-opus-5",
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: 0,
            cacheCreationTokens: 1_000_000,
            cacheCreation1hTokens: 4_000_000
        )
        XCTAssertEqual(cost, 10.00, accuracy: 0.001)
    }

    func testAnUnrecognisedTTLIsReportedRatherThanPricedSilently() {
        // `cacheWriteMultiplier` falls back to the 5-minute 1.25× for anything
        // it doesn't recognise, which is the right default and the wrong thing
        // to report as measured. `isKnownTTL` is what lets the insight say so.
        XCTAssertTrue(TranscriptPricing.isKnownTTL("1h"))
        XCTAssertTrue(TranscriptPricing.isKnownTTL("5m"))
        XCTAssertFalse(TranscriptPricing.isKnownTTL("30m"))
        XCTAssertFalse(TranscriptPricing.isKnownTTL(nil))
        XCTAssertEqual(TranscriptPricing.cacheWriteMultiplier(ttl: "30m"), 1.25, accuracy: 0.001)
    }

    func testCanonicalModelIDStripsADateSuffix() {
        // Anthropic ships dated ids (`claude-haiku-4-5-20251001`); the table is
        // keyed undated, and a family fallback would otherwise price a known
        // model through a keyword guess.
        XCTAssertEqual(TranscriptPricing.canonicalModelID("claude-haiku-4-5-20251001"),
                       "claude-haiku-4-5")
        XCTAssertEqual(TranscriptPricing.canonicalModelID("claude-opus-5"), "claude-opus-5")
        XCTAssertEqual(
            TranscriptPricing.cost(
                model: "claude-haiku-4-5-20251001",
                inputTokens: 1_000_000, outputTokens: 0,
                cacheReadTokens: 0, cacheCreationTokens: 0
            ),
            1.00, accuracy: 0.001
        )
    }

    func testCostCalculationFamilyFallback() {
        // Unknown opus variant matches via "opus" keyword, priced at the
        // family's *current* generation (Opus 5.5), not a retired rate.
        let cost = TranscriptPricing.cost(
            model: "claude-opus-future-9-9",
            inputTokens: 1_000_000,
            outputTokens: 0,
            cacheReadTokens: 0,
            cacheCreationTokens: 0
        )
        XCTAssertEqual(cost, 4.00, accuracy: 0.001)
    }

    func testCostCalculationMatchesPublishedRates() {
        // 1M each of input, output and cache read, at the rates on
        // platform.claude.com/docs/en/about-claude/pricing (2026-09-26).
        func cost(_ model: String) -> Double {
            TranscriptPricing.cost(
                model: model, inputTokens: 1_000_000, outputTokens: 1_000_000,
                cacheReadTokens: 1_000_000, cacheCreationTokens: 0
            )
        }
        XCTAssertEqual(cost("claude-opus-5-5"), 4 + 20 + 0.20, accuracy: 0.001)
        // Opus 4.5–4.7 dropped to $5/$25; only 4.1 and older keep $15/$75.
        for model in ["claude-opus-4-7", "claude-opus-4-6", "claude-opus-4-5-20251101"] {
            XCTAssertEqual(cost(model), 5 + 25 + 0.50, accuracy: 0.001, model)
        }
        XCTAssertEqual(cost("claude-opus-4-1"), 15 + 75 + 1.50, accuracy: 0.001)
        XCTAssertEqual(cost("claude-mythos-5-1"), 10 + 50 + 0.25, accuracy: 0.001)
        XCTAssertEqual(cost("claude-fable-5"), 10 + 50 + 1.00, accuracy: 0.001)
    }

    func testCostCalculationPricesEveryModelSeenInCapture() {
        // Regression guard: `claude-fable-5-1` matched no family keyword before
        // this table was corrected, so every Fable session costed $0.
        for model in ["claude-opus-5", "claude-opus-5-5", "claude-fable-5-1", "claude-sonnet-5", "claude-mythos-5-1"] {
            XCTAssertNotNil(TranscriptPricing.price(for: model), "no price for \(model)")
        }
    }

    // MARK: - Streaming reads

    /// Writes `text` verbatim (no trailing newline added) to a temp file that is
    /// removed when the test ends.
    private func makeFile(_ text: String) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("scanner-\(UUID().uuidString).jsonl")
        try Data(text.utf8).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func entry(_ id: String) -> String {
        #"{"type":"user","sessionId":"s1","uuid":"\#(id)"}"#
    }

    func testStreamEmitsEveryLineAndConsumesTheWholeFile() throws {
        let text = [entry("a"), entry("b"), entry("c")].joined(separator: "\n") + "\n"
        let url = try makeFile(text)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(at: url) { seen += $0 }

        XCTAssertEqual(seen, [entry("a"), entry("b"), entry("c")])
        XCTAssertEqual(result.linesEmitted, 3)
        XCTAssertEqual(result.bytesConsumed, Int64(text.utf8.count))
    }

    func testStreamConsumesAnUnterminatedFinalEntry() throws {
        // Claude's transcripts routinely lack a trailing newline. That last entry
        // is complete JSON, so it must be both emitted AND sealed behind the
        // cursor — otherwise every future pass re-reads it forever.
        let text = [entry("a"), entry("b")].joined(separator: "\n")
        let url = try makeFile(text)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(at: url) { seen += $0 }

        XCTAssertEqual(seen.count, 2)
        XCTAssertEqual(result.linesEmitted, 2)
        XCTAssertEqual(
            result.bytesConsumed, Int64(text.utf8.count),
            "a complete final entry must advance the cursor even without its newline"
        )
    }

    func testStreamLeavesATornFinalEntryUnconsumed() throws {
        let complete = entry("a")
        let torn = #"{"type":"user","sessionId":"s1","uu"#
        let url = try makeFile(complete + "\n" + torn)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(at: url) { seen += $0 }

        XCTAssertEqual(seen, [complete], "a half-written line must not be emitted")
        XCTAssertEqual(result.linesEmitted, 1)
        XCTAssertEqual(
            result.bytesConsumed, Int64((complete + "\n").utf8.count),
            "the torn bytes stay unconsumed so the next pass re-reads them whole"
        )
    }

    func testStreamResumesFromAByteOffset() throws {
        let head = entry("a") + "\n"
        let tail = entry("b") + "\n"
        let url = try makeFile(head + tail)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(
            at: url, startingAtByte: Int64(head.utf8.count)
        ) { seen += $0 }

        XCTAssertEqual(seen, [entry("b")], "resuming must skip what the cursor already covered")
        XCTAssertEqual(result.linesEmitted, 1)
        XCTAssertEqual(result.bytesConsumed, Int64((head + tail).utf8.count))
    }

    func testStreamSplitsLinesAcrossReadBuffers() throws {
        // A line longer than one buffer must survive being reassembled from
        // multiple reads — the whole point of the chunked reader.
        let long = #"{"type":"user","sessionId":"s1","pad":"\#(String(repeating: "x", count: 5000))"}"#
        let text = [entry("a"), long, entry("b")].joined(separator: "\n") + "\n"
        let url = try makeFile(text)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(
            at: url, linesPerChunk: 2, bufferSize: 64
        ) { seen += $0 }

        XCTAssertEqual(seen, [entry("a"), long, entry("b")])
        XCTAssertEqual(result.bytesConsumed, Int64(text.utf8.count))
    }

    func testStreamSkipsBlankLinesButStillConsumesThem() throws {
        let text = entry("a") + "\n\n\n" + entry("b") + "\n"
        let url = try makeFile(text)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(at: url) { seen += $0 }

        XCTAssertEqual(seen, [entry("a"), entry("b")])
        XCTAssertEqual(result.linesEmitted, 2, "blank lines consume no line number")
        XCTAssertEqual(result.bytesConsumed, Int64(text.utf8.count))
    }

    func testStreamOnEmptyFileEmitsNothing() throws {
        let url = try makeFile("")
        var calls = 0
        let result = try JSONLScanner.streamCompleteLines(at: url) { _ in calls += 1 }
        XCTAssertEqual(calls, 0, "an empty file must not invoke the body at all")
        XCTAssertEqual(result.linesEmitted, 0)
        XCTAssertEqual(result.bytesConsumed, 0)
    }

    func testStreamCountsUndecodableLinesInsteadOfSilentlyLosingThem() throws {
        // A line whose bytes aren't UTF-8 can't be emitted, and it can't park the
        // cursor either (that would re-read the file forever), so it is permanently
        // dropped. `linesSkipped` is the only signal that a transcript lost content:
        // `linesSeen - linesInserted` can't say it, because that gap is normally dedup.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("scanner-badutf8-\(UUID().uuidString).jsonl")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        var bytes = Data(entry("a").utf8)
        bytes.append(0x0A)
        bytes.append(contentsOf: [0xFF, 0xFE, 0xFF])  // never valid UTF-8
        bytes.append(0x0A)
        bytes.append(contentsOf: Data(entry("b").utf8))
        bytes.append(0x0A)
        try bytes.write(to: url)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(at: url) { seen += $0 }

        XCTAssertEqual(seen, [entry("a"), entry("b")], "the good lines either side must survive")
        XCTAssertEqual(result.linesEmitted, 2)
        XCTAssertEqual(result.linesSkipped, 1, "the undecodable line must be counted, not vanish")
        XCTAssertEqual(
            result.bytesConsumed, Int64(bytes.count),
            "a permanently-undecodable line must still advance the cursor past itself"
        )
    }

    func testStreamHandlesManyLinesArrivingAcrossManySmallReads() throws {
        // The scan resumes from where the previous read left off rather than
        // re-scanning the whole pending buffer for newlines each time. With a tiny
        // buffer and a long line-free stretch that difference is quadratic, so this
        // both pins the behaviour and would time out if the rescan came back.
        let long = #"{"type":"user","sessionId":"s1","pad":"\#(String(repeating: "x", count: 300_000))"}"#
        let text = ([entry("a"), long] + (0..<200).map { entry("e\($0)") }).joined(separator: "\n") + "\n"
        let url = try makeFile(text)

        var seen: [String] = []
        let result = try JSONLScanner.streamCompleteLines(
            at: url, linesPerChunk: 10, bufferSize: 4096
        ) { seen += $0 }

        XCTAssertEqual(seen.count, 202)
        XCTAssertEqual(seen[1], long, "the over-long line must be reassembled intact")
        XCTAssertEqual(result.linesEmitted, 202)
        XCTAssertEqual(result.linesSkipped, 0)
        XCTAssertEqual(result.bytesConsumed, Int64(text.utf8.count))
    }

    func testStreamChunksAreBoundedByLinesPerChunk() throws {
        let text = (0..<7).map { entry("e\($0)") }.joined(separator: "\n") + "\n"
        let url = try makeFile(text)

        var chunkSizes: [Int] = []
        _ = try JSONLScanner.streamCompleteLines(at: url, linesPerChunk: 3) {
            chunkSizes.append($0.count)
        }
        XCTAssertEqual(chunkSizes, [3, 3, 1], "no chunk may exceed linesPerChunk")
    }

    func testResumeFingerprintCoversOnlyThePrefixUpToTheLimit() throws {
        let head = entry("one") + "\n"
        let limit = Int64(head.utf8.count)
        let original = try makeFile(head + entry("two") + "\n")
        let appended = try makeFile(head + entry("SOMETHING ENTIRELY DIFFERENT") + "\n")
        let rewritten = try makeFile(entry("ONE") + "\n" + entry("two") + "\n")

        XCTAssertEqual(
            try JSONLScanner.resumeFingerprint(at: original, upTo: limit),
            try JSONLScanner.resumeFingerprint(at: appended, upTo: limit),
            "bytes past the limit must not affect the fingerprint"
        )
        XCTAssertNotEqual(
            try JSONLScanner.resumeFingerprint(at: original, upTo: limit),
            try JSONLScanner.resumeFingerprint(at: rewritten, upTo: limit),
            "a rewritten head must invalidate the fingerprint"
        )
    }

    func testResumeFingerprintCatchesARewriteThatPreservesTheHead() throws {
        // The case a head-only hash cannot see: the file still starts with the
        // same bytes, but the content the cursor sits on top of has changed.
        // Resuming there would skip every line the rewrite put in its place.
        // The windows are `byteCount` wide, so a small `byteCount` makes a small
        // fixture exercise the same geometry a 4 KB window does on a real file.
        let head = (0..<8).map { entry("head\($0)") }.joined(separator: "\n") + "\n"
        let original = try makeFile(head + entry("middle") + "\n" + entry("tail") + "\n")
        let rewritten = try makeFile(head + entry("MIDDLE") + "\n" + entry("tail") + "\n")
        let limit = Int64((head + entry("middle") + "\n").utf8.count)

        XCTAssertNotEqual(
            try JSONLScanner.resumeFingerprint(at: original, upTo: limit, byteCount: 64),
            try JSONLScanner.resumeFingerprint(at: rewritten, upTo: limit, byteCount: 64),
            "a rewrite inside the consumed region must invalidate the cursor"
        )
    }

    func testResumeFingerprintIsStableAsAShortFileGrows() throws {
        // The cursor stores a hash of the prefix it already consumed. A young
        // transcript is far shorter than the 4 KB default, so hashing a fixed 4 KB
        // would fold its tail in and every append would invalidate the cursor the
        // previous pass just wrote.
        let firstPass = entry("one") + "\n"
        let url = try makeFile(firstPass)
        let before = try JSONLScanner.resumeFingerprint(at: url, upTo: Int64(firstPass.utf8.count))

        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((entry("two") + "\n").utf8))
        try handle.close()

        XCTAssertEqual(
            try JSONLScanner.resumeFingerprint(at: url, upTo: Int64(firstPass.utf8.count)), before,
            "appending must not invalidate a cursor over a sub-4KB file"
        )
    }

    func testResumeFingerprintOfAZeroLengthPrefixIsConstant() throws {
        let url = try makeFile(entry("one") + "\n")
        let other = try makeFile(entry("two") + "\n")
        XCTAssertEqual(
            try JSONLScanner.resumeFingerprint(at: url, upTo: 0),
            try JSONLScanner.resumeFingerprint(at: other, upTo: 0),
            "a cursor at offset 0 covers no bytes, so its fingerprint carries no identity"
        )
    }

    func testParseRawLinePromotesMetadataAndKeepsTheLineVerbatim() throws {
        let line = #"{"type":"user","sessionId":"s9","uuid":"u1","parentUuid":"p0","#
            + #""timestamp":"2026-04-14T10:00:00Z","isSidechain":true,"message":{"role":"user"}}"#
        let raw = JSONLScanner.parseRawLine(line, lineNo: 7, fileStem: "stem")
        XCTAssertEqual(raw.lineNo, 7)
        XCTAssertEqual(raw.sessionId, "s9")
        XCTAssertEqual(raw.entryUuid, "u1")
        XCTAssertEqual(raw.parentUuid, "p0")
        XCTAssertEqual(raw.entryType, "user")
        XCTAssertEqual(raw.role, "user")
        XCTAssertEqual(raw.timestamp, "2026-04-14T10:00:00Z")
        XCTAssertTrue(raw.isSidechain)
        XCTAssertEqual(raw.rawJSON, line)
    }

    func testParseRawLineFallsBackToTheFileStemAndSurvivesGarbage() {
        let raw = JSONLScanner.parseRawLine("not json at all", lineNo: 1, fileStem: "stem")
        XCTAssertEqual(raw.sessionId, "stem", "an unparseable line still belongs to its file")
        XCTAssertEqual(raw.entryType, "")
        XCTAssertEqual(raw.rawJSON, "not json at all")
    }

    // MARK: - Subagent detection (three markers)

    func testDetectsSubagentViaIsSidechain() throws {
        let line = #"{"type":"user","sessionId":"s1","timestamp":"t","cwd":"/w","isSidechain":true}"#
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertTrue(turn.isSubagent, "root isSidechain flag marks the turn as subagent")
        XCTAssertEqual(turn.agentId, "", "isSidechain alone carries no agent id")
    }

    func testDetectsSubagentViaTopLevelAgentId() throws {
        let line = #"{"type":"user","sessionId":"s1","timestamp":"t","cwd":"/w","agentId":"agent-7"}"#
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertTrue(turn.isSubagent, "record-level agentId marks the turn as subagent")
        XCTAssertEqual(turn.agentId, "agent-7")
    }

    func testDetectsSubagentViaDataWrapperAgentId() throws {
        let line = #"{"type":"user","sessionId":"s1","timestamp":"t","cwd":"/w","data":{"agentId":"agent-8"}}"#
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertTrue(turn.isSubagent, "agentId on the data wrapper marks the turn as subagent")
        XCTAssertEqual(turn.agentId, "agent-8")
    }

    func testDetectsSubagentViaFilePathMarker() throws {
        // Marker 3 is a property of the FILE, threaded into parse().
        let line = #"{"type":"user","sessionId":"s1","timestamp":"t","cwd":"/w"}"#
        let turn = try XCTUnwrap(JSONLScanner.parse(line, isSubagentFile: true))
        XCTAssertTrue(turn.isSubagent)
        XCTAssertEqual(turn.agentId, "", "path marker carries no agent id")

        XCTAssertTrue(JSONLScanner.isSubagentPath("/x/project/subagents/agent-1.jsonl"))
        XCTAssertTrue(JSONLScanner.isSubagentPath("/x/Subagents/a.jsonl"),
                      "directory match is case-insensitive (mirrors claude-usage)")
        XCTAssertFalse(JSONLScanner.isSubagentPath("/x/project/sessions/a.jsonl"))
        XCTAssertFalse(JSONLScanner.isSubagentPath("/x/subagents-old/a.jsonl"),
                       "marker requires the exact directory component")
    }

    func testMainSessionTurnIsNotSubagent() throws {
        let line = #"{"type":"user","sessionId":"s1","timestamp":"t","cwd":"/w","isSidechain":false}"#
        let turn = try XCTUnwrap(JSONLScanner.parse(line))
        XCTAssertFalse(turn.isSubagent)
        XCTAssertEqual(turn.agentId, "")
    }

    func testParseFileMarksTurnsFromSubagentsDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("subagents-\(UUID().uuidString)/subagents")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        let file = root.appendingPathComponent("agent-1.jsonl")
        try #"{"type":"user","sessionId":"s1","timestamp":"t","cwd":"/w"}"#
            .write(to: file, atomically: true, encoding: .utf8)

        let turns = try JSONLScanner.parseFile(at: file)
        XCTAssertEqual(turns.count, 1)
        XCTAssertTrue(turns[0].isSubagent, "a /subagents/ path marks every turn in the file")
    }

    // MARK: - Title records

    func testParsesCustomTitle() throws {
        let line = #"{"type":"custom-title","sessionId":"s1","customTitle":"My Session"}"#
        let title = try XCTUnwrap(JSONLScanner.parseTitle(line))
        XCTAssertEqual(title.sessionId, "s1")
        XCTAssertEqual(title.source, .custom)
        XCTAssertEqual(title.title, "My Session")
    }

    func testParsesAITitle() throws {
        let line = #"{"type":"ai-title","sessionId":"s1","aiTitle":"Fixing the importer"}"#
        let title = try XCTUnwrap(JSONLScanner.parseTitle(line))
        XCTAssertEqual(title.source, .aiGenerated)
        XCTAssertEqual(title.title, "Fixing the importer")
    }

    func testTitleRejectsWrongTypeOrMissingFields() {
        XCTAssertNil(JSONLScanner.parseTitle(#"{"type":"user","sessionId":"s1"}"#))
        XCTAssertNil(JSONLScanner.parseTitle(#"{"type":"custom-title","customTitle":"x"}"#),
                     "missing sessionId")
        XCTAssertNil(JSONLScanner.parseTitle(#"{"type":"custom-title","sessionId":"s1"}"#),
                     "missing customTitle")
        XCTAssertNil(JSONLScanner.parseTitle(#"{"type":"ai-title","sessionId":"s1","customTitle":"x"}"#),
                     "ai-title reads aiTitle, not customTitle")
    }

    func testTitleRecordsAreNotTurns() {
        XCTAssertNil(JSONLScanner.parse(#"{"type":"custom-title","sessionId":"s1","customTitle":"x"}"#))
    }

    // MARK: - Agent dispatch records

    func testParsesAgentDispatchFromToolUseResult() throws {
        let line = """
        {"type":"user","sessionId":"parent-1","timestamp":"2026-04-14T10:05:00Z","cwd":"/w",\
        "toolUseResult":{"agentId":"agent-9","agentType":"Explore","status":"completed",\
        "totalTokens":12345,"totalDurationMs":9876,"totalToolUseCount":7}}
        """
        let dispatch = try XCTUnwrap(JSONLScanner.parseDispatch(line))
        XCTAssertEqual(dispatch.agentId, "agent-9")
        XCTAssertEqual(dispatch.agentType, "Explore")
        XCTAssertEqual(dispatch.sessionId, "parent-1")
        XCTAssertEqual(dispatch.timestamp, "2026-04-14T10:05:00Z")
        XCTAssertEqual(dispatch.status, "completed")
        XCTAssertEqual(dispatch.totalTokens, 12345)
        XCTAssertEqual(dispatch.totalDurationMs, 9876)
        XCTAssertEqual(dispatch.totalToolUseCount, 7)
    }

    func testDispatchRequiresUserTypeAndBothIds() {
        // Non-user record → nil even with a toolUseResult.
        XCTAssertNil(JSONLScanner.parseDispatch(
            #"{"type":"assistant","sessionId":"s","toolUseResult":{"agentId":"a","agentType":"t"}}"#
        ))
        // Missing agentType → nil (mirrors claude-usage's guard).
        XCTAssertNil(JSONLScanner.parseDispatch(
            #"{"type":"user","sessionId":"s","toolUseResult":{"agentId":"a"}}"#
        ))
        // Missing agentId → nil.
        XCTAssertNil(JSONLScanner.parseDispatch(
            #"{"type":"user","sessionId":"s","toolUseResult":{"agentType":"t"}}"#
        ))
        // Non-dict toolUseResult (plain tool results are often strings) → nil.
        XCTAssertNil(JSONLScanner.parseDispatch(
            #"{"type":"user","sessionId":"s","toolUseResult":"ok"}"#
        ))
    }

    func testParseExtrasHarvestsTitlesAndDispatchesAlongsideTurns() throws {
        // The importer walks a file once, feeding each line to `parse` and
        // `parseExtras`; this asserts the same split over the same lines.
        let lines = [
            #"{"type":"user","sessionId":"s","timestamp":"2026-04-14T10:00:00Z","cwd":"/w"}"#,
            #"{"type":"ai-title","sessionId":"s","aiTitle":"Title A"}"#,
            """
            {"type":"user","sessionId":"s","timestamp":"2026-04-14T10:01:00Z","cwd":"/w",\
            "toolUseResult":{"agentId":"a1","agentType":"Explore","status":"completed",\
            "totalTokens":10,"totalDurationMs":20,"totalToolUseCount":3}}
            """
        ]

        var turns: [JSONLScanner.ParsedTurn] = []
        var titles: [JSONLScanner.ParsedTitle] = []
        var dispatches: [JSONLScanner.AgentDispatch] = []
        for line in lines {
            if let turn = JSONLScanner.parse(line) { turns.append(turn) }
            let extras = JSONLScanner.parseExtras(line)
            if let title = extras.title { titles.append(title) }
            if let dispatch = extras.dispatch { dispatches.append(dispatch) }
        }

        XCTAssertEqual(turns.count, 2, "the dispatch-carrying user record is also a turn")
        XCTAssertEqual(titles.count, 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertEqual(dispatches[0].agentId, "a1")
    }

}
