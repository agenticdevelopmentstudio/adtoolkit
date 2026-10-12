import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// The Scripts tab's pure row summaries (no daemon involved).
final class OversightScriptsSummaryTests: XCTestCase {

    func testConditionSummary() {
        XCTAssertEqual(
            OversightScriptsViewController.triggerSummary(
                .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "70000")
            ),
            "tokens_in_context ≥ 70000"
        )
    }

    func testGroupSummaryJoinsAndParenthesizesNesting() {
        let nested = ScriptPredicate.any([
            .condition(field: .contextUsedPct, operation: .greaterOrEqual, value: "95"),
            .all([
                .condition(field: .model, operation: .contains, value: "sonnet"),
                .condition(field: .lastEventType, operation: .equals, value: "Stop")
            ])
        ])
        XCTAssertEqual(
            OversightScriptsViewController.triggerSummary(nested),
            "context_used_pct ≥ 95 OR (model contains sonnet AND last_event_type = Stop)"
        )
    }

    func testActionSummaries() {
        let inject = OversightScript(
            id: "compact", name: "Compact", enabled: true, builtIn: true, version: 1,
            trigger: ScriptTrigger(
                predicate: .condition(field: .tokensInContext, operation: .greaterOrEqual, value: "70000")
            ),
            response: ScriptResponse(kind: "compact", reasonTemplate: "r", action: .injectText("/compact"))
        )
        XCTAssertEqual(OversightScriptsViewController.actionSummary(inject), "compact: type /compact")

        var recordOnly = inject
        recordOnly.response.action = .none
        recordOnly.response.kind = "attention"
        XCTAssertEqual(OversightScriptsViewController.actionSummary(recordOnly), "attention: record only")
    }
}
