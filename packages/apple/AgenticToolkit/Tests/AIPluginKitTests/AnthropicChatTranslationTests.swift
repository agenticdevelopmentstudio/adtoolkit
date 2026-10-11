import XCTest
@testable import AIPluginKit

final class AnthropicChatTranslationTests: XCTestCase {

    // MARK: helpers

    private func json(_ object: Any) -> Data {
        // swiftlint:disable:next force_try
        try! JSONSerialization.data(withJSONObject: object)
    }

    private func object(_ data: Data) -> NSDictionary {
        let parsed = try? JSONSerialization.jsonObject(with: data)
        return (parsed as? NSDictionary) ?? [:]
    }

    private func translate(_ body: [String: Any], key: String = "max_tokens") throws -> NSDictionary {
        object(try AnthropicChatTranslation.chatRequest(fromMessages: json(body), model: "gpt-x", maxTokensKey: key))
    }

    private func convert(_ reply: [String: Any]) throws -> Data {
        try AnthropicChatTranslation.anthropicMessage(fromChatCompletion: json(reply), fallbackModel: "fb")
    }

    private func error(_ status: Int, _ body: Data) -> Data {
        AnthropicChatTranslation.anthropicError(status: status, body: body)
    }

    private func single(_ message: [String: Any]) throws -> NSDictionary {
        try translate(["messages": [message]])
    }

    private func messages(_ result: NSDictionary) -> [NSDictionary] {
        (result["messages"] as? [NSDictionary]) ?? []
    }

    // MARK: request

    func testSystemStringAndUserString() throws {
        let result = try translate(["system": "be brief", "messages": [["role": "user", "content": "hi"]]])
        XCTAssertEqual(result["model"] as? String, "gpt-x")
        XCTAssertEqual(messages(result), [
            ["role": "system", "content": "be brief"],
            ["role": "user", "content": "hi"]
        ] as [NSDictionary])
    }

    func testSystemBlocksJoinedAndCacheControlDropped() throws {
        let cache = ["type": "ephemeral"]
        let result = try translate([
            "system": [
                ["type": "text", "text": "one", "cache_control": cache],
                ["type": "text", "text": "two", "cache_control": cache]
            ],
            "messages": [["role": "user", "content": [["type": "text", "text": "hi", "cache_control": cache]]]]
        ])
        XCTAssertEqual(messages(result)[0], ["role": "system", "content": "one\n\ntwo"] as NSDictionary)
        XCTAssertEqual(messages(result)[1], ["role": "user", "content": "hi"] as NSDictionary)
        XCTAssertFalse((String(bytes: json(result), encoding: .utf8) ?? "").contains("cache_control"))
    }

