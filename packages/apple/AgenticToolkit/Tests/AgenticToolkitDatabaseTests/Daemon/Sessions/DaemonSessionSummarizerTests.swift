import XCTest
import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

final class DaemonSessionSummarizerTests: XCTestCase {

    private func marker(_ index: Int) -> String { "<<E\(String(format: "%04d", index))>>" }

    /// `fetchEvents` returns events newest-first (ORDER BY timestamp DESC). `buildPrompt`
    /// must summarize the NEWEST `maxEvents` events, emitted oldest -> newest to match
    /// its "Activity (most recent last)" header — not the oldest events via a naive
    /// `suffix` on the descending array.
    func testBuildPromptUsesNewestEventsInChronologicalOrder() throws {
        let cap = SummaryDefaults.activityLines
        let total = cap + 2 // two more than fit, so the OLDEST two must be dropped

        // chronological index: 0 = oldest, total-1 = newest. The array is newest-first.
        let events: [SessionEventDTO] = (0..<total).map { position in
            let chrono = total - 1 - position
            return SessionEventDTO(
                id: chrono, sessionId: "s", eventType: "PreToolUse",
                timestamp: "t", cwd: "/tmp", detail: marker(chrono)
            )
        }
        let session = SessionDTO(
            sessionId: "s", cwd: "/tmp/proj", model: "sonnet",
            startedAt: "t", lastActivityAt: "t", lastTool: "Read",
            status: "ended", gitBranch: "main", summary: "", pid: 0,
            termProgram: "Test", eventCount: total
        )

        let prompt = DaemonSessionSummarizer.buildPrompt(session: session, events: events)

        // The newest event is included and is the LAST activity line.
        let lastLine = prompt.split(separator: "\n").last.map(String.init) ?? ""
        XCTAssertTrue(lastLine.contains(marker(total - 1)), "newest event must be the last line")

        // The two OLDEST events were dropped (only the newest `cap` are kept).
        XCTAssertFalse(prompt.contains(marker(0)), "oldest event should be dropped")
        XCTAssertFalse(prompt.contains(marker(1)), "second-oldest event should be dropped")

        // Kept events read oldest -> newest: the oldest kept (index 2) precedes the newest.
        guard let oldestKept = prompt.range(of: marker(2)),
              let newest = prompt.range(of: marker(total - 1)) else {
            return XCTFail("expected both kept markers present")
        }
        XCTAssertTrue(oldestKept.lowerBound < newest.lowerBound, "events must be chronological")
    }

    /// The prompt's size is now user-tunable (Settings → AI Summaries): both the
    /// number of activity lines and each line's detail budget come from the caller.
    func testBuildPromptHonorsExplicitCaps() throws {
        let events: [SessionEventDTO] = (0..<10).map { position in
            SessionEventDTO(
                id: position, sessionId: "s", eventType: "PreToolUse",
                timestamp: "t", cwd: "/tmp", detail: "\(marker(9 - position))-abcdefghij"
            )
        }
        let session = SessionDTO(
            sessionId: "s", cwd: "/tmp/proj", model: "sonnet",
            startedAt: "t", lastActivityAt: "t", lastTool: "Read",
            status: "ended", gitBranch: "main", summary: "", pid: 0,
            termProgram: "Test", eventCount: 10
        )

        let prompt = DaemonSessionSummarizer.buildPrompt(
            session: session, events: events, maxEvents: 3, detailChars: marker(0).count
        )

        let activityLines = prompt.split(separator: "\n").filter { $0.hasPrefix("- [") }
        XCTAssertEqual(activityLines.count, 3, "only `maxEvents` events travel")
        // Each detail is cut to `detailChars` — exactly the marker's width here — so
        // the "-abcdefghij" tail must be gone while the marker itself survives.
        XCTAssertTrue(prompt.contains(marker(9)), "the newest event is kept")
        XCTAssertFalse(prompt.contains("abcdefghij"), "detail must be cut to `detailChars`")
    }

    /// The word cap is enforced on the reply, not just requested in the prompt —
    /// small local models routinely overrun it.
    func testCleanSummaryCapsAtTheConfiguredWordCount() throws {
        let raw = "fixing the sessions window and also the usage HUD and the status line"

        XCTAssertEqual(DaemonSessionSummarizer.cleanSummary(raw, maxWords: 4),
                       "fixing the sessions window")
        XCTAssertEqual(DaemonSessionSummarizer.cleanSummary(raw, maxWords: 20), raw,
                       "a reply already within the cap is untouched")
    }

