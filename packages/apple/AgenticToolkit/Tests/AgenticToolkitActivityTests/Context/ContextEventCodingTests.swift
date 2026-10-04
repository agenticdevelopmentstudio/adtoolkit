import XCTest
@testable import AgenticToolkitActivity

/// The wire format the daemon serializes a page of the log into and the app
/// decodes. The tag is asserted literally because it is a contract between
/// two separately-built binaries, not an implementation detail.
final class ContextEventCodingTests: XCTestCase {

    private func roundTrip(_ detail: ContextEventDetail) throws -> ContextEventDetail {
        let data = try JSONEncoder().encode(detail)
        return try JSONDecoder().decode(ContextEventDetail.self, from: data)
    }

    func testEveryDetailKindRoundTrips() throws {
        let details: [ContextEventDetail] = [
            .appFocus(AppFocusDetail(bundleID: "b", appName: "a", pid: 1, executablePath: "/x",
                                     windowID: 2, windowTitle: "t", documentPath: "/d",
                                     documentSize: 3, documentModifiedAt: Date(timeIntervalSince1970: 4),
                                     documentType: "txt")),
            .window(WindowDetail(change: .titleChanged, bundleID: "b", appName: "a", pid: 1,
                                 windowID: 2, windowTitle: nil)),
            .network(NetworkDetail(interfaceType: .wifi, isSatisfied: true, ssid: "s",
                                   bssid: nil, isExpensive: true, isConstrained: false)),
            .location(LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: 3,
                                     altitude: 4, verticalAccuracy: 5, speed: 6, course: 7)),
            .input(InputDetail(change: .inactive, secondsSinceKey: 1, secondsSinceMouseMove: nil,
                               secondsSinceClick: 3, secondsSinceScroll: nil,
                               keyCountDelta: 5, mouseCountDelta: 6, intervalMs: 7)),
            .session(SessionDetail(change: .sleep)),
            .power(PowerDetail(source: .battery, percent: 10, isCharging: nil)),
            .appLifecycle(AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                                             appName: "Xcode", pid: 501))
        ]
        XCTAssertEqual(Set(details.map(\.kind)), Set(ContextEventKind.allCases),
                       "one fixture per kind — a count only proves there are eight of "
                       + "something, so a duplicated fixture would leave a kind untested "
                       + "here and still pass")

        for detail in details {
            XCTAssertEqual(try roundTrip(detail), detail, "\(detail.kind) did not round trip")
        }
    }

    func testTheWireTagIsTheSchemaKindName() throws {
        let data = try JSONEncoder().encode(ContextEventDetail.appFocus(
            AppFocusDetail(bundleID: "b", appName: "a", pid: 1, executablePath: nil,
                           windowID: nil, windowTitle: nil, documentPath: nil,
                           documentSize: nil, documentModifiedAt: nil, documentType: nil)))
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["kind"] as? String, "app_focus",
                       "the tag is the schema's kind name, not a compiler-chosen spelling")
        XCTAssertNotNil(json["payload"])
    }

    func testAnUnknownKindTagFailsToDecode() throws {
        let json = Data(#"{"kind":"telepathy","payload":{}}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(ContextEventDetail.self, from: json))
    }

    func testRecordRoundTripsWithItsSequence() throws {
        let record = ContextEventRecord(
            sequence: 4_096,
            event: ContextEvent(machineID: UUID(), occurredAt: Date(timeIntervalSince1970: 1_700),
                                detail: .session(SessionDetail(change: .lock))))
        let data = try JSONEncoder().encode([record])
        let decoded = try JSONDecoder().decode([ContextEventRecord].self, from: data)

        XCTAssertEqual(decoded, [record])
    }

    func testQueryRoundTrips() throws {
        let query = ContextEventQuery(kinds: [.input, .power], afterSequence: 12, limit: 40)
        let decoded = try JSONDecoder().decode(
            ContextEventQuery.self, from: try JSONEncoder().encode(query))

        XCTAssertEqual(decoded, query)
    }
}
