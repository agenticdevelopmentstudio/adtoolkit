import XCTest
@testable import AgenticToolkitActivity

final class MachineDescriptorTests: XCTestCase {
    func testPlatformRawValuesMatchTheSchemaContract() {
        // The schema stores these strings verbatim; they are the
        // cross-platform contract and must not drift with Swift casing.
        XCTAssertEqual(MachinePlatform.macOS.rawValue, "macos")
        XCTAssertEqual(MachinePlatform.iOS.rawValue, "ios")
        XCTAssertEqual(MachinePlatform.android.rawValue, "android")
        XCTAssertEqual(MachinePlatform.windows.rawValue, "windows")
    }

    func testNativeIDKindRawValuesMatchTheSchemaContract() {
        XCTAssertEqual(MachineNativeIDKind.ioPlatformUUID.rawValue, "ioplatformuuid")
        XCTAssertEqual(MachineNativeIDKind.idfv.rawValue, "idfv")
        XCTAssertEqual(MachineNativeIDKind.androidID.rawValue, "android_id")
        XCTAssertEqual(MachineNativeIDKind.machineGUID.rawValue, "machineguid")
    }

    func testDescriptorCarriesEveryFieldItWasGiven() {
        let id = UUID()
        let d = MachineDescriptor(id: id, platform: .macOS, nativeID: "ABC-123",
                                  nativeIDKind: .ioPlatformUUID, hostname: "mac.local",
                                  model: "Mac16,7", osVersion: "26.0")
        XCTAssertEqual(d.id, id)
        XCTAssertEqual(d.platform, .macOS)
        XCTAssertEqual(d.nativeID, "ABC-123")
        XCTAssertEqual(d.nativeIDKind, .ioPlatformUUID)
        XCTAssertEqual(d.hostname, "mac.local")
        XCTAssertEqual(d.model, "Mac16,7")
        XCTAssertEqual(d.osVersion, "26.0")
    }

    #if os(macOS)
    func testSystemProviderReportsMacOSAndAnIOPlatformUUID() {
        let id = UUID()
        let m = SystemMachineIdentityProvider(id: id).currentMachine()
        XCTAssertEqual(m.id, id)
        XCTAssertEqual(m.platform, .macOS)
        XCTAssertEqual(m.nativeIDKind, .ioPlatformUUID)
        // IOPlatformUUID is a formatted UUID string on every shipping Mac.
        XCTAssertNotNil(m.nativeID.flatMap(UUID.init(uuidString:)),
                        "IOPlatformUUID should parse as a UUID, got \(String(describing: m.nativeID))")
        XCTAssertFalse(m.osVersion?.isEmpty ?? true)
        XCTAssertFalse(m.model?.isEmpty ?? true)
    }
    #endif
}
