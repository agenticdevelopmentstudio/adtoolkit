//
//  CommandRunning.swift
//  AgenticToolkit
//

import Foundation

/// Runs an external command and reports its exit status and its output
/// (stdout followed by stderr, not interleaved).
/// The seam launch jobs use for `launchctl`, `pkgutil` and friends, so tests
/// can substitute a recorder.
///
/// Named `CommandRunning` because `CommandRunner` is the synchronous process
/// runner that `ProcessCommandRunner` wraps.
public protocol CommandRunning: Sendable {
    func run(_ argv: [String]) async -> (status: Int32, output: String)

    /// Like `run`, but keeps stdout and stderr apart (a command whose stdout
    /// is parsed must not see stderr noise) and, when `environment` is
    /// non-nil, replaces the child's environment with it.
    func capture(_ argv: [String], environment: [String: String]?) async
        -> (status: Int32, stdout: String, stderr: String)
}

extension CommandRunning {
    /// Doubles that only implement `run` get the merged output as stdout.
    public func capture(_ argv: [String], environment: [String: String]?) async
        -> (status: Int32, stdout: String, stderr: String) {
        let result = await run(argv)
        return (result.status, result.output, "")
    }

    /// `capture` with the inherited environment.
    public func capture(_ argv: [String]) async -> (status: Int32, stdout: String, stderr: String) {
        await capture(argv, environment: nil)
    }
}

/// Runs the command as a real child process, off the cooperative pool, on top
/// of `CommandRunner.runToCompletion`, which drains stdout and stderr while the
/// child writes (no 64 KB pipe-buffer deadlock).
///
/// A command that cannot be launched at all reports status -1 with the error
/// text rather than crashing. A command with no `/` in its name is looked up
/// on the child's `PATH` (the replacement environment's, when one is given),
/// as a shell would, and fails to launch when no directory holds it.
public struct ProcessCommandRunner: CommandRunning {
    /// Backstop for a wedged helper so a caller fails instead of hanging
    /// forever; the default is far past any legitimate helper run.
    public let backstop: TimeInterval

    public init(backstop: TimeInterval = 600) {
        self.backstop = backstop
    }

    // Default QoS, enforced: the drain threads run at default, and waiting on
    // them from the caller's (often main-thread) class is a priority inversion.
    public func run(_ argv: [String]) async -> (status: Int32, output: String) {
        let backstop = backstop
        return await BlockingWork.run(qos: .default, enforcedQoS: .default) {
            Self.runBlocking(argv, backstop: backstop)
        }
    }

    public func capture(_ argv: [String], environment: [String: String]?) async
        -> (status: Int32, stdout: String, stderr: String) {
        let backstop = backstop
        return await BlockingWork.run(qos: .default, enforcedQoS: .default) {
            Self.captureBlocking(argv, environment: environment, backstop: backstop)
        }
    }

    private static func captureBlocking(_ argv: [String], environment: [String: String]?,
                                        backstop: TimeInterval) -> (status: Int32, stdout: String, stderr: String) {
        guard let process = makeProcess(argv, environment: environment) else { return (-1, "", "empty command") }
        if let environment { process.environment = environment }
        do {
            let outcome = try CommandRunner.runToCompletion(process, timeout: backstop)
            let out = String(bytes: outcome.standardOutput, encoding: .utf8) ?? ""
            let err = String(bytes: outcome.standardError, encoding: .utf8) ?? ""
            guard !outcome.timedOut else { return (-1, out, err + "\ntimed out after \(backstop)s") }
            return (outcome.status, out, err)
        } catch {
            return (-1, "", error.localizedDescription)
        }
    }

    private static func makeProcess(_ argv: [String], environment: [String: String]? = nil) -> Process? {
        guard let executable = argv.first else { return nil }
        let process = Process()
        let searchPath = (environment ?? ProcessInfo.processInfo.environment)["PATH"]
        process.executableURL = URL(fileURLWithPath: resolve(executable, searchPath: searchPath))
        process.arguments = Array(argv.dropFirst())
        return process
    }

    /// `name` itself when it holds a `/` or no `PATH` directory has an
    /// executable by that name (the launch then fails with the error text);
    /// otherwise the first match on `searchPath`.
    static func resolve(_ name: String, searchPath: String?) -> String {
        guard !name.contains("/") else { return name }
        let directories = (searchPath ?? "/usr/bin:/bin:/usr/sbin:/sbin").split(separator: ":")
        for directory in directories where !directory.isEmpty {
            let candidate = "\(directory)/\(name)"
            if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }
        }
        return name
    }

    private static func runBlocking(_ argv: [String], backstop: TimeInterval) -> (status: Int32, output: String) {
        guard let process = makeProcess(argv) else { return (-1, "empty command") }
        do {
            let outcome = try CommandRunner.runToCompletion(process, timeout: backstop)
            let text = (String(bytes: outcome.standardOutput, encoding: .utf8) ?? "")
                + (String(bytes: outcome.standardError, encoding: .utf8) ?? "")
            // A child that traps SIGTERM may still exit 0; a timeout is never success.
            guard !outcome.timedOut else { return (-1, text + "\ntimed out after \(backstop)s") }
            return (outcome.status, text)
        } catch {
            return (-1, error.localizedDescription)
        }
    }
}
