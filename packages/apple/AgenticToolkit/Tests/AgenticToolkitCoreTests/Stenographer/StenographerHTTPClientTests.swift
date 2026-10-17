import XCTest
@testable import AgenticToolkitCore

/// Serves canned replies per path so the client is tested without a daemon.
final class StubDaemonProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (Int, Data))?
    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost)); return
        }
        let (status, body) = handler(request)
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: nil,
            headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class StenographerHTTPClientTests: XCTestCase {

    private func makeClient(healthPollInterval: TimeInterval = 3600) -> StenographerHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubDaemonProtocol.self]
        return StenographerHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:22847")!,
            session: URLSession(configuration: config),
            healthPollInterval: healthPollInterval)
    }

    override func tearDown() { StubDaemonProtocol.handler = nil }

    func testUnreachableDaemonReturnsNil() async {
        StubDaemonProtocol.handler = nil
        let client = makeClient()
        let sessions = await client.sessions(status: nil, project: nil, sinceHours: 24, includeCounts: false)
        XCTAssertNil(sessions)
        let findings = await client.oversightFindings()
        XCTAssertNil(findings)
        let succeeded = await client.setSummaryPreferences(SummaryPreferenceRequest(enabled: true))
        XCTAssertFalse(succeeded)
    }

    func testSessionsBuildsQueryAndDecodes() async throws {
        let captured = Captured()
        StubDaemonProtocol.handler = { request in
            captured.set(request.url!)
            return (200, Data("""
            [{"session_id":"s1","cwd":"/x","model":"m","started_at":"2026-10-12T00:00:00Z",
              "last_activity_at":"2026-10-12T00:00:01Z","status":"active","pid":1,
              "term_program":"iTerm.app","term_session_id":"t","project_root":"/x",
              "last_tool":"","git_branch":"main","summary":"","event_count":0}]
            """.utf8))
        }
        let client = makeClient()
        let sessions = await client.sessions(status: "active", project: nil, sinceHours: 24, includeCounts: false)
        XCTAssertEqual(sessions?.map(\.sessionId), ["s1"])
        let url = try XCTUnwrap(captured.url)
        XCTAssertEqual(url.path, "/sessions")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems ?? []
        XCTAssertTrue(items.contains(URLQueryItem(name: "status", value: "active")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "since_hours", value: "24")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "counts", value: "false")))
    }

    func testSessionNotFoundIsInnerNil() async {
        StubDaemonProtocol.handler = { _ in (404, Data(#"{"error":"Session not found: zz"}"#.utf8)) }
        let found = await makeClient().session(id: "zz", includeCounts: false)
        guard let inner = found else { return XCTFail("daemon reported unreachable") }
        XCTAssertNil(inner)
    }

    func testSummarizeThrowsDaemonReason() async {
        StubDaemonProtocol.handler = { _ in (500, Data(#"{"error":"Summarize failed: model too large"}"#.utf8)) }
        do {
            try await makeClient().summarize(sessionId: "s1")
            XCTFail("expected a throw")
        } catch let failure as SummarizeDaemonFailure {
            XCTAssertEqual(failure.reason, "Summarize failed: model too large")
        } catch {
            XCTFail("wrong error \(error)")
        }
    }

    func testActOnFindingMapsConflictToFailure() async {
        StubDaemonProtocol.handler = { _ in (409, Data(#"{"error":"Finding is already acted"}"#.utf8)) }
        let result = await makeClient().actOnOversightFinding(findingId: 7)
        XCTAssertEqual(result?.succeeded, false)
        XCTAssertEqual(result?.reason, "Finding is already acted")
    }

    func testActOnFindingSuccess() async {
        StubDaemonProtocol.handler = { _ in (200, Data("""
            {"id":7,"session_id":"s","observer":"compact","kind":"k","severity":1,"status":"acted","reason":"r",
             "created_at":"2026-10-12T00:00:00Z"}
            """.utf8)) }
        let result = await makeClient().actOnOversightFinding(findingId: 7)
        XCTAssertEqual(result?.succeeded, true)
        XCTAssertEqual(result?.status, "acted")
    }

    func testDeleteScriptIs204() async {
        StubDaemonProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/oversight/scripts/abc/delete")
            XCTAssertEqual(request.httpMethod, "POST")
            return (204, Data())
        }
        let succeeded = await makeClient().deleteOversightScript(id: "abc")
        XCTAssertTrue(succeeded)
    }

    func testSetSummaryPreferencesPostsSnakeCase() async throws {
        let captured = Captured()
        StubDaemonProtocol.handler = { request in
            captured.set(request.url!, body: request.httpBody ?? request.httpBodyStream.map(Self.readAll) ?? Data())
            return (200, Data("""
            {"enabled":false,"selected_config_id":"c","prompt":"","max_words":8,"activity_lines":60,
             "detail_chars":120,"interval_minutes":5,"max_per_run":5,"timeout_seconds":60}
            """.utf8))
        }
        let request = SummaryPreferenceRequest(enabled: false, selectedConfigId: "c")
        let succeeded = await makeClient().setSummaryPreferences(request)
        XCTAssertTrue(succeeded)
        XCTAssertEqual(captured.url?.path, "/preferences/summaries")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: captured.body) as? [String: Any])
        XCTAssertEqual(object["enabled"] as? Bool, false)
        XCTAssertEqual(object["selected_config_id"] as? String, "c")
    }

    func testSetAIPreferencesPostsTheRegistryAsCamelCase() async throws {
        let captured = Captured()
        StubDaemonProtocol.handler = { request in
            captured.set(request.url!, body: request.httpBody ?? request.httpBodyStream.map(Self.readAll) ?? Data())
            return (200, Data("{}".utf8))
        }
        let id = UUID()
        let sync = AIProviderConfigSync(
            enabled: true, selectedConfigId: id,
            configs: [ResolvedProviderConfig(
                id: id, name: "A", pluginIdentifier: "p", templateId: "t", model: "m",
                values: ["baseURL": "h"], secrets: ["apiKey": "k"])])
        let succeeded = await makeClient().setAIPreferences(sync)
        XCTAssertTrue(succeeded)
        XCTAssertEqual(captured.url?.path, "/preferences/ai")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: captured.body) as? [String: Any])
        XCTAssertEqual(object["selectedConfigId"] as? String, id.uuidString)
        XCTAssertEqual(try JSONDecoder().decode(AIProviderConfigSync.self, from: captured.body), sync)
    }

    func testSetAIPreferencesIsFalseOnAnErrorStatusOrNoDaemon() async {
        let sync = AIProviderConfigSync(enabled: true, selectedConfigId: nil, configs: [])
        StubDaemonProtocol.handler = { _ in (400, Data("{}".utf8)) }
        let rejected = await makeClient().setAIPreferences(sync)
        XCTAssertFalse(rejected)
        StubDaemonProtocol.handler = nil
        let unreachable = await makeClient().setAIPreferences(sync)
        XCTAssertFalse(unreachable)
    }

    func testReconnectFiresWhenUptimeDrops() async {
        let uptimes = Uptimes([500, 600, 3, 10])
        StubDaemonProtocol.handler = { _ in
            (200, Data(#"{"status":"ok","uptime":\#(uptimes.next()),"version":"1.2.21"}"#.utf8))
        }
        let client = makeClient(healthPollInterval: 0.05)
        let fired = expectation(description: "reconnect")
        fired.assertForOverFulfill = false
        client.onReconnect { fired.fulfill() }
        await fulfillment(of: [fired], timeout: 2)
    }

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open(); defer { stream.close() }
        var data = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

/// Lock-protected capture boxes (the stub's handler runs off the test's actor).
final class Captured: @unchecked Sendable {
    private let lock = NSLock()
    private var _url: URL?; private var _body = Data()
    var url: URL? { lock.withLock { _url } }
    var body: Data { lock.withLock { _body } }
    func set(_ url: URL, body: Data = Data()) { lock.withLock { _url = url; _body = body } }
}

final class Uptimes: @unchecked Sendable {
    private let lock = NSLock(); private var values: [Int]
    init(_ values: [Int]) { self.values = values }
    func next() -> Int { lock.withLock { values.count > 1 ? values.removeFirst() : values[0] } }
}
