// Tests/AgenticToolkitMacOSTests/MCP/HostMCPServerTests.swift
import XCTest
import MCP
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// A source that records calls and answers with its name.
final class EchoSource: ChatToolSource, @unchecked Sendable {
    let names: [String]
    var calls: [(name: String, json: String, caller: String?)] = []
    init(names: [String]) { self.names = names }
    func toolDefinitions() async -> [ToolDefinition] {
        let schema = ToolJSONSchema.object(properties: ["x": ToolJSONSchema.string("x")])
        return names.map { ToolDefinition(name: $0, description: "echo \($0)", parametersJSONSchema: schema) }
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        calls.append((name, String(bytes: argumentsJSON, encoding: .utf8) ?? "", caller))
        if name == "fails" { return ("it failed", true) }
        if name == "image" { return ("data:image/png;base64,iVBORw0KGgo=", false) }
        return ("echo:\(name)", false)
    }
}

/// Counts calls made from a `@Sendable` closure.
final class OpenCounter: @unchecked Sendable {
    var count = 0
}

final class HostMCPServerTests: XCTestCase {

    /// Server + client joined by an in-memory transport pair.
    private func makePair(sources: [(any ChatToolSource, String?)]) async throws -> (HostMCPServer, Client) {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        for (source, prefix) in sources { await server.register(source, prefix: prefix) }
        // The pair is labelled (client:, server:) — destructure in that order.
        let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: serverTransport)
        let client = Client(name: "test-client", version: "1")
        _ = try await client.connect(transport: clientTransport)
        addTeardownBlock {
            await client.disconnect()
            await server.stop()
        }
        return (server, client)
    }

    func testListToolsConcatenatesSourcesInRegistrationOrder() async throws {
        let (server, client) = try await makePair(sources: [
            (EchoSource(names: ["a", "b"]), nil), (EchoSource(names: ["c"]), nil)
        ])
        let tools = try await client.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["a", "b", "c"])
        XCTAssertEqual(tools.first?.description, "echo a")
        await server.stop()
    }

    func testInputSchemaIsTheDefinitionsSchema() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["a"]), nil)])
        let tool = try await client.listTools().tools[0]
        let schema = tool.inputSchema.objectValue
        XCTAssertEqual(schema?["type"], .string("object"))
        XCTAssertNotNil(schema?["properties"]?.objectValue?["x"])
        await server.stop()
    }

    func testCallRoutesToTheSourceThatAdvertisesTheName() async throws {
        let first = EchoSource(names: ["a"]), second = EchoSource(names: ["b"])
        let (server, client) = try await makePair(sources: [(first, nil), (second, nil)])
        let result = try await client.callTool(name: "b", arguments: ["x": .string("1")])
        XCTAssertEqual(result.isError ?? false, false)
        guard case .text(let text, _, _) = result.content.first else { return XCTFail("expected text") }
        XCTAssertEqual(text, "echo:b")
        XCTAssertEqual(second.calls.count, 1)
        XCTAssertEqual(second.calls[0].json, #"{"x":"1"}"#)
        XCTAssertTrue(first.calls.isEmpty)
        await server.stop()
    }

    func testErrorResultIsErrorWithTheSentence() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["fails"]), nil)])
        let result = try await client.callTool(name: "fails", arguments: [:])
        XCTAssertEqual(result.isError, true)
        guard case .text(let text, _, _) = result.content.first else { return XCTFail("expected text") }
        XCTAssertEqual(text, "it failed")
        await server.stop()
    }

    func testUnknownToolIsAnErrorResultNotAProtocolError() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["a"]), nil)])
        let result = try await client.callTool(name: "nope", arguments: [:])
        XCTAssertEqual(result.isError, true)
        guard case .text(let text, _, _) = result.content.first else { return XCTFail("expected text") }
        XCTAssertEqual(text, "unknown tool nope")
        await server.stop()
    }

    func testPrefixIsAppliedToNamesAndStrippedOnCall() async throws {
        let source = EchoSource(names: ["info"])
        let (server, client) = try await makePair(sources: [(source, "host_")])
        let names = try await client.listTools().tools.map(\.name)
        XCTAssertEqual(names, ["host_info"])
        _ = try await client.callTool(name: "host_info", arguments: [:])
        XCTAssertEqual(source.calls.first?.name, "info")
        await server.stop()
    }

    func testPNGDataURLBecomesImageContent() async throws {
        let (server, client) = try await makePair(sources: [(EchoSource(names: ["image"]), nil)])
        let result = try await client.callTool(name: "image", arguments: [:])
        guard case .image(let data, let mime, _, _) = result.content.first else { return XCTFail("expected image") }
        XCTAssertEqual(mime, "image/png")
        XCTAssertEqual(data, "iVBORw0KGgo=")
        await server.stop()
    }

    func testHostAppToolSourceAnswersInfoAndOpensChat() async throws {
        let opened = OpenCounter()
        let host = HostAppToolSource(appName: "Kitchen", appVersion: "2.0", pluginNames: ["ClaudeAPI"],
                                     openChatWindow: { opened.count += 1 })
        let names = await host.toolDefinitions().map(\.name)
        XCTAssertEqual(names, ["host_app_info", "host_open_chat_window"])
        let info = await host.callTool(name: "host_app_info", argumentsJSON: Data("{}".utf8), caller: nil)
        XCTAssertEqual(info.content, "Host: Kitchen\nVersion: 2.0\nPlugins: ClaudeAPI")
        let open = await host.callTool(name: "host_open_chat_window", argumentsJSON: Data("{}".utf8), caller: nil)
        XCTAssertEqual(open.content, "Opened a new chat window.")
        XCTAssertEqual(opened.count, 1)
    }

    func testHostAppInfoSaysNoneWhenThereAreNoPlugins() async {
        let host = HostAppToolSource(appName: "Kitchen", appVersion: "2.0")
        let info = await host.callTool(name: "host_app_info", argumentsJSON: Data("{}".utf8), caller: nil)
        XCTAssertEqual(info.content, "Host: Kitchen\nVersion: 2.0\nPlugins: (none)")
    }

    func testSecondServeStopsTheFirst() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(EchoSource(names: ["a"]))
        addTeardownBlock { await server.stop() }

        let first = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: first.server)
        let firstClient = Client(name: "first", version: "1")
        _ = try await firstClient.connect(transport: first.client)
        addTeardownBlock { await firstClient.disconnect() }

        let second = await InMemoryTransport.createConnectedPair()
        try await server.serve(over: second.server)
        let secondClient = Client(name: "second", version: "1")
        _ = try await secondClient.connect(transport: second.client)
        addTeardownBlock { await secondClient.disconnect() }

        let tools = try await secondClient.listTools().tools
        XCTAssertEqual(tools.map(\.name), ["a"])
        await server.stop()
    }

    func testCallerHeaderReachesTheSource() async throws {
        // `Server.HandlerContext` cannot be built outside the SDK, so the
        // header read (`caller(from:)`) and the call path are tested in turn.
        let request = HTTPRequest(method: "POST", headers: ["x-adkitchen-pane": "pane-7"])
        let caller = HostMCPServer.caller(from: request)
        XCTAssertEqual(caller, "pane-7")
        XCTAssertNil(HostMCPServer.caller(from: nil))
        XCTAssertNil(HostMCPServer.caller(from: HTTPRequest(method: "POST")))

        let source = EchoSource(names: ["a"])
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(source)
        _ = await server.call(name: "a", arguments: [:], caller: caller)
        XCTAssertEqual(source.calls.first?.caller, "pane-7")
    }
}
