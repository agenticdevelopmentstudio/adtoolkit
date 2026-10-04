import XCTest
@testable import AgenticToolkitCore

final class BillingProjectCutoffTests: XCTestCase {
    func testNilOverrideUsesTheDefault() {
        let project = BillingProjectDTO(id: "p", name: "P")
        XCTAssertEqual(BillingStore.cutoffSeconds(for: project, default: 900), 900)
        XCTAssertEqual(BillingStore.cutoffSeconds(for: nil, default: 900), 900)
    }

    func testOverrideWins() {
        let project = BillingProjectDTO(id: "p", name: "P", idleCutoffMinutes: 30)
        XCTAssertEqual(BillingStore.cutoffSeconds(for: project, default: 900), 1800)
    }

    func testOutOfRangeStoredOverrideIsClamped() {
        let project = BillingProjectDTO(id: "p", name: "P", idleCutoffMinutes: 0)
        XCTAssertEqual(BillingStore.cutoffSeconds(for: project, default: 900),
                       BillingLimits.idleCutoffMinutes.lowerBound * 60)
    }

    func testReplacingCanSetAndClearTheOverride() {
        let project = BillingProjectDTO(id: "p", name: "P")
        XCTAssertEqual(project.replacing(idleCutoffMinutes: .some(45)).idleCutoffMinutes, 45)
        let set = project.replacing(idleCutoffMinutes: .some(45))
        XCTAssertNil(set.replacing(idleCutoffMinutes: .some(nil)).idleCutoffMinutes)
        XCTAssertEqual(project.replacing(idleCutoffMinutes: .some(45)).replacing(name: "Q").idleCutoffMinutes, 45,
                       "an unrelated edit keeps the override")
    }

    func testDecodingAnOlderPayloadWithoutTheFieldIsNil() throws {
        let json = #"""
        {"id":"p","name":"P","notes":"","rounding_minutes":15,"rounding_mode":"up",
         "billing_enabled":true,"archived":false,"created_at":"","updated_at":""}
        """#
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        XCTAssertNil(try decoder.decode(BillingProjectDTO.self, from: Data(json.utf8)).idleCutoffMinutes)
    }
}
