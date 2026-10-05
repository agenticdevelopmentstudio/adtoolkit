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

    // MARK: - BillingRange

    private func ranges(_ pairs: [(Int, Int)]) -> [BillingRange] {
        pairs.map { BillingRange(start: $0.0, end: $0.1) }
    }

    func testNormalizedSortsMergesTouchingAndDropsEmpty() {
        XCTAssertEqual(
            BillingRange.normalized(ranges([(50, 60), (0, 10), (10, 20), (30, 30), (15, 25), (40, 35)])),
            ranges([(0, 25), (50, 60)])
        )
    }

    func testUnionIsNormalized() {
        XCTAssertEqual(BillingRange.union(ranges([(0, 10)]), ranges([(5, 15), (20, 30)])), ranges([(0, 15), (20, 30)]))
    }

    func testSubtractCutsHolesAtEitherEdgeAndInside() {
        XCTAssertEqual(
            BillingRange.subtract(ranges([(0, 100)]), ranges([(-5, 10), (40, 50), (90, 120)])),
            ranges([(10, 40), (50, 90)])
        )
        XCTAssertEqual(BillingRange.subtract(ranges([(0, 10)]), ranges([(0, 10)])), [])
        XCTAssertEqual(BillingRange.subtract(ranges([(0, 10)]), []), ranges([(0, 10)]))
    }

    func testIntersectKeepsOnlyTheSharedSeconds() {
        XCTAssertEqual(
            BillingRange.intersect(ranges([(0, 30), (40, 60)]), ranges([(20, 50)])),
            ranges([(20, 30), (40, 50)])
        )
        XCTAssertEqual(BillingRange.intersect(ranges([(0, 10)]), ranges([(10, 20)])), [], "half-open")
    }

    func testMeasureCountsOverlapOnce() {
        XCTAssertEqual(BillingRange.measure(ranges([(0, 10), (5, 15), (20, 21)])), 16)
        XCTAssertEqual(BillingRange.measure([]), 0)
    }

    func testEncodeAndDecodeRoundTripNormalized() {
        let text = BillingRange.encode(ranges([(20, 30), (0, 10), (5, 12)]))
        XCTAssertEqual(text, "0-12;20-30")
        XCTAssertEqual(BillingRange.decode(text), ranges([(0, 12), (20, 30)]))
        XCTAssertEqual(BillingRange.encode([]), "")
        XCTAssertEqual(BillingRange.decode(""), [])
        XCTAssertEqual(BillingRange.decode("5-1;x-3;7-9"), ranges([(7, 9)]), "bad pairs are dropped")
    }

    func testIntervalsLeaveOutUnplaceableSegments() {
        let start = UTCTimestamp.epochSeconds("2026-10-01T09:00:00Z") ?? 0
        XCTAssertEqual(
            BillingRange.intervals(of: [seg("2026-10-01T09:00:00Z", 60), seg("garbage", 60),
                                        seg("2026-10-01T09:01:00Z", -5)]),
            ranges([(start, start + 60)])
        )
    }
}
