import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitLaunch

/// Records every command and answers from `responses` (key: argv joined by
/// a space); anything unlisted succeeds with no output.
final class RecordingCommands: CommandRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [[String]] = []
    private var _responses: [String: (Int32, String)] = [:]
    var responses: [String: (Int32, String)] {
        get { lock.withLock { _responses } }
        set { lock.withLock { _responses = newValue } }
    }
    private var _sequences: [String: [(Int32, String)]] = [:]
    var calls: [[String]] { lock.withLock { _calls } }

    /// Answers the next calls of `argv` in order, one entry per call, before
    /// falling back to `responses` (for a command whose answer changes).
    func respond(to argv: [String], inOrder answers: [(Int32, String)]) {
        lock.withLock { _sequences[argv.joined(separator: " ")] = answers }
    }

    func run(_ argv: [String]) async -> (status: Int32, output: String) {
        let key = argv.joined(separator: " ")
        let queued: (Int32, String)? = lock.withLock {
            _calls.append(argv)
            guard var pending = _sequences[key], !pending.isEmpty else { return nil }
            let next = pending.removeFirst()
            _sequences[key] = pending
            return next
        }
        return queued ?? responses[key] ?? (0, "")
    }
}

/// Answers `capture` with separate stdout and stderr, so a test can prove a
/// parser reads stdout only.
struct SplitCommands: CommandRunning {
    let status: Int32
    let stdout: String
    let stderr: String
    func run(_ argv: [String]) async -> (status: Int32, output: String) { (status, stdout + stderr) }
    func capture(_ argv: [String], environment: [String: String]?) async
        -> (status: Int32, stdout: String, stderr: String) { (status, stdout, stderr) }
}

@MainActor final class RecordingPrivileged: PrivilegedRunner {
    var calls: [[String]] = []
    func run(_ argv: [String]) async throws { calls.append(argv) }
}

@MainActor final class ProgressMessages {
    private(set) var items: [String] = []
    func append(_ message: String) { items.append(message) }
}
