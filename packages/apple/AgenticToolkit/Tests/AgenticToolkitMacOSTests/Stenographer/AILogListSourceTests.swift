import XCTest
@testable import AgenticToolkitMacOS
import AgenticToolkitCore

/// The AI Log window's pure row → cell mapping (no daemon involved).
/// Fixtures come from the shared `makeAIInteractionDTO` builder.
final class AILogListSourceTests: XCTestCase {

    func testCellsForCLIRow() {
        let cells = AILogListSource.cells(for: makeAIInteractionDTO())
        XCTAssertEqual(cells.time, "2026-07-10 12:00:00")
        XCTAssertEqual(cells.feature, "Summary", "feature label is friendly + capitalized")
        XCTAssertEqual(cells.session, "abcdef12", "no name → session id shortens to 8 chars")
        XCTAssertEqual(cells.provider, "claude-cli · haiku")
        XCTAssertEqual(cells.duration, "42 ms")
        XCTAssertEqual(cells.result, "reply", "success shows the reply text")
    }

    func testCellsForPluginRow() {
        let cells = AILogListSource.cells(
            for: makeAIInteractionDTO(providerKind: "plugin", configName: "Claude (Local)", model: "qwen2.5")
        )
        XCTAssertEqual(cells.provider, "Claude (Local) · qwen2.5")
    }

    func testProviderTextOmitsEmptyParts() {
        XCTAssertEqual(
            AILogListSource.providerText(for: makeAIInteractionDTO(providerKind: "plugin", configName: "", model: "m")),
            "m"
        )
        XCTAssertEqual(
            AILogListSource.providerText(for: makeAIInteractionDTO(providerKind: "plugin", configName: "", model: "")),
            "—"
        )
    }

    // MARK: - Session name resolution

    func testResolvedNameUsedWhenProvided() {
        let cells = AILogListSource.cells(for: makeAIInteractionDTO(), sessionName: "add-widget")
        XCTAssertEqual(cells.session, "add-widget", "a resolved name wins over the GUID")
    }

    func testEmptyNameFallsBackToShortId() {
        XCTAssertEqual(AILogListSource.cells(for: makeAIInteractionDTO(), sessionName: "").session, "abcdef12")
    }

    func testEmptySessionShowsDash() {
        XCTAssertEqual(AILogListSource.cells(for: makeAIInteractionDTO(sessionId: "")).session, "—")
    }

    // MARK: - Feature labels

    func testFeatureLabels() {
        XCTAssertEqual(AILogListSource.featureLabel("summarize"), "Summary")
        XCTAssertEqual(AILogListSource.featureLabel("oversight"), "Oversight")
        XCTAssertEqual(AILogListSource.featureLabel(""), "—")
        XCTAssertEqual(AILogListSource.featureLabel("custom"), "Custom")
    }

    // MARK: - Result column ("what it did")

    func testResultShowsReplyOnSuccess() {
        XCTAssertEqual(AILogListSource.resultText(for: makeAIInteractionDTO(response: "all good")), "all good")
    }

    func testResultFlattensMultilineText() {
        XCTAssertEqual(
            AILogListSource.resultText(for: makeAIInteractionDTO(response: "line one\nline two\tend")),
            "line one line two end",
            "newlines and tabs collapse to single spaces for the one-line cell"
        )
    }

    func testResultShowsErrorWithGlyphOnFailure() {
        XCTAssertEqual(
            AILogListSource.resultText(for: makeAIInteractionDTO(response: "", outcome: "error", error: "boom")),
            "⚠ boom"
        )
    }

    func testResultDashWhenNothingToShow() {
        XCTAssertEqual(AILogListSource.resultText(for: makeAIInteractionDTO(response: "")), "—")
        XCTAssertEqual(AILogListSource.resultText(for: makeAIInteractionDTO(outcome: "error", error: "")), "⚠ error")
    }

    func testDurationFormatting() {
        XCTAssertEqual(AILogListSource.durationText(milliseconds: 999), "999 ms")
        XCTAssertEqual(AILogListSource.durationText(milliseconds: 1500), "1.5 s")
    }
}