    // MARK: - Tuning knobs

    func testSummaryPrefsFallBackToTheSharedDefaults() throws {
        let database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db

        XCTAssertEqual(SummaryPrefs.prompt(database), SummaryDefaults.prompt)
        XCTAssertEqual(SummaryPrefs.maxWords(database), SummaryDefaults.maxWords)
        XCTAssertEqual(SummaryPrefs.activityLines(database), SummaryDefaults.activityLines)
        XCTAssertEqual(SummaryPrefs.detailChars(database), SummaryDefaults.detailChars)
        XCTAssertEqual(SummaryPrefs.intervalMinutes(database), SummaryDefaults.intervalMinutes)
        XCTAssertEqual(SummaryPrefs.maxPerRun(database), SummaryDefaults.maxPerRun)
        XCTAssertEqual(SummaryPrefs.timeoutSeconds(database), TimeInterval(SummaryDefaults.timeoutSeconds))
        // Defaults must keep the request budget where it has always been, so a
        // never-configured daemon behaves exactly as before this became tunable.
        XCTAssertEqual(SummaryPrefs.maxTokens(database), 64)
    }

    func testSummaryPrefsClampOutOfRangeStoredValues() throws {
        let database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        try database.setSetting(SummarySettingsKeys.maxWords, "999")
        try database.setSetting(SummarySettingsKeys.activityLines, "0")
        try database.setSetting(SummarySettingsKeys.timeoutSeconds, "not a number")

        XCTAssertEqual(SummaryPrefs.maxWords(database), SummaryLimits.maxWords.upperBound)
        XCTAssertEqual(SummaryPrefs.activityLines(database), SummaryLimits.activityLines.lowerBound)
        XCTAssertEqual(SummaryPrefs.timeoutSeconds(database), TimeInterval(SummaryDefaults.timeoutSeconds),
                       "an unparseable value falls back rather than wedging the summarizer")
    }

    /// `{maxWords}` is substituted with the effective cap; a prompt the user stripped
    /// the placeholder out of is sent verbatim (the cap still trims the reply).
    func testResolvedPromptSubstitutesTheWordCap() throws {
        let database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        try database.setSetting(SummarySettingsKeys.prompt,
                                "Write \(SummaryDefaults.maxWordsPlaceholder) words, tops.")
        try database.setSetting(SummarySettingsKeys.maxWords, "12")

        XCTAssertEqual(SummaryPrefs.resolvedPrompt(database), "Write 12 words, tops.")

        try database.setSetting(SummarySettingsKeys.prompt, "Write a title.")
        XCTAssertEqual(SummaryPrefs.resolvedPrompt(database), "Write a title.")
    }

    /// A blank stored prompt means "never configured" (and is what the panel's Reset
    /// leaves behind if it ever writes ""), not "send the model no instructions".
    func testBlankStoredPromptFallsBackToTheShippedTemplate() throws {
        let database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        try database.setSetting(SummarySettingsKeys.prompt, "   ")

        XCTAssertEqual(SummaryPrefs.prompt(database), SummaryDefaults.prompt)
    }

    // MARK: - isEnabled default

    func testIsEnabledFallsBackToTheStatedDefault() throws {
        let database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        XCTAssertFalse(DaemonSessionSummarizer(defaultEnabled: false).isEnabled(database),
                       "no stored row: the daemon's own default decides")
        XCTAssertTrue(DaemonSessionSummarizer(defaultEnabled: true).isEnabled(database))
    }

    func testStoredEnabledRowBeatsTheDefault() throws {
        let database = try TestDaemonDatabase.makeSessionDatabase(path: ":memory:").db
        let off = DaemonSessionSummarizer(defaultEnabled: false)
        try database.setSetting("ai_summaries_enabled", "true")
        XCTAssertTrue(off.isEnabled(database))
        try database.setSetting("ai_summaries_enabled", "false")
        XCTAssertFalse(DaemonSessionSummarizer(defaultEnabled: true).isEnabled(database))
    }
}
