import Foundation

/// Read-only `git` invocation for a status line or a hook helper.
///
/// `GIT_OPTIONAL_LOCKS=0` so `git status` (and friends) never take `index.lock`
/// to refresh the stat-cache: a status line re-renders constantly, and a
/// background `git` that grabs the index lock would race the user's own
/// commit/rebase/add in the same worktree ("Unable to create '…/index.lock'").
/// These calls only ever *read* git state, so they never need the index.
///
/// Commands run in this process's inherited working directory unless the
/// caller passes an explicit `-C <dir>`. Failures (a non-zero exit, a hang past
/// the timeout, or a spawn error) collapse to `""`.
public enum ReadOnlyGit {

    /// Run a read-only git command, returning trimmed stdout or "" on failure.
    public static func git(_ args: [String]) -> String {
        rawGit(args).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Run a read-only git command, returning stdout **byte-for-byte** (still ""
    /// on failure).
    ///
    /// Use this for any output whose leading or trailing whitespace carries
    /// meaning. `git status --porcelain` is the case that forced it: its `XY`
    /// prefix is always two columns, so an unstaged-only change on the
    /// alphabetically-first path begins with a literal space, and trimming eats
    /// it, turning a 24-byte status into a 22-byte one that git never emitted
    /// and that hashes differently for a purely cosmetic reason. Every
    /// *displayed* value wants the trim, which is why ``git(_:)`` is the default.
    public static func rawGit(_ args: [String]) -> String {
        let process = Process()
        // `/usr/bin/env` resolves `git` on PATH without a shell.
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + args

        var env = ProcessInfo.processInfo.environment
        env["GIT_OPTIONAL_LOCKS"] = "0"
        env["PATH"] = repairedPath(env["PATH"])
        process.environment = env

        // Drained while git writes, so a large branch listing can't fill the
        // pipe buffer and deadlock the child, and stopped after the timeout.
        // `Data()` is a closed stdin: a read-only git never prompts, but an EOF
        // guarantees it can't block waiting on one.
        guard let outcome = try? CommandRunner.runToCompletion(process, input: Data(), timeout: timeout),
              !outcome.timedOut, outcome.status == 0
        else { return "" }
        // Invalid UTF-8 → "" (git output is valid UTF-8; a failable decode here
        // swallows anything else).
        return String(bytes: outcome.standardOutput, encoding: .utf8) ?? ""
    }

    /// A status line re-renders constantly, so a git that hasn't answered within
    /// five seconds is dropped rather than waited on.
    private static let timeout: TimeInterval = 5

    /// Ensure `git` resolves even under the minimal PATH a GUI-launched status
    /// line inherits (`/usr/bin:/bin:/usr/sbin:/sbin`, no Homebrew). Apple's git
    /// shim lives at `/usr/bin/git`, but keep the common install dirs too.
    ///
    /// Public so a test spawning its own `git` (to build a fixture repo) repairs
    /// PATH the same way this does: a fixture that can't find `git` under
    /// Xcode's environment while the code under test can is a false red with no
    /// bug behind it.
    public static func repairedPath(_ current: String?) -> String {
        var parts = (current ?? "").split(separator: ":").map(String.init)
        for dir in ["/usr/bin", "/bin", "/usr/local/bin", "/opt/homebrew/bin"] where !parts.contains(dir) {
            parts.append(dir)
        }
        return parts.joined(separator: ":")
    }
}
