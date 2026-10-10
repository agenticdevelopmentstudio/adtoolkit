import Foundation
import Testing
@testable import AIPluginKit

@Suite("PromptedToolCallingPlugin")
struct PromptedToolCallingPluginTests {

    /// Records the context it was asked to build, and decodes plain text.
    private final class RecordingPlugin: AIPlugin, @unchecked Sendable {
        var lastContext: AIChatContext?
        func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
            lastContext = context
            return .command(executableURL: URL(fileURLWithPath: "/bin/true"), arguments: [],
                            stdin: nil, environment: [:])
        }
        func makeDecoder() -> any AIStreamDecoder { TextDecoder() }
    }

    private final class TextDecoder: AIStreamDecoder {
        func consume(_ data: Data) -> [AIStreamEvent] { [.textDelta(String(bytes: data, encoding: .utf8) ?? "")] }
        func finish() -> [AIStreamEvent] { [.end(stopReason: "end_turn")] }
    }

    private let tool = AIToolSpec(name: "run", description: "Run a command.",
                                  parametersJSONSchema: Data(#"{"type":"object"}"#.utf8))

    @Test("a context without tools passes through untouched")
    func passesThrough() throws {
        let inner = RecordingPlugin()
        let context = AIChatContext(messages: [AIChatMessage(role: .user, content: "hi")], model: "m",
                                    systemPrompt: "be kind", config: AIPluginConfig([:]))
        _ = try PromptedToolCallingPlugin(wrapping: inner).buildRequest(context)
        #expect(inner.lastContext?.systemPrompt == "be kind")
        #expect(inner.lastContext?.config.builtInTools == nil)
    }

    @Test("tools move into the system prompt and switch built-in tools off")
    func describesTools() throws {
        let inner = RecordingPlugin()
        let context = AIChatContext(messages: [AIChatMessage(role: .user, content: "hi")], model: "m",
                                    systemPrompt: "be kind", tools: [tool], config: AIPluginConfig([:]))
        _ = try PromptedToolCallingPlugin(wrapping: inner).buildRequest(context)
        let prompt = try #require(inner.lastContext?.systemPrompt)
        #expect(prompt.hasPrefix("be kind"))
        #expect(prompt.contains("- run: Run a command."))
        #expect(inner.lastContext?.tools.isEmpty == true)
        #expect(inner.lastContext?.config.builtInTools == "none")
    }

    @Test("earlier calls and results are written back as text")
    func textualHistory() {
        let messages = PromptedToolCallingPlugin.textual([
            AIChatMessage(role: .user, content: "where am I?"),
            AIChatMessage(role: .assistant, content: "Checking."),
            AIChatMessage(role: .toolUse, content: "", toolUseId: "1", toolName: "run",
                          toolArgumentsJSON: Data(#"{"command":"pwd"}"#.utf8)),
            AIChatMessage(role: .toolResult, content: "/Users/bobby", toolUseId: "1")
        ])
        #expect(messages.map(\.role) == [.user, .assistant, .user])
        let call = #"<tool_call>{"name": "run", "arguments": {"command":"pwd"}}</tool_call>"#
        #expect(messages[1].content.contains(call))
        #expect(messages[2].content == "[Tool result]\n/Users/bobby")
    }

    @Test("a reply's blocks become tool calls and the rest stays prose")
    func decodesCalls() {
        let decoder = PromptedToolCallingPlugin(wrapping: RecordingPlugin()).makeDecoder()
        var events = decoder.consume(Data("Let me look.\n<tool_call>{\"name\": \"run\", ".utf8))
        #expect(events.isEmpty)
        events += decoder.consume(Data("\"arguments\": {\"command\": \"pwd\"}}</tool_call>".utf8))
        events += decoder.finish()

        guard events.count == 3,
              case .textDelta(let text) = events[0],
              case .toolUse(_, let name, let arguments) = events[1],
              case .end(let reason) = events[2] else {
            Issue.record("unexpected events: \(events)")
            return
        }
        #expect(text == "Let me look.")
        #expect(name == "run")
        let object = (try? JSONSerialization.jsonObject(with: arguments)) as? [String: String]
        #expect(object == ["command": "pwd"])
        #expect(reason == "tool_use")
    }

    @Test("a malformed block is left in the prose")
    func keepsMalformedBlocks() {
        let parsed = PromptedToolCallingPlugin.parse("oops <tool_call>not json</tool_call> done")
        #expect(parsed.calls.isEmpty)
        #expect(parsed.text == "oops <tool_call>not json</tool_call> done")
    }
}
