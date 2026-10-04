#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitCore

@MainActor
private final class StatusBox { var current: WorkTrackingStatus? }

@MainActor
private final class Counter {
    var rechecks = 0
    var statuses = 0
}

/// A fake whose calls each wait until the test completes them by hand.
@MainActor
private final class Gate {
    private var waiting: [CheckedContinuation<WorkTrackingStatus?, Never>] = []
    var pending: Int { waiting.count }
    func call() async -> WorkTrackingStatus? {
        await withCheckedContinuation { waiting.append($0) }
    }
    func complete(_ index: Int, with status: WorkTrackingStatus?) { waiting[index].resume(returning: status) }
    func waitForCalls(_ n: Int) async {
        while waiting.count < n { await Task.yield() }
    }
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

    private func makePanel(status: @escaping @MainActor () async -> WorkTrackingStatus? = { nil },
                           recheck: @escaping @MainActor () async -> WorkTrackingStatus? = { nil },
                           chooseApp: @escaping @MainActor () -> (bundleId: String, name: String)? = { nil },
                           settings: WorkTrackingUserSettings? = nil) -> TrackedAppsSettingsPanel {
        let panel = TrackedAppsSettingsPanel(
            settings: settings ?? WorkTrackingUserSettings(prefix: "test.\(UUID())"),
            status: status, recheck: recheck, openAccessibilitySettings: {}, chooseApp: chooseApp)
        panel.loadViewIfNeeded()
        return panel
    }

    func testCheckAgainSatisfiesAPendingGrantRecheck() async {
        let counter = Counter()
        let panel = makePanel(status: { counter.statuses += 1; return WorkTrackingStatus() },
                              recheck: { counter.rechecks += 1; return WorkTrackingStatus() })
        panel.grantPressedForTesting()
        await panel.checkAgainForTesting()
        XCTAssertEqual(counter.rechecks, 1)
        await panel.refreshForTesting()
        XCTAssertEqual(counter.rechecks, 1, "appear must not repeat a recheck the user already did")
        XCTAssertEqual(counter.statuses, 1)
    }

    func testOlderSlowRefreshDoesNotOverwriteNewer() async {
        let gate = Gate()
        let panel = makePanel(status: { await gate.call() })
        let older = Task { @MainActor in await panel.refreshForTesting() }
        await gate.waitForCalls(1)
        let newer = Task { @MainActor in await panel.refreshForTesting() }
        await gate.waitForCalls(2)
        gate.complete(1, with: WorkTrackingStatus(accessibility: .granted))
        await newer.value
        gate.complete(0, with: WorkTrackingStatus(accessibility: .denied))
        await older.value
        XCTAssertEqual(panel.accessibilityLineTextForTesting, "Granted")
    }

    func testFailureTextHiddenAtZeroAndExactOtherwise() {
        XCTAssertNil(TrackedAppsSettingsPanel.failureText(nil))
        XCTAssertNil(TrackedAppsSettingsPanel.failureText(WorkTrackingStatus(writeFailures: 0, lastError: "x")))
        XCTAssertEqual(TrackedAppsSettingsPanel.failureText(WorkTrackingStatus(writeFailures: 3, lastError: "disk full")),
                       "3 writes failed — last: disk full")
    }

    func testDegradedAndFailureLinesFollowStatus() async {
        let box = StatusBox()
        box.current = WorkTrackingStatus(enabled: true, accessibility: .denied, writeFailures: 2, lastError: "boom")
        let panel = makePanel(status: { box.current })
        await panel.refreshForTesting()
        XCTAssertFalse(panel.degradedLineHiddenForTesting)
        XCTAssertFalse(panel.failureLineHiddenForTesting)
        XCTAssertEqual(panel.failureLineTextForTesting, "2 writes failed — last: boom")
        box.current = WorkTrackingStatus(enabled: true, accessibility: .granted)
        await panel.refreshForTesting()
        XCTAssertTrue(panel.degradedLineHiddenForTesting)
        XCTAssertTrue(panel.failureLineHiddenForTesting)
        XCTAssertEqual(panel.accessibilityLineTextForTesting, "Granted")
    }

    func testCheckAgainShowsCheckingAndDisablesButtonUntilDone() async {
        let gate = Gate()
        let panel = makePanel(recheck: { await gate.call() })
        let task = Task { @MainActor in await panel.checkAgainForTesting() }
        await gate.waitForCalls(1)
        XCTAssertEqual(panel.accessibilityLineTextForTesting, "Checking…")
        XCTAssertFalse(panel.checkAgainEnabledForTesting)
        gate.complete(0, with: WorkTrackingStatus(accessibility: .granted))
        await task.value
        XCTAssertEqual(panel.accessibilityLineTextForTesting, "Granted")
        XCTAssertTrue(panel.checkAgainEnabledForTesting)
    }

    func testFooterRemoveOnlyForAddedApps() {
        XCTAssertTrue(TrackedAppsSettingsPanel.isAddedApp("org.e.Editor"))
        XCTAssertFalse(TrackedAppsSettingsPanel.isAddedApp("com.apple.dt.Xcode"))
        let panel = makePanel()
        let card = panel.appsCardForTesting
        XCTAssertEqual(card?.canRemoveRow?("org.e.Editor"), true)
        XCTAssertEqual(card?.canRemoveRow?("com.apple.dt.Xcode"), false)
    }

    func testCardWiringWritesSettings() {
        let settings = WorkTrackingUserSettings(prefix: "test.\(UUID())")
        let panel = makePanel(chooseApp: { (bundleId: "org.e.Editor", name: "Editor") }, settings: settings)
        let card = panel.appsCardForTesting
        card?.onAdd?()
        XCTAssertEqual(settings.addedBundleIds.value, ["org.e.Editor"])
        card?.onToggle?("com.apple.Terminal", "track", false)
        XCTAssertEqual(settings.removedBundleIds.value, ["com.apple.Terminal"])
        card?.onToggle?("com.apple.Terminal", "track", true)
        XCTAssertEqual(settings.removedBundleIds.value, [])
        card?.onToggle?("org.e.Editor", "track", false)
        XCTAssertEqual(settings.addedBundleIds.value, [])
    }
}
#endif
