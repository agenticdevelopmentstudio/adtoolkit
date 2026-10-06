import XCTest
@testable import AgenticToolkitLaunch

final class BundleOwnershipTests: XCTestCase {
    private var home: URL!
    private let bundle = URL(fileURLWithPath: "/Applications/Example.app")

    override func setUpWithError() throws {
        home = FileManager.default.temporaryDirectory.appendingPathComponent("own-\(UUID())")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: home)
    }

    private func make(file url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("x".utf8).write(to: url)
    }

    private func make(directory url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func ownership(bundle: URL? = nil, owner: uid_t?, parentOwner: uid_t? = 0,
                           console: uid_t = 501) async -> [any StartupJob] {
        await BundleOwnershipAssessment(bundleURL: bundle ?? self.bundle, appName: "Example",
                                        ownerUID: { _ in owner }, parentOwnerUID: { _ in parentOwner },
                                        consoleUID: console).assess()
    }

    private func job(owner: uid_t, commands: RecordingCommands = RecordingCommands()) -> BundleOwnershipJob {
        BundleOwnershipJob(bundleURL: bundle, appName: "Example", consoleUID: 501, ownerUID: { _ in owner },
                           commands: commands)
    }

    func testTitleNamesTheApp() async throws {
        let jobs = await ownership(owner: 0)
        XCTAssertEqual(jobs.first?.title, "Letting Example update itself")
    }

    func testNothingWhenParentNotRootOwned() async {
        let jobs = await ownership(owner: 0, parentOwner: 501)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingWhenPathGoesThroughASymlink() async throws {
        let real = home.appendingPathComponent("real")
        try make(directory: real.appendingPathComponent("Example.app"))
        let link = home.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: real.path)
        let jobs = await ownership(bundle: link.appendingPathComponent("Example.app"), owner: 0)
        XCTAssertTrue(jobs.isEmpty)
    }

    @MainActor func testJobDoesNothingWhenNoLongerRootOwned() async throws {
        let privileged = RecordingPrivileged()
        try await job(owner: 501).run(context: StartupJobContext(privileged: privileged, progress: { _ in }))
        XCTAssertTrue(privileged.calls.isEmpty)
    }

    func testQueuedForRootOwnedBundle() async {
        let jobs = await ownership(owner: 0)
        XCTAssertEqual(jobs.map(\.id), ["bundle-ownership"])
        XCTAssertTrue(jobs[0].needsAdministrator)
    }

    @MainActor func testJobRunsOneScriptThroughPrivilegedRunner() async throws {
        let privileged = RecordingPrivileged()
        try await job(owner: 0).run(context: StartupJobContext(privileged: privileged, progress: { _ in }))
        XCTAssertEqual(privileged.calls,
                       [["/bin/sh", "-c", BundleOwnershipJob.privilegedScript, "sh",
                         "/Applications/Example.app", "501", "0"]])
        let script = BundleOwnershipJob.privilegedScript
        XCTAssertTrue(script.contains("-mindepth 1 -depth"))
        XCTAssertTrue(script.hasPrefix("/usr/bin/find "), "the root step runs last")
        XCTAssertTrue(script.contains("-execdir /usr/sbin/chown -h \"$2:staff\" {} +"))
        XCTAssertTrue(script.contains(#"\( -type d -o -links 1 \)"#))
        XCTAssertFalse(script.contains("/Applications"), "paths travel as arguments")
    }

    @MainActor func testJobReportsRootOwnedHardLinkedLeftovers() async throws {
        let commands = RecordingCommands()
        let find = ["/usr/bin/find", "/Applications/Example.app", "-xdev", "-user", "0",
                    "-type", "f", "-links", "+1"]
        commands.responses[find.joined(separator: " ")] = (0, "/Applications/Example.app/a\n/x/b\n")
        let notes = ProgressMessages()
        try await job(owner: 0, commands: commands)
            .run(context: StartupJobContext(privileged: RecordingPrivileged(), progress: { notes.append($0) }))
        XCTAssertEqual(commands.calls, [find])
        XCTAssertEqual(notes.items.count, 1)
        XCTAssertTrue(notes.items[0].contains("2 hard-linked"))
    }

    @MainActor func testJobSaysNothingWithoutLeftovers() async throws {
        let notes = ProgressMessages()
        try await job(owner: 0)
            .run(context: StartupJobContext(privileged: RecordingPrivileged(), progress: { notes.append($0) }))
        XCTAssertTrue(notes.items.isEmpty)
    }

    func testNothingForRelativePath() async {
        let jobs = await ownership(bundle: URL(string: "Rel.app")!, owner: 0)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingWhenUserOwned() async {
        let jobs = await ownership(owner: 501)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingWhenOwnedByAnotherUser() async {
        let jobs = await ownership(owner: 502)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingWhenConsoleUserIsRoot() async {
        let jobs = await ownership(owner: 0, console: 0)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingWhenOwnerUnknown() async {
        let jobs = await ownership(owner: nil)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingForTranslocatedBundle() async {
        let translocated = URL(fileURLWithPath: "/private/var/folders/xx/AppTranslocation/ABC/d/Example.app")
        XCTAssertTrue(BundleLocation.isTranslocated(translocated), "the assessment uses the shared rule")
        let jobs = await ownership(bundle: translocated, owner: 0)
        XCTAssertTrue(jobs.isEmpty)
    }

    func testNothingForNonAppPath() async {
        let jobs = await ownership(bundle: URL(fileURLWithPath: "/Applications"), owner: 0)
        XCTAssertTrue(jobs.isEmpty)
    }

    // MARK: Real tools

    private func runTool(_ path: String, _ arguments: [String], directory: String = "/") throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// `everyone`: a group the test user belongs to other than `staff` (20),
    /// so a chown to `<uid>:staff` shows up as a change of gid.
    private static let everyone: gid_t = 12

    private func gid(_ url: URL) -> gid_t? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.groupOwnerAccountID] as? NSNumber)?.uint32Value
    }

    /// Every item under `root`, `root` included, by lstat.
    private func tree(_ root: URL) -> [URL] {
        let below = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL } ?? []
        return [root] + below
    }

    private func setGroup(_ group: gid_t, under root: URL) {
        for item in tree(root) {
            XCTAssertEqual(lchown(item.path, uid_t.max, group), 0, "chgrp \(item.path)")
        }
    }

    /// Runs the REAL privileged script (`find` + perl) from cwd `/` over a temp
    /// tree owned by the test user, with `chown` swapped for a reporter that
    /// logs its cwd, its cwd's gid and its names, then calls the real
    /// `/usr/sbin/chown`. The tree starts in `everyone`, so a container already
    /// handed over (gid 20) at the time of a chown is the N1 race, visible.
    func testScriptChownsEveryEntryInsideAContainerNotYetHandedOver() throws {
        let bundleDir = home.appendingPathComponent("Real.app")
        try make(file: bundleDir.appendingPathComponent("Contents/Info.plist"))
        try make(file: bundleDir.appendingPathComponent("Contents/MacOS/Real"))
        try make(file: bundleDir.appendingPathComponent("Contents/Frameworks/A.framework/A"))
        try make(file: bundleDir.appendingPathComponent("Contents/Frameworks/A.framework/Resources/r"))
        setGroup(Self.everyone, under: bundleDir)
        let log = home.appendingPathComponent("chown.log")
        let reporter = home.appendingPathComponent("reporter.sh")
        let body = """
            #!/bin/sh
            d=$(pwd -P); g=$(/usr/bin/stat -f %g .); owner="$2"; shift 2
            for a in "$@"; do echo "$d|$g|$a" >> '\(log.path)'; done
            exec /usr/sbin/chown -h "$owner" "$@"

            """
        try Data(body.utf8).write(to: reporter)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: reporter.path)

        let uid = "\(getuid())"
        let status = try runTool("/bin/sh", ["-c", BundleOwnershipJob.privilegedScript(chown: reporter.path), "sh",
                                             bundleDir.path, uid, uid])
        XCTAssertEqual(status, 0)
        // `pwd -P` is physical (/private/var/...), so compare against the realpath.
        let physical = realpath(bundleDir.path, nil).map { String(cString: $0) } ?? bundleDir.path
        let lines = try String(contentsOf: log, encoding: .utf8).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, tree(bundleDir).count - 1, "every entry below the root, once: \(lines)")
        for line in lines {
            let parts = line.split(separator: "|", maxSplits: 2).map(String.init)
            XCTAssertTrue(parts[0].hasPrefix(physical), "chown ran outside the bundle: \(line)")
            XCTAssertEqual(parts[1], "\(Self.everyone)", "container already handed over at chown time: \(line)")
            XCTAssertNotEqual(parts[2], "Real.app", "the bundle root must not be chowned as a bare name")
        }
        XCTAssertTrue(lines.contains { $0.hasSuffix("|A.framework") })
        for item in tree(bundleDir) {
            XCTAssertEqual(gid(item), 20, "not handed over: \(item.path)")
        }
    }

    /// The perl step chowns the root through a handle, and only from the expected owner.
    func testPerlStepChownsTheRootThroughAHandle() throws {
        let dir = home.appendingPathComponent("Handle.app")
        try make(directory: dir)
        setGroup(Self.everyone, under: dir)
        let uid = "\(getuid())"
        // An owner other than the expected one exits quietly and changes nothing.
        XCTAssertEqual(try runTool("/usr/bin/perl", ["-e", BundleOwnershipJob.rootChownPerl, dir.path, uid, "0"]), 0)
        XCTAssertEqual(gid(dir), Self.everyone)
        XCTAssertEqual(try runTool("/usr/bin/perl", ["-e", BundleOwnershipJob.rootChownPerl, dir.path, uid, uid]), 0)
        XCTAssertEqual(gid(dir), 20)
    }

    func testPerlStepRefusesARegularFile() throws {
        let file = home.appendingPathComponent("File.app")
        try make(file: file)
        setGroup(Self.everyone, under: file)
        let uid = "\(getuid())"
        let status = try runTool("/usr/bin/perl", ["-e", BundleOwnershipJob.rootChownPerl, file.path, uid, uid])
        XCTAssertNotEqual(status, 0)
        XCTAssertEqual(gid(file), Self.everyone)
    }

    func testPerlStepRefusesASymlink() throws {
        let real = home.appendingPathComponent("Target")
        try make(directory: real)
        let link = home.appendingPathComponent("Link.app")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: real.path)
        let uid = "\(getuid())"
        let status = try runTool("/usr/bin/perl", ["-e", BundleOwnershipJob.rootChownPerl, link.path, uid, uid])
        XCTAssertNotEqual(status, 0)
    }
}
