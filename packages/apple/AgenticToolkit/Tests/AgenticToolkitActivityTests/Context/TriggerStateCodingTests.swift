import XCTest
@testable import AgenticToolkitActivity

final class TriggerStateCodingTests: XCTestCase {
    func testRoundTripsThroughJSON() throws {
        let states = ContextEventKind.allCases.map {
            TriggerState(kind: $0, isEnabled: $0 == .location,
                         permission: $0 == .location ? .location : .none,
                         permissionState: .granted, isRunning: false)
        }
        let data = try JSONEncoder().encode(states)
        let decoded = try JSONDecoder().decode([TriggerState].self, from: data)
        XCTAssertEqual(decoded, states)
    }

    func testEncodesKindsAsTheirSchemaStrings() throws {
        let data = try JSONEncoder().encode([
            TriggerState(kind: .appFocus, isEnabled: true, permission: .accessibility,
                         permissionState: .denied, isRunning: false)])
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"app_focus\""), "got \(json)")
        XCTAssertTrue(json.contains("\"accessibility\""), "got \(json)")
        XCTAssertTrue(json.contains("\"denied\""), "got \(json)")
    }

    func testDecodingAnUnknownKindFailsRatherThanSilentlyDroppingIt() throws {
        // The positive control comes first and is not optional. Every key name
        // below is hardcoded, so renaming any one of them would make the
        // unknown-kind decode throw for the wrong reason and leave this test
        // green while proving nothing. The control fails loudly instead.
        let known = Data(#"[{"kind":"app_focus","isEnabled":true,"permission":"none","permissionState":"granted","isRunning":true}]"#.utf8)
        let decoded = try JSONDecoder().decode([TriggerState].self, from: known)
        XCTAssertEqual(decoded, [TriggerState(kind: .appFocus, isEnabled: true, permission: .none,
                                              permissionState: .granted, isRunning: true)])

        let unknown = Data(#"[{"kind":"telepathy","isEnabled":true,"permission":"none","permissionState":"granted","isRunning":true}]"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode([TriggerState].self, from: unknown))
    }
}
