import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitLaunch

/// Covers the "deliberate stop" marker that keeps `ensureRunning()` from
/// reviving a daemon the user stopped on purpose. Every test drives an injected
/// temp URL so a real marker is never touched.
final class DaemonBootstrapTests: XCTestCase {

    private var markerURL: URL!
    private let label = "com.example.daemon"

    override func setUpWithError() throws {
        try super.setUpWithError()
        markerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bootstrap-tests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("daemon-stopped-by-user")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: markerURL.deletingLastPathComponent())
        markerURL = nil
        try super.tearDownWithError()
    }

    private func bootstrap(plist: URL? = nil, commands: RecordingCommands = RecordingCommands()) -> DaemonBootstrap {
        DaemonBootstrap(label: label, plistURL: plist ?? missingPlistURL, stopMarkerURL: markerURL,
                        commands: commands)
    }

    private var missingPlistURL: URL {
        markerURL.deletingLastPathComponent().appendingPathComponent("missing.plist")
    }

    func testNoMarkerByDefault() {
        XCTAssertFalse(bootstrap().wasStoppedDeliberately)
    }

    func testRecordThenClearRoundTrips() {
        let bootstrap = bootstrap()
        bootstrap.recordDeliberateStop()
        XCTAssertTrue(bootstrap.wasStoppedDeliberately)

        bootstrap.clearDeliberateStop()
        XCTAssertFalse(bootstrap.wasStoppedDeliberately)
    }

    /// The marker's parent directory may not exist yet on a fresh install.
    func testRecordCreatesMissingParentDirectory() {
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: markerURL.deletingLastPathComponent().path)
        )
        let bootstrap = bootstrap()
        bootstrap.recordDeliberateStop()
        XCTAssertTrue(bootstrap.wasStoppedDeliberately)
    }

    /// Both operations are idempotent — the menu items can fire repeatedly, and
    /// clearing a marker that was never written must not fail.
    func testRepeatedRecordAndClearAreIdempotent() {
        let bootstrap = bootstrap()
        bootstrap.clearDeliberateStop()

        bootstrap.recordDeliberateStop()
        bootstrap.recordDeliberateStop()
        XCTAssertTrue(bootstrap.wasStoppedDeliberately)

        bootstrap.clearDeliberateStop()
        bootstrap.clearDeliberateStop()
        XCTAssertFalse(bootstrap.wasStoppedDeliberately)
    }

    /// The marker is self-describing: it stores the stop timestamp so anyone who
    /// finds the file while debugging knows what wrote it and when.
    func testMarkerRecordsAParseableTimestamp() throws {
        bootstrap().recordDeliberateStop()
        let contents = try String(contentsOf: markerURL, encoding: .utf8)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(
            formatter.date(from: contents),
            "marker should contain an ISO8601 timestamp, got \(contents)"
        )
    }

    /// The stamp carries sub-second precision. `ensureRunning` tells markers apart
    /// by content when deciding whether one went stale, so whole-second resolution
    /// would let two nearby stops collide.
    func testMarkerStampHasSubSecondPrecision() throws {
        bootstrap().recordDeliberateStop()
        let contents = try String(contentsOf: markerURL, encoding: .utf8)

        let secondsOnly = ISO8601DateFormatter()
        secondsOnly.formatOptions = [.withInternetDateTime]
        XCTAssertNil(
            secondsOnly.date(from: contents),
            "stamp \(contents) parsed without fractional seconds, so it lacks sub-second precision"
        )
    }

    /// No plist means nothing to bootstrap, so ensureRunning must be a pure no-op
    /// — in particular it must not touch the marker, nor run `launchctl`.
    func testEnsureRunningIsANoOpWhenPlistMissing() async {
        let commands = RecordingCommands()
        let bootstrap = bootstrap(commands: commands)
        bootstrap.recordDeliberateStop()
        await bootstrap.ensureRunning()
        XCTAssertTrue(bootstrap.wasStoppedDeliberately)

        bootstrap.clearDeliberateStop()
        await bootstrap.ensureRunning()
        XCTAssertFalse(bootstrap.wasStoppedDeliberately)
        XCTAssertTrue(commands.calls.isEmpty)
    }

    /// The launch-time entry point hands back a task and does its work there; the
    /// registered daemon it finds clears the stale marker once the task finishes.
    func testEnsureRunningInBackgroundDoesTheWorkInItsTask() async throws {
        let commands = RecordingCommands()
        let bootstrap = bootstrap(plist: try presentPlistURL(), commands: commands)
        bootstrap.recordDeliberateStop()

        await bootstrap.ensureRunningInBackground().value

        XCTAssertFalse(bootstrap.wasStoppedDeliberately,
                       "the background work should have cleared the marker as stale")
        XCTAssertEqual(commands.calls, [["/bin/launchctl", "print", "gui/\(getuid())/\(label)"]])
    }

    // MARK: - Stale-marker clearing

    /// An observed-registered daemon proves the marker is stale, so it must go —
    /// otherwise one deliberate stop would disable self-heal forever.
    func testRegisteredDaemonClearsAStaleMarker() async throws {
        let bootstrap = bootstrap(plist: try presentPlistURL())
        bootstrap.recordDeliberateStop()

        await bootstrap.ensureRunning(isRegistered: { _ in true })

        XCTAssertFalse(bootstrap.wasStoppedDeliberately)
    }

    /// The race the compare-and-swap exists for: a "Stop" click can land while the
    /// registration probe is still running. The marker written by that click must
    /// survive — clearing it would revive the daemon on the next launch.
    func testStopRecordedDuringTheProbeIsNotClearedAsStale() async throws {
        // A marker from an earlier session, written with a fixed stamp so it cannot
        // coincide with the one the probe writes below.
        let staleStamp = "2020-01-01T00:00:00.000Z"
        try FileManager.default.createDirectory(
            at: markerURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try staleStamp.write(to: markerURL, atomically: true, encoding: .utf8)
        let bootstrap = bootstrap(plist: try presentPlistURL())
        let marker = markerURL!

        await bootstrap.ensureRunning(isRegistered: { _ in
            // The user clicks Stop while launchctl is still being waited on.
            DaemonBootstrap.recordDeliberateStop(at: marker)
            return true
        })

        XCTAssertTrue(bootstrap.wasStoppedDeliberately,
                      "a stop recorded during the probe must not be cleared as stale")
        XCTAssertNotEqual(
            try String(contentsOf: markerURL, encoding: .utf8), staleStamp,
            "the surviving marker should be the new one, not the stale stamp"
        )
    }

    /// An unregistered daemon with no marker is the self-heal case — but with a
    /// marker present `ensureRunning` must leave it alone and not bootstrap.
    func testMarkerSurvivesWhenDaemonIsNotRegistered() async throws {
        let commands = RecordingCommands()
        let bootstrap = bootstrap(plist: try presentPlistURL(), commands: commands)
        bootstrap.recordDeliberateStop()

        await bootstrap.ensureRunning(isRegistered: { _ in false })

        XCTAssertTrue(bootstrap.wasStoppedDeliberately)
        XCTAssertTrue(commands.calls.isEmpty)
    }

    /// Unregistered, no marker, plist present: the job is bootstrapped from the plist.
    func testUnregisteredDaemonWithoutMarkerIsBootstrapped() async throws {
        let commands = RecordingCommands()
        let plist = try presentPlistURL()
        let bootstrap = bootstrap(plist: plist, commands: commands)

        await bootstrap.ensureRunning(uid: 501, isRegistered: { _ in false })

        XCTAssertEqual(commands.calls, [["/bin/launchctl", "bootstrap", "gui/501", plist.path]])
    }

    func testIsRegisteredReadsLaunchctlPrintStatus() async {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print gui/501/\(label)"] = (113, "")
        let unregistered = await bootstrap(commands: commands).isRegistered(uid: 501)
        XCTAssertFalse(unregistered)

        commands.responses["/bin/launchctl print gui/501/\(label)"] = (0, "")
        let registered = await bootstrap(commands: commands).isRegistered(uid: 501)
        XCTAssertTrue(registered)
    }

    /// A real (empty) file standing in for an installed LaunchAgent plist, so the
    /// `plist exists` guard passes without touching `~/Library/LaunchAgents`.
    private func presentPlistURL() throws -> URL {
        let url = markerURL.deletingLastPathComponent().appendingPathComponent("present.plist")
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data().write(to: url)
        return url
    }
}
