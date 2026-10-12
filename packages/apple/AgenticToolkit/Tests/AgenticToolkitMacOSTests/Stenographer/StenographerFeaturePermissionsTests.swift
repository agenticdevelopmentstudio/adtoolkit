import AgenticToolkitPermissions
import XCTest
@testable import AgenticToolkitMacOS

/// The grants the Stenographer-fed features add to a host's own set.
@MainActor
final class StenographerFeaturePermissionsTests: XCTestCase {

    /// The toolkit's default trio already asks for iTerm2, so adding the
    /// features' pair asks for it once and appends only Terminal.
    func testAddingToTheDefaultSetAppendsTerminalOnly() {
        XCTAssertEqual(
            StenographerFeaturePermissions.adding(to: PermissionWalkthrough.defaultPermissions),
            [.accessibility, .notifications,
             .automation(targetBundleID: "com.googlecode.iterm2"),
             .automation(targetBundleID: "com.apple.Terminal")])
    }

    func testAddingToNothingIsTheFeatureSetItself() {
        XCTAssertEqual(StenographerFeaturePermissions.adding(to: []), StenographerFeaturePermissions.all)
    }

    /// Adding twice adds nothing the second time.
    func testAddingIsIdempotent() {
        let once = StenographerFeaturePermissions.adding(to: PermissionWalkthrough.defaultPermissions)
        XCTAssertEqual(StenographerFeaturePermissions.adding(to: once), once)
    }

    /// The features type into a terminal and do nothing else TCC guards: no
    /// Accessibility, Notifications or Keychain row.
    func testOnlyAutomationIsAskedFor() {
        for permission in StenographerFeaturePermissions.all {
            guard case .automation = permission else {
                return XCTFail("\(permission) is not an Automation grant")
            }
        }
    }
}
