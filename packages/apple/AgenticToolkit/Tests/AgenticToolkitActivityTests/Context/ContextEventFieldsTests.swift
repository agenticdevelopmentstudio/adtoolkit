import XCTest
@testable import AgenticToolkitActivity

/// The preview pane's data. Unlike `summary`, this drops nothing: a field
/// whose value is absent is shown as empty rather than omitted, so the pane
/// tells the truth about which fields an event *has*.
final class ContextEventFieldsTests: XCTestCase {

    private func value(_ fields: [ContextEventField], _ label: String) -> String? {
        fields.first { $0.label == label }?.value
    }

    func testEveryKindProducesFields() {
        let details: [ContextEventDetail] = [
            .appFocus(AppFocusDetail(bundleID: "", appName: "", pid: 0, executablePath: nil,
                                     windowID: nil, windowTitle: nil, documentPath: nil,
                                     documentSize: nil, documentModifiedAt: nil, documentType: nil)),
            .window(WindowDetail(change: .created, bundleID: "", appName: "", pid: 0,
                                 windowID: 0, windowTitle: nil)),
            .network(NetworkDetail(interfaceType: .none, isSatisfied: false, ssid: nil,
                                   bssid: nil, isExpensive: nil, isConstrained: nil)),
            .location(LocationDetail(latitude: 0, longitude: 0, horizontalAccuracy: nil,
                                     altitude: nil, verticalAccuracy: nil, speed: nil, course: nil)),
            .input(InputDetail(change: .sample, secondsSinceKey: nil, secondsSinceMouseMove: nil,
                               secondsSinceClick: nil, secondsSinceScroll: nil,
                               keyCountDelta: nil, mouseCountDelta: nil, intervalMs: nil)),
            .session(SessionDetail(change: .idle)),
            .power(PowerDetail(source: .ac, percent: nil, isCharging: nil)),
            .appLifecycle(AppLifecycleDetail(change: .launched, bundleID: "",
                                             appName: "", pid: 0))
        ]

        XCTAssertEqual(Set(details.map(\.kind)), Set(ContextEventKind.allCases),
                       "every kind must be covered by this test — by kind, not by count, "
                       + "which a duplicated fixture satisfies while leaving a kind untested")
        for detail in details {
            XCTAssertFalse(detail.fields.isEmpty,
                           "\(detail.kind.rawValue) produced no fields")
        }
    }

    func testAbsentValuesAreShownAsEmptyRatherThanOmitted() {
        let detail = ContextEventDetail.appFocus(AppFocusDetail(
            bundleID: "com.example.app", appName: "App", pid: 3, executablePath: nil,
            windowID: nil, windowTitle: nil, documentPath: nil, documentSize: nil,
            documentModifiedAt: nil, documentType: nil))

        XCTAssertEqual(value(detail.fields, "Window title"), ContextEventField.empty,
                       "the pane must show that the field exists and is empty")
        XCTAssertEqual(value(detail.fields, "App name"), "App")
        XCTAssertEqual(value(detail.fields, "Bundle id"), "com.example.app")
    }

    func testNumbersUseAPOSIXLocale() {
        let detail = ContextEventDetail.location(LocationDetail(
            latitude: 12.5, longitude: -0.25, horizontalAccuracy: nil, altitude: nil,
            verticalAccuracy: nil, speed: nil, course: nil))

        XCTAssertEqual(value(detail.fields, "Latitude"), "12.500000",
                       "coordinates are read next to raw database values; 12,5 would not round-trip")
    }

    func testAppLifecycleShowsItsChangeAndIdentity() {
        let detail = ContextEventDetail.appLifecycle(AppLifecycleDetail(
            change: .terminated, bundleID: "com.apple.dt.Xcode", appName: "Xcode", pid: 501))

        XCTAssertEqual(value(detail.fields, "Change"), "terminated")
        XCTAssertEqual(value(detail.fields, "App name"), "Xcode")
        XCTAssertEqual(value(detail.fields, "Bundle id"), "com.apple.dt.Xcode")
        XCTAssertEqual(value(detail.fields, "Process id"), "501")
    }

    func testARecordLeadsWithItsHeaderFields() {
        let record = ContextEventRecord(
            sequence: 17,
            event: ContextEvent(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
                                machineID: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
                                occurredAt: Date(timeIntervalSince1970: 1_000),
                                detail: .session(SessionDetail(change: .lock))))

        XCTAssertEqual(record.fields.prefix(5).map(\.label),
                       ["Sequence", "Event id", "Machine id", "Occurred", "Kind"])
        XCTAssertEqual(value(record.fields, "Sequence"), "17")
        XCTAssertEqual(value(record.fields, "Kind"), "Session")
        XCTAssertEqual(value(record.fields, "Change"), "lock",
                       "the detail's own fields follow the header's")
    }
}
