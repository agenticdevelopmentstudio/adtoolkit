import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// The pure row → cell mapping used by the AI Oversight table.
final class OversightFindingsListSourceTests: XCTestCase {

    private func makeFinding(
        sessionId: String = "abcdefgh-1234-5678",
        observer: String = "context",
        kind: String = "compact",
        severity: Int = 88,
        status: String = "pending",
        source: String = "rule",
        reason: String = "Context 88% used"
    ) -> OversightFindingDTO {
        OversightFindingDTO(
            id: 1, sessionId: sessionId, observer: observer, kind: kind, severity: severity,
            status: status, source: source, model: "", reason: reason, detail: "",
            createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:00:00Z"
        )
    }

    func testCellsMapsShortSessionAndKeepsFields() {
        let cells = OversightFindingsListSource.cells(for: makeFinding())
        XCTAssertEqual(cells.session, "abcdefgh")
        XCTAssertEqual(cells.observer, "context")
        XCTAssertEqual(cells.kind, "compact")
        XCTAssertEqual(cells.severity, "88")
        XCTAssertEqual(cells.status, "pending")
        XCTAssertEqual(cells.reason, "Context 88% used")
    }

    func testCellsUsesDashForEmptyFields() {
        let cells = OversightFindingsListSource.cells(
            for: makeFinding(sessionId: "", observer: "", kind: "", severity: 0, status: "", reason: "")
        )
        XCTAssertEqual(cells.session, "—")
        XCTAssertEqual(cells.observer, "—")
        XCTAssertEqual(cells.kind, "—")
        XCTAssertEqual(cells.severity, "0", "severity is numeric, always rendered")
        XCTAssertEqual(cells.status, "—")
        XCTAssertEqual(cells.reason, "—")
    }
}
