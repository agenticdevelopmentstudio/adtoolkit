import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitLaunch

final class LaunchAgentJobTests: XCTestCase {
    private var home: URL!
    private let current = "com.example.daemon"
    private let legacy = "com.example.old-daemon"
    private let domain = "gui/\(getuid())"

    override func setUpWithError() throws {
        home = FileManager.default.temporaryDirectory.appendingPathComponent("la-\(UUID())")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: home)
    }

    private var plistURL: URL { home.appendingPathComponent("LaunchAgents/\(current).plist") }
    private var legacyPlistURL: URL { home.appendingPathComponent("LaunchAgents/\(legacy).plist") }
    private var supportDirectory: URL { home.appendingPathComponent("support") }
    private var logsDirectory: URL { home.appendingPathComponent("logs") }
    private var markerURL: URL { supportDirectory.appendingPathComponent("daemon-stopped-by-user") }

    private func spec(machServices: [String]? = nil) -> LaunchAgentSpec {
        LaunchAgentSpec(
            label: current,
            programArguments: ["/Users/Jane Smith/Downloads/Example.app/Contents/MacOS/exampled"],
            workingDirectory: supportDirectory,
            stdoutPath: logsDirectory.appendingPathComponent("stdout.log"),
            stderrPath: logsDirectory.appendingPathComponent("stderr.log"),
            machServices: machServices ?? [current])
    }

    // MARK: - The plist

    func testPlistRendersTheSpecWithPathsContainingSpaces() throws {
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(
            from: LaunchAgentPlist.render(spec()), format: nil) as? [String: Any])
        XCTAssertEqual(plist["Label"] as? String, current)
        XCTAssertEqual(plist["ProgramArguments"] as? [String],
                       ["/Users/Jane Smith/Downloads/Example.app/Contents/MacOS/exampled"])
        XCTAssertEqual((plist["MachServices"] as? [String: Bool])?[current], true)
        XCTAssertEqual(plist["WorkingDirectory"] as? String, supportDirectory.path)
        XCTAssertEqual(plist["StandardOutPath"] as? String, logsDirectory.appendingPathComponent("stdout.log").path)
        XCTAssertEqual(plist["StandardErrorPath"] as? String, logsDirectory.appendingPathComponent("stderr.log").path)
        XCTAssertEqual((plist["KeepAlive"] as? [String: Bool])?["Crashed"], true)
        XCTAssertEqual(plist["RunAtLoad"] as? Bool, true)
        XCTAssertEqual(plist["ThrottleInterval"] as? Int, 30)
        XCTAssertEqual(plist["ProcessType"] as? String, "Adaptive")
        XCTAssertNil(plist["EnvironmentVariables"])
    }

    /// The exact bytes of the XML for a daemon that registers one Mach service.
    func testPlistBytesMatchTheGoldenXML() {
        let tab = "\t"
        let lines = [
            #"<?xml version="1.0" encoding="UTF-8"?>"#,
            #"<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">"#,
            #"<plist version="1.0">"#,
            "<dict>",
            "\(tab)<key>KeepAlive</key>", "\(tab)<dict>", "\(tab)\(tab)<key>Crashed</key>", "\(tab)\(tab)<true/>",
            "\(tab)</dict>",
            "\(tab)<key>Label</key>", "\(tab)<string>com.example.daemon</string>",
            "\(tab)<key>MachServices</key>", "\(tab)<dict>", "\(tab)\(tab)<key>com.example.daemon</key>",
            "\(tab)\(tab)<true/>", "\(tab)</dict>",
            "\(tab)<key>ProcessType</key>", "\(tab)<string>Adaptive</string>",
            "\(tab)<key>ProgramArguments</key>", "\(tab)<array>",
            "\(tab)\(tab)<string>/Users/Jane Smith/Downloads/Example.app/Contents/MacOS/exampled</string>",
            "\(tab)</array>",
            "\(tab)<key>RunAtLoad</key>", "\(tab)<true/>",
            "\(tab)<key>StandardErrorPath</key>", "\(tab)<string>\(logsDirectory.path)/stderr.log</string>",
            "\(tab)<key>StandardOutPath</key>", "\(tab)<string>\(logsDirectory.path)/stdout.log</string>",
            "\(tab)<key>ThrottleInterval</key>", "\(tab)<integer>30</integer>",
            "\(tab)<key>WorkingDirectory</key>", "\(tab)<string>\(supportDirectory.path)</string>",
            "</dict>",
            "</plist>",
            ""
        ]
        XCTAssertEqual(String(decoding: LaunchAgentPlist.render(spec()), as: UTF8.self),
                       lines.joined(separator: "\n"))
    }

    func testNoMachServicesOmitsTheKey() throws {
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(
            from: LaunchAgentPlist.render(spec(machServices: [])), format: nil) as? [String: Any])
        XCTAssertNil(plist["MachServices"])
    }

    func testEnvironmentAndKeepAliveOffAreRendered() throws {
        var custom = spec()
        custom.keepAliveOnCrash = false
        custom.environment = ["KEY": "value"]
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(
            from: LaunchAgentPlist.render(custom), format: nil) as? [String: Any])
        XCTAssertNil(plist["KeepAlive"])
        XCTAssertEqual(plist["EnvironmentVariables"] as? [String: String], ["KEY": "value"])
    }

    func testRenderIsByteStable() throws {
        let first = rendered()
        XCTAssertEqual(first, rendered())
        // Reorder-proof: parse and re-serialize, the bytes must not move.
        let parsed = try XCTUnwrap(PropertyListSerialization.propertyList(from: first, format: nil) as? [String: Any])
        let again = try PropertyListSerialization.data(fromPropertyList: parsed, format: .xml, options: 0)
        XCTAssertEqual(first, again)
    }

    // MARK: - Assessment

    func testQueuesWhenPlistMissing() async {
        let jobs = await assessment().assess()
        XCTAssertEqual(jobs.map(\.id), ["launch-agent"])
    }

    func testNothingWhenPlistCurrentAndNoSupersededPlist() async throws {
        try write(rendered(), to: plistURL)
        let jobs = await assessment().assess()
        XCTAssertTrue(jobs.isEmpty)
    }

    func testQueuesWhenSupersededPlistPresent() async throws {
        try write(rendered(), to: plistURL)
        try write(Data(), to: legacyPlistURL)
        let jobs = await assessment().assess()
        XCTAssertEqual(jobs.map(\.id), ["launch-agent"])
    }

    func testUnparsablePlistCountsAsDiffering() async throws {
        try write(Data("not a plist".utf8), to: plistURL)
        let jobs = await assessment().assess()
        XCTAssertEqual(jobs.map(\.id), ["launch-agent"])
    }

    // MARK: - Job

    @MainActor func testJobBootsOutSupersededWritesAndBootstraps() async throws {
        try write(Data(), to: legacyPlistURL)
        let commands = unloadedCommands()

        try await runJob(commands: commands)

        XCTAssertEqual(commands.calls.first(where: { $0.contains("bootout") }),
                       ["/bin/launchctl", "bootout", "\(domain)/\(legacy)"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyPlistURL.path))
        XCTAssertEqual(try Data(contentsOf: plistURL), rendered())
        XCTAssertTrue(commands.calls.contains(["/bin/launchctl", "bootout", "\(domain)/\(current)"]))
        XCTAssertEqual(commands.calls.last, ["/bin/launchctl", "bootstrap", domain, plistURL.path])
        XCTAssertTrue(FileManager.default.fileExists(atPath: logsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: supportDirectory.path))
    }

    @MainActor func testBootstrapFollowsBootoutAndPrintOfCurrentLabel() async throws {
        let commands = unloadedCommands()

        try await runJob(commands: commands)

        XCTAssertEqual(Array(commands.calls.suffix(3)), [
            ["/bin/launchctl", "bootout", "\(domain)/\(current)"],
            ["/bin/launchctl", "print", "\(domain)/\(current)"],
            ["/bin/launchctl", "bootstrap", domain, plistURL.path]
        ])
    }

    @MainActor func testBootstrapRetriesOnceOnLaunchdTeardownRace() async throws {
        let commands = unloadedCommands()
        let bootstrap = ["/bin/launchctl", "bootstrap", domain, plistURL.path]
        commands.respond(to: bootstrap, inOrder: [(5, "Bootstrap failed: 5: Input/output error"), (0, "")])

        try await runJob(commands: commands)

        XCTAssertEqual(commands.calls.filter { $0 == bootstrap }.count, 2)
    }

    @MainActor func testBootstrapFailureThrowsDescribedError() async throws {
        let commands = unloadedCommands()
        commands.responses["/bin/launchctl bootstrap \(domain) \(plistURL.path)"] =
            (5, "Bootstrap failed: 5: Input/output error")

        do {
            try await runJob(commands: commands)
            XCTFail("expected the job to throw")
        } catch let error as LaunchJobError {
            let text = try XCTUnwrap(error.errorDescription)
            XCTAssertTrue(text.contains("launchctl bootstrap exited 5"))
            XCTAssertTrue(text.contains("Bootstrap failed: 5: Input/output error"))
        }
    }

    @MainActor func testDeliberatelyStoppedDaemonIsWrittenNotBootstrapped() async throws {
        try write(Data("stopped".utf8), to: markerURL)
        try write(Data(), to: legacyPlistURL)
        let commands = unloadedCommands()

        try await runJob(commands: commands)

        XCTAssertEqual(try Data(contentsOf: plistURL), rendered())
        XCTAssertFalse(commands.calls.contains { $0.contains("bootstrap") })
        XCTAssertTrue(commands.calls.contains(["/bin/launchctl", "bootout", "\(domain)/\(legacy)"]))
        XCTAssertTrue(commands.calls.contains(["/bin/launchctl", "bootout", "\(domain)/\(current)"]))
        XCTAssertTrue(FileManager.default.fileExists(atPath: markerURL.path))
    }

    @MainActor func testStaleMarkerWithLoadedDaemonIsClearedAndBootstrapped() async throws {
        try write(Data("stopped".utf8), to: markerURL)
        let commands = unloadedCommands()
        // the probe finds the daemon running; the poll after bootout finds it gone
        commands.respond(to: ["/bin/launchctl", "print", "\(domain)/\(current)"], inOrder: [(0, ""), (113, "")])

        try await runJob(commands: commands)

        XCTAssertFalse(FileManager.default.fileExists(atPath: markerURL.path))
        XCTAssertEqual(commands.calls.last, ["/bin/launchctl", "bootstrap", domain, plistURL.path])
    }

    @MainActor func testRunningTheJobTwiceIsSafe() async throws {
        try write(Data(), to: legacyPlistURL)
        try await runJob(commands: unloadedCommands())
        let firstBytes = try Data(contentsOf: plistURL)

        let second = unloadedCommands()
        try await runJob(commands: second)

        XCTAssertFalse(second.calls.contains(["/bin/launchctl", "bootout", "\(domain)/\(legacy)"]))
        XCTAssertEqual(try Data(contentsOf: plistURL), firstBytes)
        XCTAssertEqual(second.calls.last, ["/bin/launchctl", "bootstrap", domain, plistURL.path])
        let jobs = await assessment().assess()
        XCTAssertTrue(jobs.isEmpty)
    }

    // A test of a superseded job that never leaves launchd is deliberately absent: it
    // costs the full 20 x 250 ms poll (5 s of real sleep), and no clock is injected.

    /// Neither job is loaded: every `print` exits 113.
    private func unloadedCommands() -> RecordingCommands {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print \(domain)/\(current)"] = (113, "")
        commands.responses["/bin/launchctl print \(domain)/\(legacy)"] = (113, "")
        return commands
    }

    @MainActor private func runJob(commands: RecordingCommands) async throws {
        let job = assessment(commands: commands).makeJob()
        try await job.run(context: StartupJobContext(privileged: RecordingPrivileged(), progress: { _ in }))
    }

    private func assessment(commands: RecordingCommands = RecordingCommands()) -> LaunchAgentAssessment {
        LaunchAgentAssessment(spec: spec(), plistURL: plistURL, directoriesToCreate: [logsDirectory, supportDirectory],
                              stopMarkerURL: markerURL, supersededLabels: [legacy],
                              supersededPlistURLs: [legacyPlistURL], commands: commands)
    }

    private func rendered() -> Data { LaunchAgentPlist.render(spec()) }
    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
