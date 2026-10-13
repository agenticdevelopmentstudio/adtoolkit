// Tests/AgenticToolkitCoreTests/Chat/CompositeChatToolSourceTests.swift
import Testing
import Foundation
@testable import AgenticToolkitCore

private final class RecordingSource: ChatToolSource, @unchecked Sendable {
    let names: [String]
    var calls: [(String, String?)] = []
    init(_ names: [String]) { self.names = names }
    func toolDefinitions() async -> [ToolDefinition] {
        names.map {
            ToolDefinition(name: $0, description: $0, parametersJSONSchema: ToolJSONSchema.object(properties: [:]))
        }
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        calls.append((name, caller))
        return ("\(name) ok", false)
    }
}

@Suite("CompositeChatToolSource")
struct CompositeChatToolSourceTests {
    @Test("concatenates definitions in order")
    func concatenatesDefinitionsInOrder() async {
        let composite = CompositeChatToolSource([RecordingSource(["a", "b"]), RecordingSource(["c"])])
        let names = await composite.toolDefinitions().map(\.name)
        #expect(names == ["a", "b", "c"])
    }

    @Test("routes by name and passes the caller")
    func routesByNameAndPassesCaller() async {
        let first = RecordingSource(["a"]), second = RecordingSource(["b"])
        let composite = CompositeChatToolSource([first, second])
        let result = await composite.callTool(name: "b", argumentsJSON: Data("{}".utf8), caller: "pane-1")
        #expect(result.content == "b ok")
        #expect(second.calls.first?.0 == "b")
        #expect(second.calls.first?.1 == "pane-1")
        #expect(first.calls.isEmpty)
    }

    @Test("an unknown tool is a sentence")
    func unknownToolIsASentence() async {
        let composite = CompositeChatToolSource([RecordingSource(["a"])])
        let result = await composite.callTool(name: "zzz", argumentsJSON: Data(), caller: nil)
        #expect(result.isError)
        #expect(result.content == "unknown tool zzz")
    }

    @Test("the two-argument call forwards with a nil caller")
    func twoArgumentCallForwardsWithNilCaller() async {
        let source = RecordingSource(["a"])
        _ = await source.callTool(name: "a", argumentsJSON: Data())
        #expect(source.calls.count == 1)
        #expect(source.calls.first?.1 == nil)
    }
}
