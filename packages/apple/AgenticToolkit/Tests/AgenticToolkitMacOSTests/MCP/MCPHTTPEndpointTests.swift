import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class MCPHTTPEndpointTests: XCTestCase {

    /// A source with two tools: `whoami` reports the caller it was given, and
    /// `sleep` runs for two seconds and records whether it was cancelled.
    final class CallerSource: ChatToolSource, @unchecked Sendable {
        static let sleepSeconds: UInt64 = 2
        private let lock = NSLock()
        private var recorded: [String] = []
        private var recordedOutcomes: [String] = []
        var callers: [String] {
            lock.lock()
            defer { lock.unlock() }
            return recorded
        }
        /// "finished" or "cancelled", one per `sleep` call.
        var outcomes: [String] {
            lock.lock()
            defer { lock.unlock() }
            return recordedOutcomes
        }

        private func record(_ caller: String) {
            lock.lock()
            recorded.append(caller)
            lock.unlock()
        }

        private func recordOutcome(_ outcome: String) {
            lock.lock()
            recordedOutcomes.append(outcome)
            lock.unlock()
        }

        func toolDefinitions() async -> [ToolDefinition] {
            [ToolDefinition(name: "whoami", description: "names the caller",
                            parametersJSONSchema: ToolJSONSchema.object(properties: [:])),
             ToolDefinition(name: "sleep", description: "sleeps, and notices being cancelled",
                            parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
        }
        func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
            if name == "sleep" {
                do {
                    try await Task.sleep(nanoseconds: Self.sleepSeconds * 1_000_000_000)
                    recordOutcome("finished")
                } catch {
                    recordOutcome("cancelled")
                }
                return ("slept", false)
            }
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
        XCTAssertEqual(tools?.map { $0["name"] as? String }, ["whoami", "sleep"])
    }

    // MARK: - Cancellation

    private static let sleepCall =
        #"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"sleep","arguments":{}}}"#
    private static let cancelFive =
        #"{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":5,"reason":"gave up"}}"#
    private static let paneC = [HostMCPServer.callerHeader: "pane-C"]

    /// A caller's `notifications/cancelled` names the id the caller sent. The
    /// endpoint points it at the id the SDK knows the request by, the tool
    /// stops, and the waiting call is answered rather than held open.
    func testCallerCancellationReachesTheTool() async throws {
        let port = self.port
        let begin = Date()
        async let call = Self.post(port: port, body: Self.sleepCall, extraHeaders: Self.paneC)
        try await Task.sleep(nanoseconds: 300_000_000)
        let (status, json) = try await send(body: Self.cancelFive, extraHeaders: Self.paneC)
        XCTAssertEqual(status, 202)
        XCTAssertNil(json)
        let (callStatus, callJSON) = try await call
        XCTAssertLessThan(Date().timeIntervalSince(begin), 1.5, "the call must not run to the sleep's end")
        XCTAssertEqual(callStatus, 200)
        XCTAssertEqual(callJSON?["id"] as? Int, 5, "the caller gets its own id back")
        XCTAssertNotNil(callJSON?["error"])
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(source.outcomes, ["cancelled"])
    }

    /// Two callers may both be using id 5. A cancellation from one must not
    /// stop the other's request.
    func testCancellationFromAnotherCallerCancelsNothing() async throws {
        let port = self.port
        async let call = Self.post(port: port, body: Self.sleepCall, extraHeaders: Self.paneC)
        try await Task.sleep(nanoseconds: 300_000_000)
        let (status, _) = try await send(body: Self.cancelFive, extraHeaders: [HostMCPServer.callerHeader: "pane-D"])
        XCTAssertEqual(status, 202)
        let (callStatus, callJSON) = try await call
        XCTAssertEqual(callStatus, 200)
        XCTAssertNotNil(callJSON?["result"])
        XCTAssertEqual(source.outcomes, ["finished"])
    }

    /// FlyingFox's timeout cancels only its own handler. The endpoint forwards
    /// it into the SDK, so the tool stops when the client is told it failed.
    func testHTTPTimeoutCancelsTheTool() async throws {
        let slow = CallerSource()
        let server = HostMCPServer(appName: "Slow", appVersion: "1")
        await server.register(slow)
        let endpoint = MCPHTTPEndpoint(server: server, token: token, preferredPort: 0, requestTimeout: 0.5)
        let port = try await endpoint.start()
        let begin = Date()
        let (status, _) = try await Self.post(port: port, body: Self.sleepCall)
        XCTAssertEqual(status, 500)
        XCTAssertLessThan(Date().timeIntervalSince(begin), 1.5)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(slow.outcomes, ["cancelled"])
        await endpoint.stop()
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
