@testable import AgenticToolkitMacOS
import XCTest

@MainActor
final class AppUpdatesFeatureTests: XCTestCase {
    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    /// Every feature registers itself in the shared registry; leave it as found.
    private var made: [AppUpdatesFeature] = []

    override func tearDown() async throws {
        made.forEach { $0.unregister() }
        made = []
    }

    private func makeFeature(
        canCheck: @escaping () -> Bool = { true },
        automatic: Box<Bool> = Box(false),
        onCheck: @escaping () -> Void = {}
    ) -> AppUpdatesFeature {
        let feature = AppUpdatesFeature(
            checkForUpdates: onCheck,
            canCheckForUpdates: canCheck,
            installsUpdatesAutomatically: { automatic.value },
            setInstallsUpdatesAutomatically: { automatic.value = $0 })
        made.append(feature)
        return feature
    }

    /// No updater is no feature: the item is absent from the menu, not greyed.
    func testNoUpdaterMeansNoFeature() {
        XCTAssertNil(AppUpdatesFeature(updater: nil))
    }

    func testContributesCheckItemToAppAndStatusMenus() {
        var checks = 0
        let feature = makeFeature(onCheck: { checks += 1 })
        let contributions = feature.menuContributions

        let app = contributions.filter { $0.slot == .app }
        XCTAssertEqual(app.map(\.title), ["Check for Updates…"])
        let status = contributions.filter { $0.slot == .statusItem(section: 2) }
        XCTAssertEqual(status.map(\.title), ["Check for Updates…", "Install Updates Automatically"])
        XCTAssertEqual(status.map(\.identifier), [nil, "install-automatically"])

        app[0].action()
        status[0].action()
        XCTAssertEqual(checks, 2)
    }

    func testCheckItemIsDisabledWhileSparkleCannotCheck() throws {
        var can = false
        let feature = makeFeature(canCheck: { can })
        let item = try XCTUnwrap(feature.menuContributions.first { $0.slot == .app })
        XCTAssertFalse(item.isEnabled())
        can = true
        XCTAssertTrue(item.isEnabled())
    }

    func testToggleReflectsInstallsAutomatically() throws {
        let automatic = Box(false)
        let feature = makeFeature(automatic: automatic)
        let toggle = try XCTUnwrap(feature.menuContributions.first { $0.title == "Install Updates Automatically" })
        XCTAssertEqual(toggle.isChecked?(), false)
        toggle.action()
        XCTAssertTrue(automatic.value)
        XCTAssertEqual(toggle.isChecked?(), true)
        toggle.action()
        XCTAssertFalse(automatic.value)
    }

    func testDevChannelNeverChecksInBackground() {
        let info: [String: Any] = [
            "AgenticReleaseChannel": "dev",
            "SUFeedURL": "https://example.com/appcast.xml",
            "SUPublicEDKey": "abc123="
        ]
        XCTAssertEqual(AppUpdaterConfiguration(infoDictionary: info)?.checksInBackground, false)
    }
}

@MainActor
final class ClosureMenuItemTargetCheckStateTests: XCTestCase {
    func testValidateSetsStateFromIsChecked() {
        var checked = true
        let target = ClosureMenuItemTarget(action: {}, isChecked: { checked })
        let item = NSMenuItem()
        XCTAssertTrue(target.validateMenuItem(item))
        XCTAssertEqual(item.state, .on)
        checked = false
        _ = target.validateMenuItem(item)
        XCTAssertEqual(item.state, .off)
    }

    func testValidateLeavesStateAloneWithoutIsChecked() {
        let target = ClosureMenuItemTarget(action: {})
        let item = NSMenuItem()
        item.state = .mixed
        _ = target.validateMenuItem(item)
        XCTAssertEqual(item.state, .mixed)
    }
}
