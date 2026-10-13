import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class MCPHTTPEndpointTests: XCTestCase {

    /// A source whose one tool reports the caller it was given.
    final class CallerSource: ChatToolSource, @unchecked Sendable {
        private let lock = NSLock()
        private var recorded: [String] = []
        var callers: [String] {
            lock.lock()
            defer { lock.unlock() }
            return recorded
        }

        private func record(_ caller: String) {
            lock.lock()
            recorded.append(caller)
            lock.unlock()
        }

        func toolDefinitions() async -> [ToolDefinition] {
            [ToolDefinition(name: "whoami", description: "names the caller",
                            parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
        }
        func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
            record(caller ?? "none")
            // Long enough that two concurrent calls overlap.
            try? await Task.sleep(nanoseconds: 300_000_000)
            return ("caller:\(caller ?? "none")", false)
        }
    }

    private let source = CallerSource()
    private var endpoint: MCPHTTPEndpoint!
    private var port: UInt16 = 0
    private let token = "test-token"

    override func setUp() async throws {
        let server = HostMCPServer(appName: "Test", appVersion: "1")
        await server.register(source)
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
        try await Self.post(port: port, method: method, path: path, body: body,
                            bearer: bearer, extraHeaders: extraHeaders)
    }

    private static func post(
        port: UInt16, method: String = "POST", path: String = "/mcp", body: String,
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

    typealias Outcome = (pane: String, id: Int?, text: String?, elapsed: TimeInterval)

    /// The SDK keys its per-request bookkeeping by JSON-RPC id alone; the
    /// endpoint gives each request a unique id and restores the caller's.
    private static func timedWhoAmI(port: UInt16, pane: String) async throws -> Outcome {
        let body = #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"whoami","arguments":{}}}"#
        let begin = Date()
        let (_, json) = try await post(port: port, body: body, extraHeaders: [HostMCPServer.callerHeader: pane])
        let content = ((json?["result"] as? [String: Any])?["content"] as? [[String: Any]])?.first
        return (pane, json?["id"] as? Int, content?["text"] as? String, Date().timeIntervalSince(begin))
    }

    func testConcurrentCallsWithTheSameIdKeepTheirOwnCaller() async throws {
        let port = self.port
        async let first = Self.timedWhoAmI(port: port, pane: "pane-A")
        async let second = Self.timedWhoAmI(port: port, pane: "pane-B")
        let results = try await [first, second]
        for result in results {
            XCTAssertEqual(result.id, 1, "\(result.pane) must get its own id back")
            XCTAssertEqual(result.text, "caller:\(result.pane)")
            XCTAssertLessThan(result.elapsed, 5)
        }
        XCTAssertEqual(source.callers.sorted(), ["pane-A", "pane-B"])
    }

    func testStringIdsRoundTripToo() async throws {
        let body = #"{"jsonrpc":"2.0","id":"abc","method":"tools/list","params":{}}"#
        let (status, json) = try await send(body: body)
        XCTAssertEqual(status, 200)
        XCTAssertEqual(json?["id"] as? String, "abc")
    }

    /// `"id": null` is no id to the SDK: a notification, answered 202 with no
    /// body. The endpoint must not turn it into a request.
    func testNullIdIsStillANotification() async throws {
        let body = #"{"jsonrpc":"2.0","id":null,"method":"tools/list","params":{}}"#
        let (status, json) = try await send(body: body)
        XCTAssertEqual(status, 202)
        XCTAssertNil(json)
    }

    func testStartWhileRunningReturnsTheSamePort() async throws {
        let again = try await endpoint.start()
        XCTAssertEqual(again, port)
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
