import XCTest
@testable import AgenticToolkitCore

final class BillingRollupUnionTests: XCTestCase {
    private func seg(_ start: String, _ seconds: Int, session: String = "s") -> BillingSegmentDTO {
        BillingSegmentDTO(id: UUID().uuidString, sessionId: session, origin: "auto",
                          startedAt: start, seconds: seconds)
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
