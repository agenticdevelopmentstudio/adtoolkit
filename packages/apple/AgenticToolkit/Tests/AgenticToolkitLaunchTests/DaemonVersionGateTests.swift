import XCTest
@testable import AgenticToolkitLaunch

/// The gate quits the app, so its bias matters more than its arithmetic: it must
/// fire on a definitely-older daemon and on nothing else.
final class DaemonVersionGateTests: XCTestCase {
    /// A gate for a daemon that renumbered: versions with major 2 are the old scheme.
    private let renumbered = DaemonVersionGate(minimum: .legacy(major: 2, minor: 123, patch: 1), legacyMajor: 2)
    /// A gate for a daemon with no history.
    private let plain = DaemonVersionGate(minimum: .current(major: 1, minor: 2, patch: 0))

    // MARK: - Too old

    func testAnOlderPatchIsTooOld() {
        XCTAssertEqual(renumbered.verdict(daemonVersion: "2.123.0"), .tooOld(reported: "2.123.0"))
    }

    func testAnOlderMinorIsTooOld() {
        XCTAssertEqual(renumbered.verdict(daemonVersion: "2.99.9"), .tooOld(reported: "2.99.9"))
    }

    func testAnOlderMajorIsTooOld() {
        XCTAssertEqual(plain.verdict(daemonVersion: "0.999.999"), .tooOld(reported: "0.999.999"))
    }

    // MARK: - Renumbering

    /// From the renumbering the daemon reports the product's version, which semver
    /// would sort below every legacy daemon. It is newer than all of them.
    func testACurrentVersionIsNewerThanEveryLegacyOne() {
        let gate = DaemonVersionGate(minimum: .legacy(major: 2, minor: 178, patch: 1), legacyMajor: 2)
        for version in ["1.1.0", "1.1.7", "1.2.0"] {
            XCTAssertEqual(gate.verdict(daemonVersion: version), .allowed, version)
        }
        XCTAssertGreaterThan(DaemonVersion("1.1.0", legacyMajor: 2)!, DaemonVersion("2.178.1", legacyMajor: 2)!)
        XCTAssertLessThan(DaemonVersion("1.1.0", legacyMajor: 2)!, DaemonVersion("1.1.1", legacyMajor: 2)!)
    }

    /// A legacy daemon lacks anything added since, however large its numbers are.
    func testALegacyDaemonIsOlderThanACurrentMinimum() {
        let gate = DaemonVersionGate(minimum: .current(major: 1, minor: 2, patch: 0), legacyMajor: 2)
        XCTAssertEqual(gate.verdict(daemonVersion: "2.178.1"), .tooOld(reported: "2.178.1"))
    }

    /// Without a legacy major, a 2.x version is just a larger semver.
    func testNoLegacyMajorMeansPlainSemver() {
        XCTAssertEqual(plain.verdict(daemonVersion: "2.0.0"), .allowed)
        XCTAssertEqual(DaemonVersion("2.0.0", legacyMajor: nil)?.isLegacy, false)
        XCTAssertEqual(DaemonVersion("2.0.0", legacyMajor: 2)?.isLegacy, true)
    }

    /// Components are compared numerically, not as text.
    func testComparisonIsNumericNotLexicographic() {
        XCTAssertEqual(renumbered.verdict(daemonVersion: "2.124.0"), .allowed)
        XCTAssertNotEqual(renumbered.verdict(daemonVersion: "2.99.0"), .allowed)
    }

    // MARK: - Allowed

    func testTheExactMinimumRuns() {
        XCTAssertEqual(renumbered.verdict(daemonVersion: "2.123.1"), .allowed)
    }

    /// The whole point of `>=`: a daemon ahead of the app is expected to serve it.
    func testANewerDaemonRuns() {
        for version in ["2.123.2", "2.124.0", "2.200.0", "3.0.0"] {
            XCTAssertEqual(renumbered.verdict(daemonVersion: version), .allowed,
                           "\(version) is newer than the minimum and must not be gated")
        }
    }

    // MARK: - Failing open

    /// An unreachable daemon is not a stale one: at login it may still be starting.
    func testAnUnreachableDaemonDoesNotQuitTheApp() {
        XCTAssertEqual(renumbered.verdict(daemonVersion: nil), .allowed)
    }

    /// "Could not read it" is not "too old".
    func testAnUnparseableVersionDoesNotQuitTheApp() {
        for version in ["", "unknown", "2.123.1-rc.1", "two.one.zero", "2.1.0.4"] {
            XCTAssertEqual(renumbered.verdict(daemonVersion: version), .allowed,
                           "\(version) is unparseable and must fail open")
        }
    }

    // MARK: - Failing closed

    /// Unlike `verdict`, `supports` fails CLOSED: "could not tell" is "no".
    func testSupportsNeedsAKnownNewEnoughDaemon() {
        let since = DaemonVersion.legacy(major: 2, minor: 176, patch: 0)
        XCTAssertFalse(renumbered.supports(since: since, daemonVersion: nil))
        XCTAssertFalse(renumbered.supports(since: since, daemonVersion: "garbage"))
        XCTAssertFalse(renumbered.supports(since: since, daemonVersion: "2.175.9"))
        XCTAssertTrue(renumbered.supports(since: since, daemonVersion: "2.176.0"))
        XCTAssertTrue(renumbered.supports(since: since, daemonVersion: "1.1.0"))
        XCTAssertTrue(renumbered.supports(since: since, daemonVersion: "3.0.0"))
    }

    // MARK: - Enforce

    @MainActor func testEnforcePresentsOnlyATooOldDaemon() async {
        let presented = expectation(description: "presented")
        let reports = PresentedReports()
        renumbered.enforce(current: { "2.100.0" }, present: { reported, minimum in
            reports.append("\(reported) < \(minimum)")
            presented.fulfill()
        })
        await fulfillment(of: [presented], timeout: 5)
        XCTAssertEqual(reports.items, ["2.100.0 < 123.1".replacingOccurrences(of: "123.1", with: "2.123.1")])
    }

    @MainActor func testEnforceStaysQuietForAnAllowedDaemon() async {
        let quiet = expectation(description: "not presented")
        quiet.isInverted = true
        renumbered.enforce(current: { "2.123.1" }, present: { _, _ in quiet.fulfill() })
        await fulfillment(of: [quiet], timeout: 0.5)
    }
}

@MainActor private final class PresentedReports {
    private(set) var items: [String] = []
    func append(_ item: String) { items.append(item) }
}
