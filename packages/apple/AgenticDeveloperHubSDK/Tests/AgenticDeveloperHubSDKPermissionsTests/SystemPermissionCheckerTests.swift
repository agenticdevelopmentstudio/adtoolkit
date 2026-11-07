import CoreLocation
import Foundation
import Testing
import UserNotifications
@testable import AgenticDeveloperHubSDKPermissions

/// Records the last probe call and returns a configured status.
private final class ProbeRecorder: @unchecked Sendable {
    var lastBundleID: String?
    var lastPromptIfNeeded: Bool?
}

private struct StubAutomationProbe: AutomationProbing {
    let status: OSStatus
    let recorder: ProbeRecorder

    func permissionStatus(forBundleID bundleID: String, promptIfNeeded: Bool) -> OSStatus {
        recorder.lastBundleID = bundleID
        recorder.lastPromptIfNeeded = promptIfNeeded
        return status
    }
}

@Suite("Automation permission mapping")
struct AutomationMappingTests {
    private func checker(_ status: OSStatus, _ recorder: ProbeRecorder = ProbeRecorder()) -> SystemPermissionChecker {
        SystemPermissionChecker(automationProbe: StubAutomationProbe(status: status, recorder: recorder))
    }

    @Test("noErr maps to granted")
    func granted() async {
        #expect(await checker(noErr).status(.automation(targetBundleID: "com.googlecode.iterm2")) == .granted)
    }

    @Test("errAEEventNotPermitted (-1743) maps to denied")
    func denied() async {
        #expect(await checker(-1743).status(.automation(targetBundleID: "com.googlecode.iterm2")) == .denied)
    }

    @Test("consent-required (-1744) and target-not-running (-600) map to undetermined, not denied")
    func undetermined() async {
        #expect(await checker(-1744).status(.automation(targetBundleID: "x")) == .undetermined)
        #expect(await checker(-600).status(.automation(targetBundleID: "x")) == .undetermined)
    }

    @Test("automationStatus maps OSStatus values to the tri-state")
    func mapping() {
        #expect(SystemPermissionChecker.automationStatus(noErr) == .granted)
        #expect(SystemPermissionChecker.automationStatus(-1743) == .denied)
        #expect(SystemPermissionChecker.automationStatus(-1744) == .undetermined)
        #expect(SystemPermissionChecker.automationStatus(-600) == .undetermined)
    }

    @Test("notificationStatus: notDetermined is undetermined, not denied")
    func notificationMapping() {
        #expect(SystemPermissionChecker.notificationStatus(.authorized) == .granted)
        #expect(SystemPermissionChecker.notificationStatus(.denied) == .denied)
        #expect(SystemPermissionChecker.notificationStatus(.notDetermined) == .undetermined)
    }

    @Test("locationStatus: only authorizedAlways is granted, everything else is not")
    func locationMapping() {
        #expect(SystemPermissionChecker.locationStatus(.authorizedAlways) == .granted)
        // `CLAuthorizationStatus.authorizedWhenInUse` is declared
        // `API_UNAVAILABLE(macos)` — it cannot be written by name in code that
        // targets macOS, even inside a switch pattern's sibling expression
        // context, so it cannot appear here as `.authorizedWhenInUse`. It is
        // still a real wire value CoreLocation can hand back (macOS just never
        // originates it itself), and `locationStatus`'s own switch matches it
        // by raw value, so rawValue 4 — its documented raw value — exercises
        // the identical arm. "While Using the App" reading as granted would let
        // a location trigger start even though the OS will not serve it once
        // olylod's daemon is running with no app in the foreground — this is
        // the arm most worth pinning.
        let authorizedWhenInUse = CLAuthorizationStatus(rawValue: 4)!
        #expect(SystemPermissionChecker.locationStatus(authorizedWhenInUse) == .denied)
        #expect(SystemPermissionChecker.locationStatus(.denied) == .denied)
        #expect(SystemPermissionChecker.locationStatus(.restricted) == .denied)
        #expect(SystemPermissionChecker.locationStatus(.notDetermined) == .undetermined)
    }

    @Test("isGranted convenience is true only for .granted")
    func isGrantedConvenience() async {
        #expect(await checker(noErr).isGranted(.automation(targetBundleID: "x")) == true)
        #expect(await checker(-1743).isGranted(.automation(targetBundleID: "x")) == false)
        #expect(await checker(-600).isGranted(.automation(targetBundleID: "x")) == false)
    }

    @Test("status does not prompt, request does; bundle id is forwarded")
    func promptFlag() async {
        let recorder = ProbeRecorder()
        let checker = checker(noErr, recorder)

        _ = await checker.status(.automation(targetBundleID: "com.googlecode.iterm2"))
        #expect(recorder.lastBundleID == "com.googlecode.iterm2")
        #expect(recorder.lastPromptIfNeeded == false)

        _ = await checker.request(.automation(targetBundleID: "com.googlecode.iterm2"))
        #expect(recorder.lastPromptIfNeeded == true)
    }
}

@Suite("Full Disk Access status file")
struct FullDiskAccessStatusTests {
    private func status(writing contents: String?) async throws -> PermissionStatus {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("fda-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("notifyd-access.json")
        if let contents { try contents.write(to: file, atomically: true, encoding: .utf8) }
        return await SystemPermissionChecker().status(.fullDiskAccess(statusFilePath: file.path))
    }

    @Test("testFullDiskAccessStatusFromFile: granted, denied, missing, garbage")
    func testFullDiskAccessStatusFromFile() async throws {
        #expect(try await status(writing: #"{"granted":true,"checkedAt":"2026-11-07T10:00:00Z"}"#) == .granted)
        #expect(try await status(writing: #"{"granted":false,"checkedAt":"2026-11-07T10:00:00Z"}"#) == .denied)
        #expect(try await status(writing: nil) == .undetermined)
        #expect(try await status(writing: "not json") == .undetermined)
        #expect(try await status(writing: #"{"granted":"yes"}"#) == .undetermined)
    }
}