    func testAssistantTextAndTwoToolUses() throws {
        let result = try single([
            "role": "assistant",
            "content": [
                ["type": "text", "text": "working"],
                ["type": "tool_use", "id": "t1", "name": "a", "input": ["x": 1]],
                ["type": "tool_use", "id": "t2", "name": "b", "input": [String: Any]()]
            ]
        ])
        let assistant = messages(result)[0]
        XCTAssertEqual(assistant["content"] as? String, "working")
        let calls = try XCTUnwrap(assistant["tool_calls"] as? [NSDictionary])
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0]["id"] as? String, "t1")
        XCTAssertEqual(calls[0]["type"] as? String, "function")
        let function = try XCTUnwrap(calls[0]["function"] as? NSDictionary)
        XCTAssertEqual(function["name"] as? String, "a")
        let arguments = try XCTUnwrap(function["arguments"] as? String)
        XCTAssertEqual(object(Data(arguments.utf8)), ["x": 1] as NSDictionary)
        XCTAssertEqual((calls[1]["function"] as? NSDictionary)?["arguments"] as? String, "{}")
    }

    func testEmptyAssistantMessageHasEmptyContent() throws {
        let result = try single(["role": "assistant", "content": [["type": "thinking", "thinking": "x"]]])
        XCTAssertEqual(messages(result)[0], ["role": "assistant", "content": ""] as NSDictionary)
        let none = try single(["role": "assistant", "content": [Any]()])
        XCTAssertEqual(messages(none)[0]["content"] as? String, "")
    }

    func testToolResultWithBlockArrayAndImage() throws {
        let result = try single([
            "role": "user",
            "content": [["type": "tool_result", "tool_use_id": "t1", "content": [
                ["type": "text", "text": "one"],
                ["type": "image", "source": ["type": "base64", "media_type": "image/png", "data": "AA"]],
                ["type": "text", "text": "two"]
            ]]]
        ])
        XCTAssertEqual(messages(result), [
            ["role": "tool", "tool_call_id": "t1", "content": "one\n\n[image omitted]\n\ntwo"]
        ] as [NSDictionary])
    }

    func testAssistantWithoutTextHasNullContent() throws {
        let result = try single([
            "role": "assistant",
            "content": [["type": "tool_use", "id": "t1", "name": "a", "input": [String: Any]()]]
        ])
        XCTAssertTrue(messages(result)[0]["content"] is NSNull)
    }

    func testToolResultsBecomeToolMessagesBeforeUserText() throws {
        let result = try single([
            "role": "user",
            "content": [
                ["type": "text", "text": "after"],
                ["type": "tool_result", "tool_use_id": "t1", "content": "ok"],
                ["type": "tool_result", "tool_use_id": "t2", "is_error": true,
                 "content": [["type": "text", "text": "boom"]]]
            ]
        ])
        XCTAssertEqual(messages(result), [
            ["role": "tool", "tool_call_id": "t1", "content": "ok"],
            ["role": "tool", "tool_call_id": "t2", "content": "Error: boom"],
            ["role": "user", "content": "after"]
        ] as [NSDictionary])
    }

    func testThinkingBlocksDropped() throws {
        let result = try single([
            "role": "assistant",
            "content": [
                ["type": "thinking", "thinking": "hmm", "signature": "s"],
                ["type": "redacted_thinking", "data": "x"],
                ["type": "text", "text": "answer"]
            ]
        ])
        XCTAssertEqual(messages(result)[0], ["role": "assistant", "content": "answer"] as NSDictionary)
    }

    func testBase64AndURLImages() throws {
        let result = try single([
            "role": "user",
            "content": [
                ["type": "image", "source": ["type": "base64", "media_type": "image/png", "data": "AAAA"]],
                ["type": "image", "source": ["type": "url", "url": "https://x/y.png"]],
                ["type": "text", "text": "what?"]
            ]
        ])
        XCTAssertEqual(messages(result)[0], ["role": "user", "content": [
            ["type": "image_url", "image_url": ["url": "data:image/png;base64,AAAA"]],
            ["type": "image_url", "image_url": ["url": "https://x/y.png"]],
            ["type": "text", "text": "what?"]
        ]] as NSDictionary)
    }

    func testToolsAndToolChoice() throws {
        let body: [String: Any] = [
            "messages": [["role": "user", "content": "hi"]],
            "tools": [
                ["name": "a", "description": "d", "input_schema": ["type": "object"]],
                ["type": "web_search_20250305", "name": "web_search"]
            ],
            "tool_choice": ["type": "any"]
        ]
        let result = try translate(body)
        XCTAssertEqual(result["tools"] as? [NSDictionary], [
            ["type": "function", "function": ["name": "a", "description": "d", "parameters": ["type": "object"]]]
        ] as [NSDictionary])
        XCTAssertEqual(result["tool_choice"] as? String, "required")

        func choice(_ value: [String: Any]) throws -> Any? {
            var copy = body
            copy["tool_choice"] = value
            return try translate(copy)["tool_choice"]
        }
        XCTAssertEqual(try choice(["type": "auto"]) as? String, "auto")
        XCTAssertEqual(try choice(["type": "none"]) as? String, "none")
        XCTAssertEqual(try choice(["type": "tool", "name": "a"]) as? NSDictionary,
                       ["type": "function", "function": ["name": "a"]] as NSDictionary)
    }

    func testStreamAddsStreamOptions() throws {
        let result = try translate(["stream": true, "messages": [["role": "user", "content": "hi"]]])
        XCTAssertEqual(result["stream"] as? Bool, true)
        XCTAssertEqual(result["stream_options"] as? NSDictionary, ["include_usage": true] as NSDictionary)
        let plain = try translate(["messages": [["role": "user", "content": "hi"]]])
        XCTAssertNil(plain["stream"])
        XCTAssertNil(plain["stream_options"])
    }

    func testMaxTokensKeyAndPassThroughFields() throws {
        let result = try translate([
            "max_tokens": 100, "temperature": 0.5, "top_p": 0.9, "stop_sequences": ["END"],
            "metadata": ["user_id": "u"], "thinking": ["type": "enabled"], "top_k": 5,
            "messages": [["role": "user", "content": "hi"]]
        ], key: "max_completion_tokens")
        XCTAssertEqual(result["max_completion_tokens"] as? Int, 100)
        XCTAssertNil(result["max_tokens"])
        XCTAssertEqual(result["temperature"] as? Double, 0.5)
        XCTAssertEqual(result["top_p"] as? Double, 0.9)
        XCTAssertEqual(result["stop"] as? [String], ["END"])
        for dropped in ["metadata", "thinking", "top_k"] { XCTAssertNil(result[dropped]) }
    }

    func testStructuralFailuresThrow() {
        XCTAssertThrowsError(try AnthropicChatTranslation.chatRequest(fromMessages: Data("[1]".utf8), model: "m")) {
            XCTAssertEqual($0 as? AnthropicChatTranslation.TranslationError, .notAnObject)
        }
        XCTAssertThrowsError(try AnthropicChatTranslation.chatRequest(fromMessages: Data("nope".utf8), model: "m")) {
            XCTAssertEqual($0 as? AnthropicChatTranslation.TranslationError, .notAnObject)
        }
        let empty = json(["messages": [Any]()])
        XCTAssertThrowsError(try AnthropicChatTranslation.chatRequest(fromMessages: empty, model: "m")) {
            XCTAssertEqual($0 as? AnthropicChatTranslation.TranslationError, .noMessages)
        }
    }

    // MARK: streaming

    private func sse(_ objects: [[String: Any]], done: Bool = true) -> Data {
        var text = ""
        for item in objects { text += "data: " + (String(bytes: json(item), encoding: .utf8) ?? "") + "\n\n" }
        if done { text += "data: [DONE]\n\n" }
        return Data(text.utf8)
    }

    private func parseEvents(_ data: Data) -> [(name: String, payload: NSDictionary)] {
        (String(bytes: data, encoding: .utf8) ?? "").components(separatedBy: "\n\n").compactMap { block in
            let lines = block.components(separatedBy: "\n")
            guard lines.count == 2, lines[0].hasPrefix("event: "), lines[1].hasPrefix("data: ") else { return nil }
            return (String(lines[0].dropFirst(7)), object(Data(lines[1].dropFirst(6).utf8)))
        }
    }

    private func run(_ input: Data, byteAtATime: Bool, id: String = "msg_fixed") -> Data {
        let translator = ChatCompletionsStreamTranslator(model: "gpt-x", messageID: id)
        var out = Data()
        if byteAtATime {
            for byte in input { out.append(translator.consume(Data([byte]))) }
        } else {
            out.append(translator.consume(input))
        }
        out.append(translator.finish())
        return out
    }

    private var textStream: Data {
        sse([
            ["choices": [["index": 0, "delta": ["role": "assistant", "content": ""]]]],
            ["choices": [["index": 0, "delta": ["content": "Hel"]]]],
            ["choices": [["index": 0, "delta": ["content": "lo"]]]],
            ["choices": [["index": 0, "delta": [String: Any](), "finish_reason": "stop"]]],
            ["choices": [Any](), "usage": ["prompt_tokens": 7, "completion_tokens": 3]]
        ])
    }

    func testStreamedTextByteAtATimeEqualsWhole() {
        let input = textStream
        let whole = run(input, byteAtATime: false)
        let bytewise = parseEvents(run(input, byteAtATime: true))
        let events = parseEvents(whole)
        // JSON key order varies per serialization, so compare parsed events.
        XCTAssertEqual(bytewise.map(\.name), events.map(\.name))
        XCTAssertEqual(bytewise.map(\.payload), events.map(\.payload))
        XCTAssertEqual(events.map(\.name), [
            "message_start", "content_block_start", "content_block_delta", "content_block_delta",
            "content_block_stop", "message_delta", "message_stop"
        ])
        XCTAssertEqual(events[0].payload["type"] as? String, "message_start")
        let message = events[0].payload["message"] as? NSDictionary
        XCTAssertEqual(message?["id"] as? String, "msg_fixed")
        XCTAssertEqual(message?["model"] as? String, "gpt-x")
        let delta = events[5].payload
        XCTAssertEqual((delta["delta"] as? NSDictionary)?["stop_reason"] as? String, "end_turn")
        XCTAssertEqual((delta["usage"] as? NSDictionary)?["output_tokens"] as? Int, 3)
        XCTAssertEqual((delta["usage"] as? NSDictionary)?["input_tokens"] as? Int, 7)
    }

    func testCRLFLineEndings() {
        let text = String(bytes: textStream, encoding: .utf8) ?? ""
        let crlf = Data(text.replacingOccurrences(of: "\n", with: "\r\n").utf8)
        XCTAssertEqual(parseEvents(run(crlf, byteAtATime: false)).count, 7)
    }

    private func toolChunk(_ index: Int?, id: String? = nil, name: String? = nil, args: String? = nil)
        -> [String: Any] {
        var function: [String: Any] = [:]
        if let name { function["name"] = name }
        if let args { function["arguments"] = args }
        var entry: [String: Any] = ["function": function]
        if let index { entry["index"] = index }
        if let id { entry["id"] = id }
        return ["choices": [["index": 0, "delta": ["tool_calls": [entry]]]]]
    }

    /// Asserts at most one block is open at any time and every start follows
    /// the previous block's stop.
    private func assertSequential(_ events: [(name: String, payload: NSDictionary)],
                                  file: StaticString = #filePath, line: UInt = #line) {
        var open: Int?
        for event in events {
            let index = event.payload["index"] as? Int
            switch event.name {
            case "content_block_start":
                XCTAssertNil(open, "start while a block is open", file: file, line: line)
                open = index
            case "content_block_delta":
                XCTAssertEqual(open, index, "delta for a block that is not open", file: file, line: line)
            case "content_block_stop":
                XCTAssertEqual(open, index, file: file, line: line)
                open = nil
            default: break
            }
        }
        XCTAssertNil(open, file: file, line: line)
    }

    func testTextThenTwoToolCalls() {
        func call(_ index: Int, id: String? = nil, name: String? = nil, args: String? = nil) -> [String: Any] {
            toolChunk(index, id: id, name: name, args: args)
        }
        let stream = sse([
            ["choices": [["index": 0, "delta": ["content": "ok"]]]],
            call(0, id: "c0", name: "alpha", args: ""),
            call(0, args: "{\"a\":"),
            call(0, args: "1}"),
            call(1, id: "c1", name: "beta", args: "{\"b\""),
            call(1, args: ":2}"),
            ["choices": [["index": 0, "delta": [String: Any](), "finish_reason": "tool_calls"]]]
        ])
        let events = parseEvents(run(stream, byteAtATime: true))
        let starts = events.filter { $0.name == "content_block_start" }
        XCTAssertEqual(starts.map { $0.payload["index"] as? Int }, [0, 1, 2])
        XCTAssertEqual(starts.map { ($0.payload["content_block"] as? NSDictionary)?["type"] as? String },
                       ["text", "tool_use", "tool_use"])
        XCTAssertEqual((starts[1].payload["content_block"] as? NSDictionary)?["id"] as? String, "c0")
        XCTAssertEqual((starts[2].payload["content_block"] as? NSDictionary)?["name"] as? String, "beta")
        func fragments(_ index: Int) -> String {
            events.filter { $0.name == "content_block_delta" && $0.payload["index"] as? Int == index }
                .compactMap { ($0.payload["delta"] as? NSDictionary)?["partial_json"] as? String }.joined()
        }
        XCTAssertEqual(fragments(1), "{\"a\":1}")
        XCTAssertEqual(fragments(2), "{\"b\":2}")
        XCTAssertEqual(events.filter { $0.name == "content_block_stop" }.count, 3)
        assertSequential(events)
        let delta = events.first { $0.name == "message_delta" }
        XCTAssertEqual((delta?.payload["delta"] as? NSDictionary)?["stop_reason"] as? String, "tool_use")
        XCTAssertEqual(events.last?.name, "message_stop")
    }

    func testInterleavedToolFragmentsNeverOpenTwoBlocks() {
        let stream = sse([
            toolChunk(0, id: "c0", name: "alpha", args: "{\"a\":"),
            toolChunk(1, id: "c1", name: "beta", args: "{\"b\":2}"),
            toolChunk(0, args: "1}"),
            ["choices": [["index": 0, "delta": ["content": "late"], "finish_reason": "tool_calls"]]]
        ])
        let events = parseEvents(run(stream, byteAtATime: false))
        assertSequential(events)
        let joined = events.compactMap { ($0.payload["delta"] as? NSDictionary)?["partial_json"] as? String }
        XCTAssertEqual(joined, ["{\"a\":", "{\"b\":2}"])   // the late "1}" was dropped
        let names = events.map(\.name)
        XCTAssertEqual(names.filter { $0 == "content_block_start" }.count, 3)
    }

    func testKeylessIDStartsNewCallEvenWhenCurrentHasNoID() {
        let stream = sse([
            toolChunk(nil, args: "{\"orphan\""),                  // no id, no name: never started, dropped
            toolChunk(nil, id: "k0", name: "alpha", args: "{\"a\":"),
            toolChunk(nil, args: "1}"),
            toolChunk(nil, id: "k1", name: "beta", args: "{}")
        ])
        let events = parseEvents(run(stream, byteAtATime: true))
        assertSequential(events)
        let starts = events.filter { $0.name == "content_block_start" }
        XCTAssertEqual(starts.compactMap { ($0.payload["content_block"] as? NSDictionary)?["name"] as? String },
                       ["alpha", "beta"])
        let first = events.filter { $0.name == "content_block_delta" && $0.payload["index"] as? Int == 0 }
            .compactMap { ($0.payload["delta"] as? NSDictionary)?["partial_json"] as? String }.joined()
        XCTAssertEqual(first, "{\"a\":1}")
    }

    func testToolBlockWaitsForNameNotJustID() {
        let stream = sse([
            toolChunk(0, id: "c0", args: "{\"a\":"),
            toolChunk(0, args: "1}"),
            toolChunk(0, name: "alpha")
        ])
        let events = parseEvents(run(stream, byteAtATime: false))
        XCTAssertEqual(events.map(\.name), [
            "message_start", "content_block_start", "content_block_delta", "content_block_stop",
            "message_delta", "message_stop"
        ])
        let start = events[1].payload["content_block"] as? NSDictionary
        XCTAssertEqual(start?["name"] as? String, "alpha")
        XCTAssertEqual(start?["id"] as? String, "c0")
        XCTAssertEqual((events[2].payload["delta"] as? NSDictionary)?["partial_json"] as? String, "{\"a\":1}")
    }

    func testNamelessPendingCallDroppedAtFinish() {
        let stream = sse([toolChunk(0, id: "c0", args: "{}")])
        let events = parseEvents(run(stream, byteAtATime: false))
        XCTAssertEqual(events.map(\.name), ["message_start", "message_delta", "message_stop"])
    }

    func testNameArrivingAfterIDIsNotLostWhenStartWaitsForIt() {
        let stream = sse([toolChunk(0, name: "late", args: "{}")])
        let events = parseEvents(run(stream, byteAtATime: false))
        let start = events.first { $0.name == "content_block_start" }
        XCTAssertEqual((start?.payload["content_block"] as? NSDictionary)?["name"] as? String, "late")
    }

    func testGeneratedToolUseID() {
        let events = parseEvents(run(sse([toolChunk(0, name: "n", args: "{}")]), byteAtATime: false))
        let start = events.first { $0.name == "content_block_start" }
        let id = (start?.payload["content_block"] as? NSDictionary)?["id"] as? String
        XCTAssertEqual(id?.hasPrefix("toolu_"), true)
        XCTAssertGreaterThan(id?.count ?? 0, 6)
    }

    func testNonASCIITextFedOneByteAtATime() {
        let text = "caf\u{E9} \u{1F600} na\u{EF}ve \u{65E5}\u{672C}"
        let stream = sse([["choices": [["index": 0, "delta": ["content": text], "finish_reason": "stop"]]]])
        let events = parseEvents(run(stream, byteAtATime: true))
        let got = events.compactMap { ($0.payload["delta"] as? NSDictionary)?["text"] as? String }.joined()
        XCTAssertEqual(got, text)
    }

    func testCRLFSplitAcrossChunks() {
        let translator = ChatCompletionsStreamTranslator(model: "m", messageID: "msg_1")
        let body = String(data: json(["choices": [["index": 0, "delta": ["content": "x"]]]]), encoding: .utf8) ?? ""
        var out = translator.consume(Data(("data: " + body).utf8))
        XCTAssertTrue(out.isEmpty)
        out.append(translator.consume(Data("\r".utf8)))
        XCTAssertTrue(out.isEmpty)
        out.append(translator.consume(Data("\n".utf8)))
        XCTAssertEqual(parseEvents(out).map(\.name), ["message_start", "content_block_start", "content_block_delta"])
        let more = translator.consume(Data("\r\n".utf8))   // blank line: nothing
        XCTAssertTrue(more.isEmpty)
        let closing = parseEvents(translator.finish())
        XCTAssertEqual(closing.map(\.name), ["content_block_stop", "message_delta", "message_stop"])
        let texts = parseEvents(out).compactMap { ($0.payload["delta"] as? NSDictionary)?["text"] as? String }
        XCTAssertEqual(texts, ["x"])
    }

    func testLinesAfterDoneInSameChunkNeverProcessed() {
        let ghostChunk: [String: Any] = ["choices": [["index": 0, "delta": ["content": "ghost"]]]]
        let ghost = String(data: json(ghostChunk), encoding: .utf8) ?? ""
        let input = Data(("data: [DONE]\ndata: " + ghost + "\n").utf8)
        let translator = ChatCompletionsStreamTranslator(model: "m", messageID: "msg_1")
        var out = translator.consume(input)
        out.append(translator.finish())
        let events = parseEvents(out)
        XCTAssertEqual(events.map(\.name), ["message_start", "message_delta", "message_stop"])
        XCTAssertFalse(events.contains { $0.name == "content_block_delta" })
    }

    func testDataAfterDoneIsIgnored() {
        var input = textStream
        input.append(sse([["choices": [["index": 0, "delta": ["content": "ghost"]]]]], done: false))
        let translator = ChatCompletionsStreamTranslator(model: "m", messageID: "msg_1")
        var out = translator.consume(input)
        out.append(translator.consume(sse([["choices": [["index": 0, "delta": ["content": "more"]]]]])))
        out.append(translator.finish())
        let events = parseEvents(out)
        XCTAssertEqual(events.last?.name, "message_stop")
        XCTAssertEqual(events.filter { $0.name == "message_stop" }.count, 1)
        XCTAssertFalse((String(data: out, encoding: .utf8) ?? "").contains("ghost"))
        XCTAssertFalse((String(data: out, encoding: .utf8) ?? "").contains("more"))
    }

    func testMidStreamErrorClosesBlockAndEmitsErrorOnly() {
        let stream = sse([
            ["choices": [["index": 0, "delta": ["content": "partial"]]]],
            ["error": ["message": "upstream died", "type": "server_error"]],
            ["choices": [["index": 0, "delta": ["content": "after"]]]]
        ])
        let translator = ChatCompletionsStreamTranslator(model: "m", messageID: "msg_1")
        var out = translator.consume(stream)
        out.append(translator.finish())
        let events = parseEvents(out)
        XCTAssertEqual(events.map(\.name), [
            "message_start", "content_block_start", "content_block_delta", "content_block_stop", "error"
        ])
        XCTAssertEqual(events.last?.payload, [
            "type": "error", "error": ["type": "api_error", "message": "upstream died"]
        ] as NSDictionary)
        let bare = parseEvents(run(sse([["error": ["code": 1]]]), byteAtATime: false))
        XCTAssertEqual(bare.map(\.name), ["error"])
        XCTAssertEqual((bare[0].payload["error"] as? NSDictionary)?["message"] as? String, "provider stream error")
    }

    func testFinishTwiceEmitsClosingEventsOnce() {
        let translator = ChatCompletionsStreamTranslator(model: "m", messageID: "msg_1")
        var out = translator.consume(textStream)   // includes [DONE]
        out.append(translator.finish())
        out.append(translator.finish())
        XCTAssertEqual(parseEvents(out).filter { $0.name == "message_stop" }.count, 1)
        XCTAssertEqual(parseEvents(out).filter { $0.name == "message_delta" }.count, 1)
    }

    func testFinishReasonMapping() {
        for (finish, expected) in [("length", "max_tokens"), ("content_filter", "refusal"),
                                   ("function_call", "tool_use"), ("weird", "end_turn")] {
            let stream = sse([["choices": [["index": 0, "delta": ["content": "x"], "finish_reason": finish]]]])
            let delta = parseEvents(run(stream, byteAtATime: false)).first { $0.name == "message_delta" }
            XCTAssertEqual((delta?.payload["delta"] as? NSDictionary)?["stop_reason"] as? String, expected)
        }
    }

    func testUnparseableDataLineSkipped() {
        let stream = Data("data: {not json\n\n".utf8) + textStream
        XCTAssertEqual(parseEvents(run(stream, byteAtATime: false)).map(\.name).count, 7)
    }

    // MARK: non-streamed reply and errors

    func testNonStreamedReplyWithToolCalls() throws {
        let reply: [String: Any] = [
            "id": "chatcmpl-9", "model": "gpt-x",
            "choices": [["index": 0, "finish_reason": "tool_calls", "message": [
                "role": "assistant", "content": "calling",
                "tool_calls": [
                    ["id": "c1", "type": "function", "function": ["name": "a", "arguments": "{\"k\":\"v\"}"]],
                    ["id": "c2", "type": "function", "function": ["name": "b", "arguments": "garbage"]]
                ]
            ]]],
            "usage": ["prompt_tokens": 11, "completion_tokens": 4]
        ]
        let result = object(try convert(reply))
        XCTAssertEqual(result["id"] as? String, "msg_chatcmpl-9")
        XCTAssertEqual(result["type"] as? String, "message")
        XCTAssertEqual(result["role"] as? String, "assistant")
        XCTAssertEqual(result["model"] as? String, "gpt-x")
        XCTAssertEqual(result["stop_reason"] as? String, "tool_use")
        XCTAssertEqual(result["content"] as? [NSDictionary], [
            ["type": "text", "text": "calling"],
            ["type": "tool_use", "id": "c1", "name": "a", "input": ["k": "v"]],
            ["type": "tool_use", "id": "c2", "name": "b", "input": [String: Any]()]
        ] as [NSDictionary])
        XCTAssertEqual(result["usage"] as? NSDictionary, ["input_tokens": 11, "output_tokens": 4] as NSDictionary)
    }

    func testNonStreamedFallbackModelAndMalformed() throws {
        let reply: [String: Any] = ["id": "x", "choices": [["finish_reason": "length", "message": ["content": "t"]]]]
        let result = object(try convert(reply))
        XCTAssertEqual(result["model"] as? String, "fb")
        XCTAssertEqual(result["stop_reason"] as? String, "max_tokens")
        XCTAssertThrowsError(try convert([String: Any]())) {
            XCTAssertEqual($0 as? AnthropicChatTranslation.TranslationError, .malformedReply)
        }
    }

    func testErrorMapping() {
        let openAI = json(["error": ["message": "slow down", "type": "rate_limit_exceeded"]])
        XCTAssertEqual(object(error(429, openAI)), [
            "type": "error", "error": ["type": "rate_limit_error", "message": "slow down"]
        ] as NSDictionary)
        XCTAssertEqual(object(error(500, Data("upstream blew up".utf8))), [
            "type": "error", "error": ["type": "api_error", "message": "upstream blew up"]
        ] as NSDictionary)
        let long = Data(String(repeating: "a", count: 900).utf8)
        let message = (object(error(502, long))["error"] as? NSDictionary)?["message"] as? String
        XCTAssertEqual(message?.count, 500)
        let expected = [400: "invalid_request_error", 401: "authentication_error", 403: "permission_error",
                        404: "not_found_error", 413: "request_too_large", 529: "overloaded_error"]
        for (status, type) in expected {
            let body = object(error(status, Data()))["error"] as? NSDictionary
            XCTAssertEqual(body?["type"] as? String, type)
        }
    }
}
