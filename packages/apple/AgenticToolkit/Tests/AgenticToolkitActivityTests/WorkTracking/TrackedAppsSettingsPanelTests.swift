#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitCore

@MainActor
private final class Counter {
    var rechecks = 0
    var statuses = 0
}

@MainActor
final class TrackedAppsSettingsPanelTests: XCTestCase {
    func testRowsAreDefaultsPlusAddedWithRemovedUnchecked() {
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["org.e.Editor"],
                                            removedBundleIds: ["com.apple.Terminal"], retentionDays: 90)
        let rows = TrackedAppsSettingsPanel.rows(preferences: prefs)
        XCTAssertEqual(rows.first { $0.app.bundleId == "com.apple.Terminal" }?.checked, false)
        XCTAssertEqual(rows.first { $0.app.bundleId == "org.e.Editor" }?.checked, true)
        XCTAssertEqual(rows.first { $0.app.bundleId == "com.apple.dt.Xcode" }?.checked, true)
    }

    func testTogglingADefaultOffAndOn() {
        let off = TrackedAppsSettingsPanel.toggling("com.apple.dt.Xcode", on: false, in: .default)
        XCTAssertEqual(off.removedBundleIds, ["com.apple.dt.Xcode"])
        XCTAssertEqual(TrackedAppsSettingsPanel.toggling("com.apple.dt.Xcode", on: true, in: off).removedBundleIds, [])
    }

    func testTogglingAnAddedAppOffRemovesIt() {
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["org.e.Editor"], removedBundleIds: [], retentionDays: 90)
        XCTAssertEqual(TrackedAppsSettingsPanel.toggling("org.e.Editor", on: false, in: prefs).addedBundleIds, [])
    }

    func testAddingDropsFromRemovedAndNeverDuplicates() {
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["org.e.Editor"],
                                            removedBundleIds: ["com.apple.Terminal"], retentionDays: 90)
        let again = TrackedAppsSettingsPanel.adding("org.e.Editor", to: prefs)
        XCTAssertEqual(again.addedBundleIds, ["org.e.Editor"])
        let terminal = TrackedAppsSettingsPanel.adding("com.apple.Terminal", to: prefs)
        XCTAssertEqual(terminal.removedBundleIds, [])
        XCTAssertEqual(terminal.addedBundleIds, ["org.e.Editor"])
    }

    func testAccessibilityTextHasThreeStates() {
        XCTAssertEqual(TrackedAppsSettingsPanel.accessibilityText(WorkTrackingStatus(accessibility: .granted)), "Granted")
        XCTAssertEqual(TrackedAppsSettingsPanel.accessibilityText(WorkTrackingStatus(accessibility: .denied)), "Not granted")
        XCTAssertEqual(TrackedAppsSettingsPanel.accessibilityText(nil), "Unknown — press Check Again")
    }

    func testAppearingNeverRechecksUnlessGrantWasPressed() async {
        let counter = Counter()
        let panel = TrackedAppsSettingsPanel(settings: WorkTrackingUserSettings(prefix: "test.\(UUID())"),
            status: { counter.statuses += 1; return WorkTrackingStatus() },
            recheck: { counter.rechecks += 1; return WorkTrackingStatus() },
            openAccessibilitySettings: {})
        panel.loadViewIfNeeded()
        await panel.refreshForTesting()
        XCTAssertEqual(counter.rechecks, 0); XCTAssertEqual(counter.statuses, 1)
        panel.grantPressedForTesting()
        await panel.refreshForTesting()
        XCTAssertEqual(counter.rechecks, 1)
        await panel.refreshForTesting()
        XCTAssertEqual(counter.rechecks, 1, "the recheck must not repeat on every appear")
        XCTAssertEqual(counter.statuses, 2)
    }
}
#endif
