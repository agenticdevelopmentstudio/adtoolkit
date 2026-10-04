import XCTest
@testable import AgenticToolkitActivity

final class UsageTypesTests: XCTestCase {
    func test_durationMs_computes_from_start_and_end() {
        let start = Date(timeIntervalSince1970: 100)
        var seg = FocusSegment(id: UUID(), startedAt: start, endedAt: nil,
            focus: WindowFocus(app: AppInfo(bundleID: "a", name: "A", pid: 1),
                               windowID: 7, title: "t", documentPath: nil),
            endReason: nil)
        XCTAssertNil(seg.durationMs)
        seg.endedAt = start.addingTimeInterval(2)  // 2s
        XCTAssertEqual(seg.durationMs, 2000)
    }
}
