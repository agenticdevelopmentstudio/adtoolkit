import XCTest
@testable import AgenticToolkitMacOS
import AgenticToolkitCore

/// Guard outcomes in the AI Log result column, on shared `makeAIInteractionDTO`
/// fixtures.
final class AILogGuardOutcomeTests: XCTestCase {

    func testGuardBlockedRowShowsReasonWithWarningGlyph() {
        let text = AILogListSource.resultText(for: makeAIInteractionDTO(
            response: "",
            outcome: "guard_blocked",
            error: "qwen3-coder-next:latest needs ~61.2 GB est. (96% of RAM); block threshold is 50% of 64.0 GB"))
        XCTAssertTrue(text.hasPrefix("⚠ "))
        XCTAssertTrue(text.contains("block threshold"))
    }

    func testGuardDeferredRowShowsReason() {
        let text = AILogListSource.resultText(for: makeAIInteractionDTO(
            response: "",
            outcome: "guard_deferred",
            error: "memory pressure is warning; deferring local inference"))
        XCTAssertTrue(text.hasPrefix("⚠ "))
        XCTAssertTrue(text.contains("memory pressure"))
    }

    func testOkRowStillShowsResponse() {
        let text = AILogListSource.resultText(for: makeAIInteractionDTO(
            response: "Fixing the sessions window"))
        XCTAssertEqual(text, "Fixing the sessions window")
    }
}
