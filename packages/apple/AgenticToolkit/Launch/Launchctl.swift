import Foundation
import AgenticToolkitCore

/// The `launchctl` plumbing launch jobs share: per-user targets and reading a
/// job's pid from `launchctl print`. One copy, so a parsing rule is fixed once.
public enum Launchctl {
    public static let path = "/bin/launchctl"

    /// The per-user GUI domain, `gui/<uid>`.
    public static func guiDomain(uid: uid_t = getuid()) -> String { "gui/\(uid)" }

    /// A job in the per-user GUI domain, `gui/<uid>/<label>`.
    public static func guiTarget(_ label: String, uid: uid_t = getuid()) -> String {
        "\(guiDomain(uid: uid))/\(label)"
    }

    /// The job's own pid from `launchctl print` stdout, or nil.
    ///
    /// Top-level only: the job's properties are indented by one tab, and nested
    /// blocks (`arguments = { … }`, endpoints) by more, and a nested `pid = 9`
    /// is not the job's. The value must be the whole rest of the line, so a
    /// line with trailing text never yields a number that was not the pid.
    /// `scripts/install_health.py`'s `parse_launchctl` holds the same rule.
    public static func topLevelPID(inPrint stdout: String) -> Int32? {
        guard let match = stdout.firstMatch(of: /(?m)^\tpid = (\d+)$/) else { return nil }
        return Int32(match.1)
    }

    /// The running pid of `target`, read from stdout only, or nil when the job
    /// is not loaded, not running, or `print` fails.
    public static func pid(of target: String, commands: any CommandRunning) async -> Int32? {
        let printed = await commands.capture([path, "print", target], environment: nil)
        guard printed.status == 0 else { return nil }
        return topLevelPID(inPrint: printed.stdout)
    }
}

/// Where an app bundle is running from.
public enum BundleLocation {
    /// A copy run from App Translocation (a quarantined download opened in
    /// place) lives under a random path that is gone after a reboot.
    public static func isTranslocated(_ bundleURL: URL) -> Bool {
        bundleURL.path.contains("/AppTranslocation/")
    }
}
