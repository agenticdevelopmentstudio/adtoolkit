import AgenticToolkitCore
import Foundation

/// Runs `claude` on the app's behalf.
///
/// **Only `claude`, and only for what `claude` alone can answer**: whether a
/// login is live, and logging out. Credentials are not read or written here —
/// The app's own items go through `ClaudeKeychain`, and Claude Code's item
/// through `ClaudeCodeKeychainItem`.
///
/// Nothing here mints. `claude setup-token` does, and it has its own runner
/// (`ClaudeSetupTokenMinter`) reached only when the user asks for a token.
public enum ClaudeAuthCLI {

    public enum CLIError: Error, LocalizedError, Sendable {
        case binaryNotFound(String)
        case launchFailed(String)
        case nonZeroExit(command: String, code: Int32, message: String)
        case timedOut(String)
        case noTokenInOutput(String)

        public var errorDescription: String? {
            switch self {
            case .binaryNotFound(let name):
                return "\(name) not found — looked in ~/.local/bin, /usr/local/bin and /opt/homebrew/bin."
            case .launchFailed(let message):
                return "Couldn't launch the command: \(message)"
            case .nonZeroExit(let command, let code, let message):
                return message.isEmpty ? "\(command) failed (exit \(code))" : message
            case .timedOut(let command):
                return "\(command) took too long and was stopped."
            case .noTokenInOutput(let message):
                return message.isEmpty
                    ? "No token appeared in the output of `claude setup-token`."
                    : "No token appeared in the output of `claude setup-token`:\n\(message)"
            }
        }
    }

    /// What a finished command said.
    public struct Output: Sendable {
        public let stdout: String
        public let stderr: String
        public let status: Int32

        public var isSuccess: Bool { status == 0 }

        /// What to put in front of a person: these CLIs write their refusals to
        /// stderr and their answers to stdout, so prefer stderr and fall back.
        public var message: String { stderr.isEmpty ? stdout : stderr }
    }

    // MARK: - Binaries

    /// Delegates to `ClaudeCLI.findBinary()`, which searches the native, Homebrew
    /// and Node version-manager install locations. `PATH` is deliberately not
    /// consulted: an app launched from Finder inherits no login shell.
    public static func claudeBinary() -> String? { ClaudeCLI.findBinary() }

    // MARK: - The CLI

    /// Runs `claude <arguments>`, throwing on a non-zero exit.
    @discardableResult
    public static func claude(
        _ arguments: [String],
        timeout: TimeInterval = 120
    ) async throws -> Output {
        guard let binary = claudeBinary() else { throw CLIError.binaryNotFound("claude") }
        let output = try await run(executable: binary, arguments: arguments, timeout: timeout)
        guard output.isSuccess else {
            throw CLIError.nonZeroExit(
                command: "claude " + arguments.joined(separator: " "),
                code: output.status,
                message: output.message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output
    }

    // MARK: - Process plumbing

    /// Runs `executable` and returns everything it said — and always returns.
    ///
    /// The run is `CommandRunner.runToCompletion` on a `BlockingWork` thread:
    /// stdout and stderr are drained concurrently with the child (one that
    /// outran the ~64KB pipe buffer would otherwise deadlock against the
    /// wait), the exit is learnt from a `terminationHandler` installed before
    /// launch, and the wait is bounded by `timeout` whatever the child does.
    ///
    /// **Never `Process.waitUntilExit()` here.** On macOS 26.6 it can miss the
    /// wake-up for a child that exits within a few milliseconds and park its
    /// thread forever — about one call in five against `/usr/bin/true`, about
    /// one credential round in a thousand against `security`. The child is
    /// gone and reaped by then, so a timeout that watches `isRunning` never
    /// fires either. One such run held a credential round open for good and
    /// froze every later "Switching to …" behind it.
    ///
    /// `input` is written to the child's stdin, and stdin closed, **before**
    /// launch — how a secret reaches `security -i` without ever appearing in
    /// an argv that `ps` can show, and how a `claude` that decides to prompt
    /// sees EOF and gives up rather than block on a terminal that isn't
    /// there. A pipe is a kernel buffer, so the input must fit one unread:
    /// 64 KB on macOS, and `security -i` reads at most
    /// `ClaudeCodeKeychainItem.interactiveLineLimit` of it anyway.
    public static func run(
        executable: String,
        arguments: [String],
        input: Data? = nil,
        timeout: TimeInterval = 180
    ) async throws -> Output {
        let environment = childEnvironment(executable: executable)
        let outcome: CommandRunner.Outcome
        do {
            // `Process` is not Sendable, so it is built on the thread that runs it.
            outcome = try await BlockingWork.run(qos: .default, enforcedQoS: .default) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.environment = environment

                let stdinPipe = Pipe()
                process.standardInput = stdinPipe
                if let input { try stdinPipe.fileHandleForWriting.write(contentsOf: input) }
                try stdinPipe.fileHandleForWriting.close()

                return try CommandRunner.runToCompletion(process, timeout: timeout)
            }
        } catch {
            throw CLIError.launchFailed(error.localizedDescription)
        }

        if outcome.timedOut {
            throw CLIError.timedOut(([executable] + arguments).joined(separator: " "))
        }
        return Output(
            stdout: String(data: outcome.standardOutput, encoding: .utf8) ?? "",
            stderr: String(data: outcome.standardError, encoding: .utf8) ?? "",
            status: outcome.status)
    }

    /// The environment a child of *this app* should run in.
    ///
    /// Two deliberate edits. `AGENTIC_TOOLKIT_HEADLESS` marks these as
    /// programmatic invocations so a session tracker's hooks don't record them
    /// as sessions. And the per-terminal account pins are **removed**: the app
    /// may itself have been launched from a terminal carrying a credential of
    /// its own in the environment, and a panel about the machine-wide login must
    /// not answer for whichever account that terminal happened to be billing.
    ///
    /// `PATH` leads with `executable`'s own directory, so a script-installed
    /// `claude` finds the `node` beside it.
    static func childEnvironment(executable: String) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = ClaudeCLI.searchPath(
            claudeDirectory: ClaudeCLI.directory(ofBinary: executable), inheritedPath: env["PATH"])
        env["AGENTIC_TOOLKIT_HEADLESS"] = "1"
        env["CLAUDE_CODE_OAUTH_TOKEN"] = nil
        env["ANTHROPIC_API_KEY"] = nil
        env["ANTHROPIC_AUTH_TOKEN"] = nil
        env["CLAUDE_ACCT_TOKENS"] = nil
        env["CLAUDE_ACCT_NAME"] = nil
        return env
    }
}
