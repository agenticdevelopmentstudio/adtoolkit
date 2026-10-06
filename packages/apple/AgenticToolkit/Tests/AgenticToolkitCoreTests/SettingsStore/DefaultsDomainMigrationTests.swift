import XCTest
@testable import AgenticToolkitCore

final class DefaultsDomainMigrationTests: XCTestCase {
    private let defaults = UserDefaults.standard
    private var legacy = ""
    private var current = ""

    override func setUp() {
        super.setUp()
        let tag = UUID().uuidString
        legacy = "com.example.migration-test.legacy.\(tag)"
        current = "com.example.migration-test.current.\(tag)"
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: legacy)
        defaults.removePersistentDomain(forName: current)
        super.tearDown()
    }

    func testCopiesLegacySettingsIntoAnEmptyDomain() {
        defaults.setPersistentDomain(["theme": "dark", "count": 3], forName: legacy)

        XCTAssertTrue(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))

        let copied = defaults.persistentDomain(forName: current)
        XCTAssertEqual(copied?["theme"] as? String, "dark")
        XCTAssertEqual(copied?["count"] as? Int, 3)
        XCTAssertNotNil(defaults.persistentDomain(forName: legacy), "legacy domain is kept for a downgrade")
    }

    /// A setting already made under the new id is the user's latest word.
    func testNeverOverwritesADomainThatAlreadyHoldsSettings() {
        defaults.setPersistentDomain(["theme": "dark"], forName: legacy)
        defaults.setPersistentDomain(["theme": "light"], forName: current)

        XCTAssertFalse(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))
        XCTAssertEqual(defaults.persistentDomain(forName: current)?["theme"] as? String, "light")
    }

    /// The new domain is rarely empty: a development build under the new id
    /// leaves its own keys there. Those must not block the legacy window
    /// positions from coming across.
    func testMergesMissingKeysIntoANonEmptyDomain() {
        defaults.setPersistentDomain(
            ["WindowState_main": "{0,0,800,600}", "WindowVisible_main": true, "theme": "dark"], forName: legacy)
        defaults.setPersistentDomain(["Instance1234_WindowState_main": "x", "theme": "light"], forName: current)

        XCTAssertTrue(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))

        let merged = defaults.persistentDomain(forName: current)
        XCTAssertEqual(merged?["WindowState_main"] as? String, "{0,0,800,600}")
        XCTAssertEqual(merged?["WindowVisible_main"] as? Bool, true)
        XCTAssertEqual(merged?["theme"] as? String, "light")
        XCTAssertEqual(merged?["Instance1234_WindowState_main"] as? String, "x")
    }

    /// Once merged, a key the user later removes under the new id stays removed.
    func testMergesOnlyOnce() {
        defaults.setPersistentDomain(["theme": "dark"], forName: legacy)
        XCTAssertTrue(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))

        var domain = defaults.persistentDomain(forName: current) ?? [:]
        domain.removeValue(forKey: "theme")
        defaults.setPersistentDomain(domain, forName: current)

        XCTAssertFalse(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))
        XCTAssertNil(defaults.persistentDomain(forName: current)?["theme"])
    }

    func testDoesNothingWithoutLegacySettings() {
        XCTAssertFalse(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))
        XCTAssertTrue(defaults.persistentDomain(forName: current)?.isEmpty ?? true)
    }

    func testIsIdempotent() {
        defaults.setPersistentDomain(["theme": "dark"], forName: legacy)

        XCTAssertTrue(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))
        XCTAssertFalse(DefaultsDomainMigration.migrateIfNeeded(from: legacy, to: current))
    }
}
