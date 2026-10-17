import XCTest
import Foundation
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitDatabase

/// `SessionFeatureRoutes` over a real `DaemonDatabase`, with every daemon-only
/// closure replaced by a recorder so the routes are exercised without a daemon.
final class SessionFeatureRoutesTests: XCTestCase {

    private struct ImportUnavailable: Error {}

    /// Hook deliveries the routes handed to `captureHook`.
    private final class Captured: @unchecked Sendable {
        private let lock = NSLock()
        private var events: [ParsedEvent] = []
        func add(_ event: ParsedEvent) { lock.lock(); events.append(event); lock.unlock() }
        var count: Int { lock.lock(); defer { lock.unlock() }; return events.count }
    }

    private var tmpDir: URL!
    private var db: DaemonDatabase!
    private var dbPath: String!
    private var captured: Captured!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("session-routes-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        db = opened.db
        dbPath = opened.path
        captured = Captured()
    }

    override func tearDownWithError() throws {
        TestDaemonDatabase.remove(path: dbPath)
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeServices(
        spool: IngestSpool? = nil,
        buildHookEvent: @escaping @Sendable (String, Data) -> ParsedEvent? = { _, _ in nil }
    ) throws -> SessionFeatureServices {
        let dispatcher = tmpDir.appendingPathComponent("dispatch.sh")
        try "#!/bin/sh\n# claudehelpers-statusline-dispatch 1\n".write(to: dispatcher, atomically: true, encoding: .utf8)
        let installer = ClaudeHookInstaller(
            configuration: ClaudeHookConfiguration(
                name: "routes-test",
                marker: "# routes-test-hook",
                hookBinaryPath: tmpDir.appendingPathComponent("helper").path,
                dropDirectory: tmpDir.appendingPathComponent("drop").path,
                settingsURL: tmpDir.appendingPathComponent("settings.json"),
                bundledDispatcher: dispatcher
            ),
            helperIsExecutable: { _ in true }
        )
        let secrets = InMemorySecretStore()
        let captured = self.captured!
        return SessionFeatureServices(
            database: db,
            conversations: ConversationStore(database: db),
            quarantine: QuarantineService(
                errorsDirectory: tmpDir.appendingPathComponent("errors"), database: db
            ),
            spool: spool,
            preferences: PreferencesService(
                database: db, secretStore: secrets, hookInstaller: installer, summariesDefaultEnabled: true
            ),
            secretStore: secrets,
            hookInstaller: installer,
            daemonName: "routes-test",
            daemonVersion: "9.9.9",
            startTime: Date(),
            endpointIndex: ["GET /health", "GET /sessions"],
            startupDurationMs: { 42 },
            memorySample: { SessionFeatureServices.MemorySample(footprintMB: 10, peakMB: 20) },
            parseQuarantinedEvent: { _ in .unparseable },
            retryIngest: { _ in },
            buildHookEvent: buildHookEvent,
            captureHook: { captured.add($0) },
            runImport: { _ in throw ImportUnavailable() }
        )
    }

    private func send(
        _ method: String, _ path: String, query: [String: [String]] = [:], body: String = "",
        services: SessionFeatureServices
    ) async throws -> RouteResponse {
        let request = RouteRequest(method: method, path: path, queryValues: query, body: Data(body.utf8))
        return try XCTUnwrap(await SessionFeatureRoutes.table(services).handle(request), "\(method) \(path) unclaimed")
    }

    private func json(_ response: RouteResponse) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: response.body) as? [String: Any])
    }

    // MARK: - Index and health

    func testRootReportsTheNameVersionAndEndpointIndex() async throws {
        let response = try await send("GET", "/", services: try makeServices())
        XCTAssertEqual(response.status, 200)
        let body = try json(response)
        XCTAssertEqual(body["name"] as? String, "routes-test")
        XCTAssertEqual(body["version"] as? String, "9.9.9")
        XCTAssertEqual(body["endpoints"] as? [String], ["GET /health", "GET /sessions"])
    }

    func testRootBodyIsTheHandFormattedLayout() async throws {
        let response = try await send("GET", "/", services: try makeServices())
        let expected = """
        {
          "name": "routes-test",
          "version": "9.9.9",
          "endpoints": [
            "GET /health",
            "GET /sessions"
          ]
        }
        """
        XCTAssertEqual(String(decoding: response.body, as: UTF8.self), expected)
    }

    func testHealthReportsReadinessMemoryAndStartup() async throws {
        let response = try await send("GET", "/health", services: try makeServices())
        XCTAssertEqual(response.status, 200)
        let body = try json(response)
        XCTAssertEqual(body["status"] as? String, "ok")
        XCTAssertEqual(body["version"] as? String, "9.9.9")
        XCTAssertEqual(body["startup_duration_ms"] as? Int, 42)
        XCTAssertEqual(body["memory_footprint_mb"] as? Int, 10)
        XCTAssertEqual(body["memory_peak_mb"] as? Int, 20)
    }

    // MARK: - Sessions and events

    func testListingSessionsOnAnEmptyDatabaseIsAnEmptyArray() async throws {
        let response = try await send("GET", "/sessions", services: try makeServices())
        XCTAssertEqual(response.status, 200)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: response.body) as? [Any])
        XCTAssertTrue(rows.isEmpty)
    }

    func testAnUnknownSessionIs404() async throws {
        let response = try await send("GET", "/sessions/nope", services: try makeServices())
        XCTAssertEqual(response.status, 404)
        XCTAssertEqual(try json(response)["error"] as? String, "Session not found: nope")
    }

    func testAnUnknownSessionHasNoMetrics() async throws {
        let response = try await send("GET", "/sessions/nope/metrics", services: try makeServices())
        XCTAssertEqual(response.status, 404)
        XCTAssertEqual(try json(response)["error"] as? String, "No metrics for session: nope")
    }

    func testANonNumericEventIdIs400() async throws {
        let response = try await send("GET", "/events/abc", services: try makeServices())
        XCTAssertEqual(response.status, 400)
        XCTAssertEqual(try json(response)["error"] as? String, "Invalid event id: abc")
    }

    func testAnUnknownEventIs404() async throws {
        let response = try await send("GET", "/events/999999", services: try makeServices())
        XCTAssertEqual(response.status, 404)
    }

    func testTheEventStreamIsLeftForTheTransport() async throws {
        let request = RouteRequest(method: "GET", path: "/events/stream")
        let claimed = await SessionFeatureRoutes.table(try makeServices()).handle(request)
        XCTAssertNil(claimed)
    }

    func testAnUnknownPathIsUnclaimed() async throws {
        let request = RouteRequest(method: "GET", path: "/nowhere")
        let claimed = await SessionFeatureRoutes.table(try makeServices()).handle(request)
        XCTAssertNil(claimed)
    }

    // MARK: - Ingestion

    func testSpoolStatusIs503WhenThereIsNoSpool() async throws {
        let response = try await send("GET", "/ingestion/spool", services: try makeServices(spool: nil))
        XCTAssertEqual(response.status, 503)
        XCTAssertEqual(try json(response)["status"] as? String, "unavailable")
    }

    func testIngestionErrorCountStartsAtZero() async throws {
        let response = try await send("GET", "/ingestion/errors/count", services: try makeServices())
        let body = try json(response)
        XCTAssertEqual(body["count"] as? Int, 0)
        XCTAssertEqual(body["exhausted"] as? Int, 0)
    }

    func testClearingIngestionErrorsIs204() async throws {
        let response = try await send("POST", "/ingestion/errors/clear", services: try makeServices())
        XCTAssertEqual(response.status, 204)
        XCTAssertTrue(response.body.isEmpty)
    }

    func testStartingARetryReplies202() async throws {
        let response = try await send("POST", "/ingestion/errors/retry", services: try makeServices())
        XCTAssertEqual(response.status, 202)
    }

    func testAnEmptyHookBodyIsAcceptedAndIgnored() async throws {
        let response = try await send("POST", "/hook/Stop", services: try makeServices())
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(String(decoding: response.body, as: UTF8.self), "{}")
        XCTAssertEqual(captured.count, 0)
    }

    func testAHookThatBuildsNoEventIsAcceptedAndIgnored() async throws {
        let response = try await send(
            "POST", "/hook/Stop", body: #"{"session_id":"s"}"#, services: try makeServices()
        )
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(captured.count, 0)
    }

    // MARK: - Import

    func testAMalformedImportBodyIs400() async throws {
        let response = try await send("POST", "/import", body: "not json", services: try makeServices())
        XCTAssertEqual(response.status, 400)
        XCTAssertTrue((try json(response)["error"] as? String ?? "").hasPrefix("Invalid import request body"))
    }

    func testAnImportFailureIs500() async throws {
        let response = try await send("POST", "/import", services: try makeServices())
        XCTAssertEqual(response.status, 500)
    }

    // MARK: - Preferences

    func testTrackingPreferenceRequiresABody() async throws {
        let response = try await send("POST", "/preferences/tracking", services: try makeServices())
        XCTAssertEqual(response.status, 400)
        XCTAssertEqual(try json(response)["error"] as? String, "Missing body: expected {\"enabled\": Bool}")
    }

    func testAMalformedAIPreferenceBodyIs400() async throws {
        let response = try await send("POST", "/preferences/ai", body: "{", services: try makeServices())
        XCTAssertEqual(response.status, 400)
    }

    func testSummaryPreferenceRoundTrips() async throws {
        let services = try makeServices()
        let set = try await send("POST", "/preferences/summaries", body: #"{"max_words": 33}"#, services: services)
        XCTAssertEqual(set.status, 200)
        let read = try await send("GET", "/preferences/summaries", services: services)
        XCTAssertEqual(try json(read)["max_words"] as? Int, 33)
    }

    // MARK: - Oversight, AI log, conversations

    func testOversightFindingCountStartsAtZero() async throws {
        let response = try await send("GET", "/oversight/findings/count", services: try makeServices())
        XCTAssertEqual(try json(response)["pending"] as? Int, 0)
    }

    func testAnOversightFindingIdMustBeNumeric() async throws {
        let response = try await send("POST", "/oversight/findings/x/act", services: try makeServices())
        XCTAssertEqual(response.status, 400)
        XCTAssertEqual(try json(response)["error"] as? String, "Invalid finding id")
    }

    func testAnUnknownOversightScriptIs404() async throws {
        let response = try await send("GET", "/oversight/scripts/missing", services: try makeServices())
        XCTAssertEqual(response.status, 404)
        XCTAssertEqual(try json(response)["error"] as? String, "Script not found")
    }

    func testSavingAnOversightScriptRequiresABody() async throws {
        let response = try await send("POST", "/oversight/scripts", services: try makeServices())
        XCTAssertEqual(response.status, 400)
    }

    func testAnUnknownAIInteractionIs404() async throws {
        let response = try await send("GET", "/ai/interactions/12345", services: try makeServices())
        XCTAssertEqual(response.status, 404)
        XCTAssertEqual(try json(response)["error"] as? String, "Interaction not found")
    }

    func testAnAIInteractionIdMustBeNumeric() async throws {
        let response = try await send("GET", "/ai/interactions/abc", services: try makeServices())
        XCTAssertEqual(response.status, 400)
    }

    func testConversationsOnAnEmptyDatabaseIsEmpty() async throws {
        let response = try await send("GET", "/conversations", services: try makeServices())
        XCTAssertEqual(response.status, 200)
    }

    // MARK: - Migration gating

    func testOnlySchemaFreePathsAreServableWhileMigrating() {
        XCTAssertTrue(SessionFeatureRoutes.isServableWhileMigrating([]))
        XCTAssertTrue(SessionFeatureRoutes.isServableWhileMigrating(["hook", "Stop"]))
        XCTAssertTrue(SessionFeatureRoutes.isServableWhileMigrating(["health"]))
        XCTAssertTrue(SessionFeatureRoutes.isServableWhileMigrating(["ingestion", "spool"]))
        XCTAssertFalse(SessionFeatureRoutes.isServableWhileMigrating(["sessions"]))
        XCTAssertFalse(SessionFeatureRoutes.isServableWhileMigrating(["ingestion", "errors"]))
        XCTAssertFalse(SessionFeatureRoutes.isServableWhileMigrating(["hook"]))
    }
}
