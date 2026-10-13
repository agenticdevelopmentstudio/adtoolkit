import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class MCPHTTPEndpointTests: XCTestCase {

    /// A source whose one tool reports the caller it was given.
    final class CallerSource: ChatToolSource, @unchecked Sendable {
        func toolDefinitions() async -> [ToolDefinition] {
            [ToolDefinition(name: "whoami", description: "names the caller",
                            parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
        }
        func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
            ("caller:\(caller ?? "none")", false)
        }
    }

    private var endpoint: MCPHTTPEndpoint!
    private var port: UInt16 = 0
    private let token = "test-token"

    override func setUp() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(CallerSource())
        // An ephemeral preferred port so the suite never collides with a
        // running app on 51477.
        endpoint = MCPHTTPEndpoint(server: server, token: token, preferredPort: 0)
        port = try await endpoint.start()
    }

    override func tearDown() async throws {
        await endpoint.stop()
    }

    private func send(
        method: String = "POST", path: String = "/mcp", body: String,
        bearer: String? = "test-token", extraHeaders: [String: String] = [:]
    ) async throws -> (Int, [String: Any]?) {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port)\(path)")!)
        request.httpMethod = method
        request.httpBody = Data(body.utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearer { request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        for (key, value) in extraHeaders { request.setValue(value, forHTTPHeaderField: key) }
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = try XCTUnwrap(response as? HTTPURLResponse).statusCode
        return (status, try? JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func rpc(_ method: String, params: String = "{}", id: Int = 1) -> String {
        #"{"jsonrpc":"2.0","id":\#(id),"method":"\#(method)","params":\#(params)}"#
    }

    func testToolsListRoundTrip() async throws {
        let (status, json) = try await send(body: rpc("tools/list"))
        XCTAssertEqual(status, 200)
        let tools = (json?["result"] as? [String: Any])?["tools"] as? [[String: Any]]
        XCTAssertEqual(tools?.map { $0["name"] as? String }, ["whoami"])
    }

    func testCallerHeaderReachesTheSource() async throws {
        let (status, json) = try await send(body: rpc("tools/call", params: #"{"name":"whoami","arguments":{}}"#),
                                            extraHeaders: [HostMCPServer.callerHeader: "pane-7"])
        XCTAssertEqual(status, 200)
        let content = ((json?["result"] as? [String: Any])?["content"] as? [[String: Any]])?.first
        XCTAssertEqual(content?["text"] as? String, "caller:pane-7")
    }

    func testMissingCallerHeaderIsNone() async throws {
        let (_, json) = try await send(body: rpc("tools/call", params: #"{"name":"whoami","arguments":{}}"#))
        let content = ((json?["result"] as? [String: Any])?["content"] as? [[String: Any]])?.first
        XCTAssertEqual(content?["text"] as? String, "caller:none")
    }

    func testWrongBearerIs401() async throws {
        let (status, _) = try await send(body: rpc("tools/list"), bearer: "nope")
        XCTAssertEqual(status, 401)
    }

    func testMissingBearerIs401() async throws {
        let (status, _) = try await send(body: rpc("tools/list"), bearer: nil)
        XCTAssertEqual(status, 401)
    }

    func testOtherPathIs404() async throws {
        let (status, _) = try await send(path: "/other", body: rpc("tools/list"))
        XCTAssertEqual(status, 404)
    }

    func testGetIs405() async throws {
        let (status, _) = try await send(method: "GET", body: "")
        XCTAssertEqual(status, 405)
    }

    /// The SDK's pipeline refuses a foreign Origin before the server sees it.
    func testForeignOriginIsRefused() async throws {
        let (status, _) = try await send(body: rpc("tools/list"), extraHeaders: ["Origin": "https://evil.example"])
        XCTAssertNotEqual(status, 200)
        XCTAssertTrue([400, 403, 421].contains(status), "got \(status)")
    }

    /// Review Focus 5: a second endpoint wanting the same port gets another.
    func testSecondEndpointFallsBackToAnotherPort() async throws {
        let second = MCPHTTPEndpoint(server: HostMCPServer(appName: "Two", appVersion: "1"),
                                     token: token, preferredPort: port)
        let secondPort = try await second.start()
        XCTAssertNotEqual(secondPort, port)
        XCTAssertNotEqual(secondPort, 0)
        await second.stop()
    }
}
