import XCTest
@testable import AgenticToolkitCore

final class BillingRollupUnionTests: XCTestCase {
    private func seg(_ start: String, _ seconds: Int, session: String = "s") -> BillingSegmentDTO {
        BillingSegmentDTO(id: UUID().uuidString, sessionId: session, origin: "auto",
                          startedAt: start, seconds: seconds)
    }

    func testDisjointSegmentsSumAsBefore() {
        let raw = BillingRollup.rawSeconds(of: [seg("2026-10-01T09:00:00Z", 300),
                                                seg("2026-10-01T10:00:00Z", 300)])
        XCTAssertEqual(raw, 600)
    }

    func testTwoParallelSessionsBillOnce() {
        let raw = BillingRollup.rawSeconds(of: [seg("2026-10-01T09:00:00Z", 600, session: "a"),
                                                seg("2026-10-01T09:05:00Z", 600, session: "b")])
        XCTAssertEqual(raw, 900, "09:00–09:15 is fifteen minutes, not twenty")
    }

    func testThreeOverlappingSourcesCountOnce() {
        let raw = BillingRollup.rawSeconds(of: [
            seg("2026-10-01T12:15:00Z", 300, session: "a"),
            seg("2026-10-01T12:15:00Z", 300, session: "b"),
            seg("2026-10-01T12:15:00Z", 300, session: "app:x")
        ])
        XCTAssertEqual(raw, 300)
    }

    func testUnparseableStartStillCounts() {
        let raw = BillingRollup.rawSeconds(of: [seg("garbage", 120), seg("2026-10-01T09:00:00Z", 60)])
        XCTAssertEqual(raw, 180)
    }

    func testNegativeSecondsCountAsZero() {
        XCTAssertEqual(BillingRollup.rawSeconds(of: [seg("2026-10-01T09:00:00Z", -50)]), 0)
    }

    func testSupplementCountsOnlyTimeTheOwnerDoesNotCover() {
        let owner = [seg("2026-10-01T09:00:00Z", 600)]           // 09:00–09:10
        let supplement = [seg("2026-10-01T09:05:00Z", 600)]      // 09:05–09:15
        XCTAssertEqual(BillingRollup.rawSeconds(of: supplement, excluding: owner), 300)
    }

    func testSupplementInsideOwnerIsZero() {
        let owner = [seg("2026-10-01T09:00:00Z", 3600)]
        XCTAssertEqual(BillingRollup.rawSeconds(of: [seg("2026-10-01T09:10:00Z", 60)], excluding: owner), 0)
    }
}
