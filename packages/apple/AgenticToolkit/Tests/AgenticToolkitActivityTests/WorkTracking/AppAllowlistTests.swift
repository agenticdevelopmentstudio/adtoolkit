import XCTest
@testable import AgenticToolkitActivity
import AgenticToolkitCore

final class AppAllowlistTests: XCTestCase {
    func testDefaultsAreAllowedAndOthersAreNot() {
        let list = AppAllowlist(preferences: .default)
        XCTAssertTrue(list.isAllowed("com.apple.dt.Xcode"))
        XCTAssertFalse(list.isAllowed("com.apple.Safari"))
    }
    func testRemovedDefaultIsNotAllowedAndAddedAppIs() {
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["org.example.Editor"],
                                            removedBundleIds: ["com.apple.Terminal"], retentionDays: 90)
        let list = AppAllowlist(preferences: prefs)
        XCTAssertFalse(list.isAllowed("com.apple.Terminal"))
        XCTAssertTrue(list.isAllowed("org.example.Editor"))
        XCTAssertEqual(list.app(for: "org.example.Editor")?.resolver, .editor)
    }
    func testSublimeMergeIsAGitClientWithNoPath() {
        XCTAssertEqual(AppAllowlist(preferences: .default).app(for: "com.sublimemerge")?.resolver, PathResolverKind.none)
    }
    func testDefaultBundleIdsAreUnique() {
        XCTAssertEqual(Set(AppAllowlist.defaults.map(\.bundleId)).count, AppAllowlist.defaults.count)
    }
}
