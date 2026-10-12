import AgenticToolkitCore
import Foundation

/// Shells out to `ps -p <pid> -o tty=` to find the controlling TTY for a process.
///
/// Returned strings look like `s001` (no `/dev/` prefix). Callers needing the
/// device path can prepend `/dev/` themselves.
enum TTYResolver {

    /// `ps` answers in milliseconds; a run past this is one that will not answer.
    private static let timeout: TimeInterval = 10

    /// Returns the controlling TTY for the given PID, or nil if the process is
    /// gone, has no TTY, or `ps` failed or did not finish.
    static func tty(forPID pid: Int32) -> String? {
        guard pid > 0 else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "tty="]

        guard let outcome = try? CommandRunner.runToCompletion(process, timeout: timeout),
              !outcome.timedOut
        else { return nil }
        let tty = String(data: outcome.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return tty.isEmpty ? nil : tty
    }
}
