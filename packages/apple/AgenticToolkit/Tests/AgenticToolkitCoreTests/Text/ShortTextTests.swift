import Foundation
import Testing
@testable import AgenticToolkitCore

struct ShortTextTests {

    @Test func underTheLimitIsUnchanged() {
        #expect("short".shortened(to: 10) == "short")
    }

    @Test func exactlyTheLimitIsUnchanged() {
        #expect("0123456789".shortened(to: 10) == "0123456789")
    }

    @Test func overTheLimitIsCutEndingInAnEllipsis() {
        let cut = "0123456789ABC".shortened(to: 10)
        #expect(cut == "0123456…")
        #expect(cut.count == 8)  // prefix(limit - 3) plus the ellipsis: two under the limit
    }
}
