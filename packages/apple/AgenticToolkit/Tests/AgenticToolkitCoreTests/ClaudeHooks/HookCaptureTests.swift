@testable import AgenticToolkitCore
import Foundation
import XCTest

/// The hook capture command, the status-line capture around it, and the drop
/// directory each configuration reads. Drop files go to temporary directories
/// through an explicit `environment:`; nothing here touches the real
/// `~/.claude`.
final class HookCaptureTests: XCTestCase {

    private var directory: URL!
    private var settings: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hookcapture-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        settings = directory.appendingPathComponent("settings.json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private var stenographer: ClaudeHookConfiguration { .stenographerFixture(settingsURL: settings) }
    private var adkd: ClaudeHookConfiguration { .adkdFixture(settingsURL: settings) }

    private func dropFiles(_ url: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
    }

    private func hookData(_ envelope: [String: Any]?) throws -> [String: Any] {
        try XCTUnwrap(envelope?["hook_data"] as? [String: Any])
    }

    // MARK: - Drop directory

    func testEachConfigurationReadsItsOwnDropDirectoryVariable() {
        XCTAssertEqual(HookDropWriter.dropDirectoryVariable(configuration: stenographer), "STENOGRAPHER_DROP_DIR")
        XCTAssertEqual(HookDropWriter.dropDirectoryVariable(configuration: adkd), "ADKD_DROP_DIR")
    }

    func testTheVariableOverridesTheConfiguredDirectoryOnlyWhenNonEmpty() {
        XCTAssertEqual(HookDropWriter.dropDirectory(configuration: adkd, environment: ["ADKD_DROP_DIR": "/tmp/x"]),
                       "/tmp/x")
        XCTAssertEqual(HookDropWriter.dropDirectory(configuration: adkd, environment: ["ADKD_DROP_DIR": ""]),
                       "~/.claude/adkd-events")
        XCTAssertEqual(HookDropWriter.dropDirectory(configuration: adkd, environment: ["STENOGRAPHER_DROP_DIR": "/tmp/y"]),
                       "~/.claude/adkd-events", "another configuration's variable is not read")
    }

    // MARK: - Hook capture

    func testRunWritesADropFileForTheEvent() throws {
        let drop = directory.appendingPathComponent("drop")
        let status = HookCaptureCommand.run(
            arguments: ["--event", "Stop", "--ppid", "5"],
            stdin: Data(#"{"session_id":"s1"}"#.utf8),
            environment: ["ADKD_DROP_DIR": drop.path],
            configuration: adkd,
            accountName: { _ in "who@example.com" },
            oauthEmail: { "login@example.com" },
            claudePid: { nil })
        XCTAssertEqual(status, 0)
        let files = try dropFiles(drop)
        XCTAssertEqual(files.count, 1)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: files[0])) as? [String: Any])
        XCTAssertEqual(envelope["event"] as? String, "Stop")
        XCTAssertEqual(envelope["oauth_account_email"] as? String, "login@example.com")
    }

    func testRunWithoutAnEventWritesNothingAndStillSucceeds() throws {
        let drop = directory.appendingPathComponent("drop")
        let status = HookCaptureCommand.run(
            arguments: [], stdin: Data(), environment: ["ADKD_DROP_DIR": drop.path],
            configuration: adkd, accountName: { _ in "" }, claudePid: { nil })
        XCTAssertEqual(status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: drop.path))
    }

    func testEnvelopeCarriesTermSessionIdAndSessionStartPid() throws {
        let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "SessionStart", ppidString: "123",
            stdin: Data(#"{"session_id":"s1","cwd":"/tmp"}"#.utf8),
            env: ["TERM_PROGRAM": "iTerm.app", "TERM_SESSION_ID": "w1t12p0:UUID-9"],
            claudePid: { nil }, accountName: { _ in "" })
        let fields = try hookData(envelope)
        XCTAssertEqual(fields["term_session_id"] as? String, "w1t12p0:UUID-9")
        XCTAssertEqual(fields["term_program"] as? String, "iTerm.app")
        XCTAssertEqual(fields["pid"] as? Int, 123)
    }

    func testOnlySessionStartCarriesAPid() throws {
        let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "PreToolUse", ppidString: nil, stdin: Data(#"{"session_id":"s2"}"#.utf8),
            env: [:], claudePid: { nil }, accountName: { _ in "" })
        let fields = try hookData(envelope)
        XCTAssertEqual(fields["term_session_id"] as? String, "")
        XCTAssertNil(fields["pid"])
    }

    func testHeadlessEventsAreNotTracked() {
        let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "SessionStart", ppidString: "1", stdin: Data(#"{"session_id":"summary"}"#.utf8),
            env: ["AGENTIC_TOOLKIT_HEADLESS": "1"], claudePid: { nil }, accountName: { _ in "" })
        XCTAssertNil(envelope)
    }

    func testClaudesPidIsFoundWhenNoPpidFlagIsGiven() throws {
        let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "SessionStart", ppidString: nil, stdin: Data(#"{"session_id":"s1"}"#.utf8),
            env: [:], claudePid: { 4242 }, accountName: { _ in "" })
        XCTAssertEqual(try hookData(envelope)["pid"] as? Int, 4242)
        let unknown = HookCaptureCommand.buildEnvelope(
            eventType: "SessionStart", ppidString: nil, stdin: Data(#"{"session_id":"s1"}"#.utf8),
            env: [:], claudePid: { nil }, accountName: { _ in "" })
        XCTAssertEqual(try hookData(unknown)["pid"] as? Int, 0)
    }

    func testTheAccountLookupsAreInjected() {
        let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "Stop", ppidString: "1", stdin: Data(#"{"session_id":"s1"}"#.utf8),
            env: [:], claudePid: { nil },
            accountName: { _ in "named@example.com" }, oauthEmail: { "x@example.com" })
        XCTAssertEqual(envelope?["account_email"] as? String, "named@example.com")
        XCTAssertEqual(envelope?["oauth_account_email"] as? String, "x@example.com")
    }

    // MARK: - Status-line capture

    private let payload = Data(#"{"session_id":"sl-1","cwd":"/nonexistent-dir"}"#.utf8)

    func testAFeedTheDaemonRefusesIsDroppedInTheConfigurationsDirectory() throws {
        let drop = directory.appendingPathComponent("drop")
        StatusLineCapture.feed(
            payload: payload, token: nil, environment: ["ADKD_DROP_DIR": drop.path],
            configuration: adkd, post: { _, _ in false }, accountName: { _ in "" }, oauthEmail: { "" })
        let files = try dropFiles(drop)
        XCTAssertEqual(files.count, 1)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: files[0])) as? [String: Any])
        XCTAssertEqual(envelope["event"] as? String, "StatusLine")
    }

    func testAFeedTheDaemonAcceptsLeavesNoDropFile() {
        let drop = directory.appendingPathComponent("drop")
        nonisolated(unsafe) var posted: [String] = []
        StatusLineCapture.feed(
            payload: payload, token: nil, environment: ["STENOGRAPHER_DROP_DIR": drop.path],
            configuration: stenographer, post: { event, _ in posted.append(event); return true },
            accountName: { _ in "" }, oauthEmail: { "" })
        XCTAssertEqual(posted, ["StatusLine"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: drop.path))
    }

    func testCaptureOnlySkipsTheRenderAndExitsZero() {
        nonisolated(unsafe) var rendered = false
        let status = StatusLineCapture.run(
            captureOnly: true, payload: payload, environment: ["ADKD_DROP_DIR": directory.path],
            configuration: adkd, post: { _, _ in true }, accountName: { _ in "" },
            render: { _, _ in rendered = true; return 7 })
        XCTAssertEqual(status, 0)
        XCTAssertFalse(rendered)
    }

    func testARenderReturnsItsOwnStatusAndStillFeeds() {
        nonisolated(unsafe) var posted = false
        let status = StatusLineCapture.run(
            captureOnly: false, payload: payload, environment: ["ADKD_DROP_DIR": directory.path],
            configuration: adkd, post: { _, _ in posted = true; return true }, accountName: { _ in "" },
            render: { _, _ in 3 })
        XCTAssertEqual(status, 3)
        // This test process is not the helper, so the feed runs in-process.
        XCTAssertTrue(posted)
    }

    func testTheFeedLockIsNamedForTheConfiguration() throws {
        let lock = try XCTUnwrap(FeedLock.acquire(sessionID: "s", name: "adkd", directory: directory))
        defer { lock.release() }
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(names.contains("adkd-statusline-feed-s.lock"))
    }
}
