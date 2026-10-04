import XCTest
@testable import AgenticToolkitActivity

final class ContextEventTests: XCTestCase {
    func testKindRawValuesMatchTheSchemaContract() {
        XCTAssertEqual(ContextEventKind.appFocus.rawValue, "app_focus")
        XCTAssertEqual(ContextEventKind.window.rawValue, "window")
        XCTAssertEqual(ContextEventKind.network.rawValue, "network")
        XCTAssertEqual(ContextEventKind.location.rawValue, "location")
        XCTAssertEqual(ContextEventKind.input.rawValue, "input")
        XCTAssertEqual(ContextEventKind.session.rawValue, "session")
        XCTAssertEqual(ContextEventKind.power.rawValue, "power")
        XCTAssertEqual(ContextEventKind.appLifecycle.rawValue, "app_lifecycle")
        XCTAssertEqual(ContextEventKind.allCases.count, 8)
    }

    func testEveryDetailReportsItsOwnKind() {
        // One assertion per case, so a new kind added without a matching
        // `detail.kind` arm fails here rather than silently writing the
        // wrong `kind` column.
        let pairs: [(ContextEventDetail, ContextEventKind)] = [
            (.appFocus(AppFocusDetail(bundleID: "a", appName: "A", pid: 1, executablePath: nil,
                                      windowID: nil, windowTitle: nil, documentPath: nil,
                                      documentSize: nil, documentModifiedAt: nil, documentType: nil)), .appFocus),
            (.window(WindowDetail(change: .created, bundleID: "a", appName: "A", pid: 1,
                                  windowID: 7, windowTitle: nil)), .window),
            (.network(NetworkDetail(interfaceType: .wifi, isSatisfied: true, ssid: nil, bssid: nil,
                                    isExpensive: nil, isConstrained: nil)), .network),
            (.location(LocationDetail(latitude: 1, longitude: 2, horizontalAccuracy: nil, altitude: nil,
                                      verticalAccuracy: nil, speed: nil, course: nil)), .location),
            (.input(InputDetail(change: .sample,
                                secondsSinceKey: nil, secondsSinceMouseMove: nil, secondsSinceClick: nil,
                                secondsSinceScroll: nil, keyCountDelta: nil, mouseCountDelta: nil,
                                intervalMs: nil)), .input),
            (.session(SessionDetail(change: .lock)), .session),
            (.power(PowerDetail(source: .battery, percent: nil, isCharging: nil)), .power),
            (.appLifecycle(AppLifecycleDetail(change: .terminated, bundleID: "com.apple.dt.Xcode",
                                              appName: "Xcode", pid: 501)), .appLifecycle),
        ]
        for (detail, expected) in pairs {
            XCTAssertEqual(detail.kind, expected)
        }
        XCTAssertEqual(Set(pairs.map(\.1)), Set(ContextEventKind.allCases),
                       "every kind must be exercised")
    }

    func testEventDerivesItsKindFromItsDetail() {
        let e = ContextEvent(id: UUID(), machineID: UUID(), occurredAt: Date(),
                             detail: .session(SessionDetail(change: .wake)))
        XCTAssertEqual(e.kind, .session)
    }

    func testSupportingEnumRawValuesMatchTheSchemaContract() {
        XCTAssertEqual(WindowChange.created.rawValue, "created")
        XCTAssertEqual(WindowChange.destroyed.rawValue, "destroyed")
        XCTAssertEqual(WindowChange.titleChanged.rawValue, "title_changed")
        XCTAssertEqual(WindowChange.allCases.count, 3)

        XCTAssertEqual(NetworkInterfaceType.wifi.rawValue, "wifi")
        XCTAssertEqual(NetworkInterfaceType.ethernet.rawValue, "ethernet")
        XCTAssertEqual(NetworkInterfaceType.cellular.rawValue, "cellular")
        XCTAssertEqual(NetworkInterfaceType.other.rawValue, "other")
        XCTAssertEqual(NetworkInterfaceType.none.rawValue, "none")
        XCTAssertEqual(NetworkInterfaceType.allCases.count, 5)

        XCTAssertEqual(SessionChange.idle.rawValue, "idle")
        XCTAssertEqual(SessionChange.active.rawValue, "active")
        XCTAssertEqual(SessionChange.lock.rawValue, "lock")
        XCTAssertEqual(SessionChange.unlock.rawValue, "unlock")
        XCTAssertEqual(SessionChange.sleep.rawValue, "sleep")
        XCTAssertEqual(SessionChange.wake.rawValue, "wake")
        XCTAssertEqual(SessionChange.allCases.count, 6)

        XCTAssertEqual(PowerSourceKind.ac.rawValue, "ac")
        XCTAssertEqual(PowerSourceKind.battery.rawValue, "battery")
        XCTAssertEqual(PowerSourceKind.allCases.count, 2)
    }
}
