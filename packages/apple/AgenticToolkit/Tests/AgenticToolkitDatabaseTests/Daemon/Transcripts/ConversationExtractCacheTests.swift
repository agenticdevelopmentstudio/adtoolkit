import XCTest
@testable import AgenticToolkitDatabase

final class ConversationExtractCacheTests: XCTestCase {

    private func userLine(_ text: String) -> String {
        #"{"type":"user","message":{"role":"user","content":"\#(text)"}}"#
    }

    func testExtractCacheReturnsWhatTheExtractorReturns() {
        let cache = ConversationExtractCache()
        let raw = userLine("hello there")

        XCTAssertEqual(cache.lines(lineId: 1, rawJSON: raw), ConversationExtractor.extract(rawJSON: raw))
        XCTAssertEqual(cache.lines(lineId: 1, rawJSON: raw).first?.text, "hello there")
        XCTAssertEqual(cache.lines(lineId: 2, rawJSON: "{not json"), [])
    }

    func testExtractCacheNeverServesAReusedIdAnotherLinesText() {
        let cache = ConversationExtractCache()
        _ = cache.lines(lineId: 7, rawJSON: userLine("first"))

        let reused = cache.lines(lineId: 7, rawJSON: userLine("a different line"))

        XCTAssertEqual(reused.first?.text, "a different line")
    }

    func testExtractCacheStaysBoundedAndKeepsWhatIsStillRead() {
        let cache = ConversationExtractCache(capacity: 4)
        let hot = userLine("hot")
        _ = cache.lines(lineId: 0, rawJSON: hot)
        for id in 1...20 {
            _ = cache.lines(lineId: id, rawJSON: userLine("line \(id)"))
            _ = cache.lines(lineId: 0, rawJSON: hot)   // a poll keeps reading it
        }

        XCTAssertLessThanOrEqual(cache.count, 4, "never more than `capacity`")
        XCTAssertEqual(cache.lines(lineId: 0, rawJSON: hot).first?.text, "hot")
    }
}
