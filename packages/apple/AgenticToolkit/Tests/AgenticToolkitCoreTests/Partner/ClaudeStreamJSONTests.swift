import Foundation
import Testing
@testable import AgenticToolkitCore

@Suite("Claude stream-json") struct ClaudeStreamJSONTests {
    @Test func decodesAssistantTextAndToolUse() throws {
        let line = #"{"type":"assistant","session_id":"s","message":{"role":"assistant","content":["# +
            #"{"type":"text","text":"hi"},"# +
            #"{"type":"tool_use","id":"t1","name":"mcp__adkitchen__partner_notify","input":{}}]}}"#
        let msg = try ClaudeStreamMessage.decode(Data(line.utf8))
        let tool = msg.blocks[1].name
        #expect(msg.kind == .assistant && msg.blocks.count == 2 && tool == "mcp__adkitchen__partner_notify")
    }
    @Test func decodesResultError() throws {
        let line = #"{"type":"result","subtype":"error_max_turns","is_error":true,"result":"x","session_id":"s"}"#
        let msg = try ClaudeStreamMessage.decode(Data(line.utf8))
        #expect(msg.kind == .result && msg.isError && msg.subtype == "error_max_turns")
    }
    @Test func unknownTypeIsOther() throws {
        let msg = try ClaudeStreamMessage.decode(Data(#"{"type":"stream_event","event":{}}"#.utf8))
        #expect(msg.kind == .other("stream_event"))
    }
    @Test func nonJSONThrows() {
        #expect(throws: DecodingError.self) { try ClaudeStreamMessage.decode(Data("nope".utf8)) }
    }
    @Test func systemInitDecodes() throws {
        let msg = try ClaudeStreamMessage.decode(Data(#"{"type":"system","subtype":"init","session_id":"s"}"#.utf8))
        #expect(msg.kind == .systemInit && msg.sessionID == "s")
    }
    @Test func userMessageLineShape() throws {
        let data = ClaudeStreamInput.userMessage("hello")
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(obj?["type"] as? String == "user")
        #expect(ClaudeStreamInput.userMessage("x").last == 0x0A)
    }
}
