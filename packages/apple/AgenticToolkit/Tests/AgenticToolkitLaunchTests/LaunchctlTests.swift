import Testing
import Foundation
@testable import AgenticToolkitLaunch

@Suite struct LaunchctlTests {
    @Test func targetsAreInTheUsersGuiDomain() {
        #expect(Launchctl.guiDomain(uid: 501) == "gui/501")
        #expect(Launchctl.guiTarget("com.example.job", uid: 501) == "gui/501/com.example.job")
    }

    @Test func readsTheTopLevelPid() {
        #expect(Launchctl.topLevelPID(inPrint: "x = {\n\tstate = running\n\tpid = 4242\n}\n") == 4242)
    }

    /// The case `scripts/install_health.py`'s tests pin: a nested pid line
    /// before the job's own.
    @Test func ignoresANestedPid() {
        let printed = "x = {\n\targuments = {\n\t\tpid = 9\n\t}\n\tpid = 42\n}\n"
        #expect(Launchctl.topLevelPID(inPrint: printed) == 42)
    }

    @Test func rejectsTrailingText() {
        #expect(Launchctl.topLevelPID(inPrint: "\tpid = 4242 (x)\n") == nil)
    }

    @Test func nilWithoutAPid() {
        #expect(Launchctl.topLevelPID(inPrint: "x = {\n\tstate = waiting\n}\n") == nil)
    }

    @Test func pidReadsStdoutOnly() async {
        let commands = SplitCommands(status: 0, stdout: "\tstate = waiting\n", stderr: "\tpid = 7\n")
        #expect(await Launchctl.pid(of: "gui/501/x", commands: commands) == nil)
    }

    @Test func pidNilWhenPrintFails() async {
        let commands = SplitCommands(status: 113, stdout: "\tpid = 7\n", stderr: "")
        #expect(await Launchctl.pid(of: "gui/501/x", commands: commands) == nil)
    }

    @Test func pidAsksLaunchctlPrintForTheTarget() async {
        let commands = RecordingCommands()
        commands.responses["/bin/launchctl print gui/501/x"] = (0, "\tpid = 5\n")
        #expect(await Launchctl.pid(of: "gui/501/x", commands: commands) == 5)
        #expect(commands.calls == [["/bin/launchctl", "print", "gui/501/x"]])
    }

    @Test func translocationIsRecognized() {
        #expect(BundleLocation.isTranslocated(
            URL(fileURLWithPath: "/private/var/folders/xx/AppTranslocation/ABC/d/A.app")))
        #expect(!BundleLocation.isTranslocated(URL(fileURLWithPath: "/Applications/A.app")))
    }

    // MARK: Installed copy

    private func installed(_ path: String, home: String = "/Users/someone") -> Bool {
        BundleLocation.isInstalledCopy(bundleURL: URL(fileURLWithPath: path),
                                       homeDirectory: URL(fileURLWithPath: home))
    }

    @Test func isInstalledCopy() {
        #expect(installed("/Applications/X.app"))
        #expect(installed("/Applications/Sub/X.app"))
        #expect(installed("/Users/someone/Applications/X.app"))
        #expect(installed("/Users/someone/Applications/Sub/X.app"))
        #expect(!installed("/ApplicationsFoo/X.app"))
        #expect(!installed("/Users/someone/ApplicationsFoo/X.app"))
        #expect(!installed("/Users/someone/Downloads/X.app"))
        #expect(!installed("/Users/other/Applications/X.app"))
        #expect(!installed("/Users/someone/Library/Developer/Xcode/DerivedData/A/Build/Products/Debug/X.app"))
    }

    @Test func aTranslocatedCopyIsNotInstalled() {
        #expect(!installed("/private/var/folders/xx/AppTranslocation/ABC/d/Applications/X.app"))
    }

    @Test func dotDotCannotEscapeApplications() {
        #expect(!installed("/Applications/../Users/someone/Downloads/X.app"))
    }

    @Test func aSymlinkOutOfApplicationsIsNotInstalled() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("loc-\(UUID())")
        let outside = root.appendingPathComponent("Downloads/X.app")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let apps = root.appendingPathComponent("Applications")
        try FileManager.default.createDirectory(at: apps, withIntermediateDirectories: true)
        let link = apps.appendingPathComponent("X.app")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        // The temp root stands in for home, so `<root>/Applications` is the user's.
        #expect(!BundleLocation.isInstalledCopy(bundleURL: link, homeDirectory: root))
    }
}
