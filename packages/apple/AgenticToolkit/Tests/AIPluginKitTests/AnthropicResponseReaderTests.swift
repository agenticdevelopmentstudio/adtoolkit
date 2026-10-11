import XCTest
@testable import AIPluginKit

final class AnthropicResponseReaderTests: XCTestCase {

    private let startUsage = """
    {"input_tokens":25,"cache_read_input_tokens":10,"cache_creation_input_tokens":5,"output_tokens":1}
    """

    private var stream: String {
        """
    event: message_start
    data: {"type":"message_start","message":{"id":"msg_1","model":"claude-x","usage":\(startUsage)}}

    event: content_block_delta
    data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"hi"}}

    event: message_delta
    data: {"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":42}}

    event: message_stop
    data: {"type":"message_stop"}


    """
    }

    func testSSESplitAtEveryByte() {
        let reader = AnthropicResponseReader(streaming: true)
        for byte in Data(stream.utf8) { reader.consume(Data([byte])) }
        reader.finish()
        XCTAssertEqual(reader.model, "claude-x")
        XCTAssertEqual(reader.inputTokens, 25)
        XCTAssertEqual(reader.outputTokens, 42)
        XCTAssertEqual(reader.cacheReadTokens, 10)
        XCTAssertEqual(reader.cacheCreationTokens, 5)
        XCTAssertEqual(reader.stopReason, "end_turn")
    }

    func testSSEWholeAndCRLF() {
        let reader = AnthropicResponseReader(streaming: true)
        reader.consume(Data(stream.replacingOccurrences(of: "\n", with: "\r\n").utf8))
        reader.finish()
        XCTAssertEqual(reader.outputTokens, 42)
        XCTAssertEqual(reader.model, "claude-x")
    }

    func testJSONMessage() {
        let body = """
        {"id":"msg_1","model":"claude-y","stop_reason":"tool_use",
        "usage":{"input_tokens":3,"output_tokens":9,"cache_read_input_tokens":2,"cache_creation_input_tokens":1}}
        """
        let reader = AnthropicResponseReader(streaming: false)
        let data = Data(body.utf8)
        reader.consume(data.prefix(20))
        reader.consume(data.dropFirst(20))
        reader.finish()
        XCTAssertEqual(reader.model, "claude-y")
        XCTAssertEqual(reader.stopReason, "tool_use")
        XCTAssertEqual(reader.inputTokens, 3)
        XCTAssertEqual(reader.outputTokens, 9)
        XCTAssertEqual(reader.cacheReadTokens, 2)
        XCTAssertEqual(reader.cacheCreationTokens, 1)
    }

    func testGarbageStaysNil() {
        for streaming in [true, false] {
            let reader = AnthropicResponseReader(streaming: streaming)
            reader.consume(Data([0xFF, 0xFE, 0x00, 0x0A, 0x7B]))
            reader.consume(Data("data: {broken\n\ndata: [1,2]\n".utf8))
            reader.finish()
            XCTAssertNil(reader.model)
            XCTAssertNil(reader.inputTokens)
            XCTAssertNil(reader.outputTokens)
            XCTAssertNil(reader.stopReason)
        }
    }

    func testJSONOver4MiBStaysNil() {
        let reader = AnthropicResponseReader(streaming: false)
        let head = Data("{\"model\":\"m\",\"pad\":\"".utf8)
        reader.consume(head)
        reader.consume(Data(repeating: 0x61, count: 4 * 1024 * 1024))
        reader.consume(Data("\"}".utf8))
        reader.finish()
        XCTAssertNil(reader.model)
        XCTAssertNil(reader.outputTokens)
    }
}
