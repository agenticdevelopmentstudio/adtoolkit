import AgenticToolkitCore
@testable import AgenticToolkitMacOS
import XCTest

/// Where a saved credential belongs, decided by its kind: a login stays on the
/// Mac that holds it, a setup token goes to every Mac. A login in iCloud
/// Keychain put one single-use refresh token on every Mac, and whichever Mac
/// refreshed it first signed the others out.
final class ClaudeCredentialPlacementTests: XCTestCase {

    private typealias Located = ClaudeAccountKeychainStore.Located
    private typealias Placement = ClaudeAccountKeychainStore.Placement

    private func located(
        _ name: String, _ kind: ClaudeCredentialKind, in location: ClaudeKeychainLocation
    ) -> Located {
        let account = ClaudeSavedAccount(name: name, kind: kind, identity: name)
        return Located(account: account, location: location, itemKey: account.itemKey)
    }

    private func place(
        _ found: [Located], live: String = "", sharedReachable: Bool = true
    ) -> Placement {
        Placement(of: found, sharedReachable: sharedReachable) {
            ClaudeLoginIdentity(email: live, uuid: "")
        }
    }

    private func keys(_ records: [Located]) -> [String] { records.map(\.itemKey).sorted() }

    func testALoginBelongsOnThisMacAndASetupTokenOnEveryMac() {
        XCTAssertEqual(ClaudeKeychainLocation.home(of: .oauth), .login)
        XCTAssertEqual(ClaudeKeychainLocation.home(of: .longLived), .shared)
    }

    func testRecordsAlreadyHomeAreListedAsTheyAre() {
        let login = located("a@x.com", .oauth, in: .login)
        let token = located("a@x.com", .longLived, in: .shared)
        let placement = place([login, token])
        XCTAssertEqual(keys(placement.settled), keys([login, token]))
        XCTAssertTrue(placement.moving.isEmpty)
        XCTAssertTrue(placement.redundant.isEmpty)
    }

    func testThisMacsLiveLoginFoundInICloudMovesHere() {
        let shared = located("a@x.com", .oauth, in: .shared)
        let placement = place([shared], live: "a@x.com")
        XCTAssertEqual(keys(placement.moving), keys([shared]))
        XCTAssertTrue(placement.settled.isEmpty)
    }

    func testALoginInICloudThatIsNotLiveHereIsNeitherListedNorTouched() {
        // It may be another Mac's live login: listing it would let this Mac
        // refresh it, and deleting it would take the other Mac's saved copy.
        let shared = located("b@x.com", .oauth, in: .shared)
        let placement = place([shared], live: "a@x.com")
        XCTAssertTrue(placement.settled.isEmpty)
        XCTAssertTrue(placement.moving.isEmpty)
        XCTAssertTrue(placement.redundant.isEmpty)
    }

    func testALoginInICloudIsLeftAloneOnceThisMacHasSavedItsOwn() {
        let local = located("a@x.com", .oauth, in: .login)
        let shared = located("a@x.com", .oauth, in: .shared)
        let placement = place([local, shared], live: "a@x.com")
        XCTAssertEqual(keys(placement.settled), keys([local]))
        XCTAssertTrue(placement.moving.isEmpty)
        XCTAssertTrue(placement.redundant.isEmpty)
    }

    func testASetupTokenOnThisMacMovesToICloud() {
        let token = located("a@x.com", .longLived, in: .login)
        let placement = place([token])
        XCTAssertEqual(keys(placement.moving), keys([token]))
    }

    func testASetupTokenStaysOnThisMacWhenICloudCannotBeReached() {
        let token = located("a@x.com", .longLived, in: .login)
        let placement = place([token], sharedReachable: false)
        XCTAssertEqual(keys(placement.settled), keys([token]))
        XCTAssertTrue(placement.moving.isEmpty)
    }

    func testASetupTokenAlreadyInICloudRetiresItsLocalTwin() {
        let local = located("a@x.com", .longLived, in: .login)
        let shared = located("a@x.com", .longLived, in: .shared)
        let placement = place([local, shared])
        XCTAssertEqual(placement.settled.map(\.location), [.shared])
        XCTAssertEqual(placement.redundant.map(\.location), [.login])
        XCTAssertTrue(placement.moving.isEmpty)
    }

    func testALegacyItemThatCouldNotBeMigratedStaysWhereItIs() {
        // Still addressed by its bare name, holding possibly two records:
        // deleting that item to move one of them would lose the other.
        let account = ClaudeSavedAccount(name: "a@x.com", kind: .longLived)
        let legacy = Located(account: account, location: .login, itemKey: "a@x.com")
        let placement = place([legacy])
        XCTAssertEqual(keys(placement.settled), ["a@x.com"])
        XCTAssertTrue(placement.moving.isEmpty)
    }

    func testTheLiveLoginIsReadOnlyWhenICloudHoldsALogin() {
        // `~/.claude.json` is most of a megabyte; a listing with nothing to
        // claim has no reason to parse it.
        var reads = 0
        _ = Placement(
            of: [located("a@x.com", .oauth, in: .login), located("a@x.com", .longLived, in: .shared)],
            sharedReachable: true
        ) {
            reads += 1
            return ClaudeLoginIdentity()
        }
        XCTAssertEqual(reads, 0)
    }
}
