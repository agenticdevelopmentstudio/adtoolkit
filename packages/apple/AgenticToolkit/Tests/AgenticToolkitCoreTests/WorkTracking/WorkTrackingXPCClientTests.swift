import XCTest
@testable import AgenticToolkitCore

final class WorkTrackingXPCClientTests: XCTestCase {

    final class ScriptedTransport: WorkTrackingXPCTransport, @unchecked Sendable {
        var data = Data()
        var rows: [Data] = []
        private(set) var calls: [(timeout: TimeInterval??, retries: Int)] = []
        private(set) var sentBodies: [Data] = []

        /// Records the call and captures the body a set-preferences invoke sends.
        func callData(
            timeout: TimeInterval??, retries: Int,
            _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable (Data) -> Void) -> Void
        ) async throws -> Data {
            calls.append((timeout, retries))
            let recorder = RecordingProxy()
            invoke(recorder) { _ in }
            if let body = recorder.body { sentBodies.append(body) }
            return data
        }

        func callDecodingArray<T: Decodable>(
            _ type: T.Type, timeout: TimeInterval??, retries: Int,
            _ invoke: @escaping @Sendable (Proxy, @escaping @Sendable ([Data]) -> Void) -> Void
        ) async throws -> [T] {
            calls.append((timeout, retries))
            let decoder = WorkTrackingXPCClient<ScriptedTransport>.makeReplyDecoder()
            return try rows.map { try decoder.decode(T.self, from: $0) }
        }
    }

    final class RecordingProxy: NSObject, WorkTrackingXPCProtocol, @unchecked Sendable {
        var body: Data?
        func workTrackingSetPreferences(_ body: Data, reply: @escaping (Data) -> Void) { self.body = body }
        func workTrackingStatus(reply: @escaping (Data) -> Void) {}
        func workTrackingRecheckPermissions(reply: @escaping (Data) -> Void) {}
        func workTrackingSpans(since: String?, limit: Int, reply: @escaping ([Data]) -> Void) {}
    }

    private let transport = ScriptedTransport()
    private lazy var client = WorkTrackingXPCClient(transport: transport)

    private func wire(_ value: some Encodable) -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return (try? encoder.encode(value)) ?? Data()
    }

    func testStatusDecodesSnakeCase() async {
        let literal = """
        {"enabled":true,"accessibility":"granted","write_failures":2,"last_error":"x",
         "current_span":{"id":"s1","bundle_id":"com.x","app_name":"X","window_title":"w",
         "working_path":"/p","repo_root":"/p","branch":"main","started_at":"2026-10-03T10:00:00Z",
         "ended_at":"","tz":"UTC","last_seen_at":"2026-10-03T10:00:05Z"}}
        """
        transport.data = Data(literal.utf8)
        let status = await client.status()
        XCTAssertEqual(status?.enabled, true)
        XCTAssertEqual(status?.accessibility, .granted)
        XCTAssertEqual(status?.writeFailures, 2)
        XCTAssertEqual(status?.lastError, "x")
        XCTAssertEqual(status?.currentSpan?.bundleId, "com.x")
        XCTAssertEqual(status?.currentSpan?.lastSeenAt, "2026-10-03T10:00:05Z")
    }

    func testEmptyReplyIsNil() async {
        transport.data = Data()
        let status = await client.status()
        let rechecked = await client.recheckPermissions()
        XCTAssertNil(status)
        XCTAssertNil(rechecked)
        transport.data = Data("not json".utf8)
        let unreadable = await client.status()
        XCTAssertNil(unreadable)
    }

    func testSetPreferencesSendsSnakeCaseBody() async throws {
        transport.data = wire(WorkTrackingStatus(enabled: true))
        let prefs = WorkTrackingPreferences(
            enabled: true, addedBundleIds: ["com.a"], removedBundleIds: ["com.b"], retentionDays: 30)
        let status = await client.setPreferences(prefs)
        XCTAssertEqual(status?.enabled, true)
        let body = try XCTUnwrap(transport.sentBodies.last)
        let text = String(bytes: body, encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("added_bundle_ids"))
        let decoded = try WorkTrackingXPCClient<ScriptedTransport>.makeReplyDecoder()
            .decode(WorkTrackingPreferences.self, from: body)
        XCTAssertEqual(decoded, prefs)
        XCTAssertEqual(transport.calls.last?.timeout, .some(.some(5)))
        XCTAssertEqual(transport.calls.last?.retries, 0)
    }

    func testSpansDecodeNewestFirstAsSent() async {
        func literal(_ id: String, _ start: String) -> Data {
            Data("""
            {"id":"\(id)","bundle_id":"com.x","app_name":"X","window_title":"w","working_path":"/p",
             "repo_root":"/p","branch":"main","started_at":"\(start)","ended_at":"","tz":"UTC","last_seen_at":""}
            """.utf8)
        }
        transport.rows = [literal("b", "2026-10-03T10:00:00Z"), literal("a", "2026-10-03T09:00:00Z")]
        let spans = await client.spans(since: nil, limit: 10)
        XCTAssertEqual(spans?.map(\.id), ["b", "a"])
        XCTAssertEqual(spans?.first?.bundleId, "com.x")
        XCTAssertEqual(spans?.first?.startedAt, "2026-10-03T10:00:00Z")
    }

    @MainActor
    func testUserSettingsSnapshotIsNormalized() {
        let prefix = "wt_test_\(UUID().uuidString)_"
        let settings = WorkTrackingUserSettings(prefix: prefix)
        defer {
            settings.enabled.remove()
            settings.addedBundleIds.remove()
            settings.removedBundleIds.remove()
            settings.retentionDays.remove()
        }
        settings.enabled.value = true
        settings.addedBundleIds.value = ["com.b", "com.a", "com.b"]
        settings.removedBundleIds.value = ["com.z", "com.z"]
        settings.retentionDays.value = 1
        XCTAssertEqual(settings.preferences, WorkTrackingPreferences(
            enabled: true, addedBundleIds: ["com.a", "com.b"], removedBundleIds: ["com.z"], retentionDays: 7))
    }
}
