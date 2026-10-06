import Foundation

/// Runs `claude -p` (the Claude Code CLI in print mode) to get a model reply without an
/// API key — it reuses the user's Claude Code login. Foundation-only and provider-shaped
/// so both the in-app `SessionSummarizer` and the daemon's `DaemonSessionSummarizer` share
/// one robust implementation instead of each copying the Process/Pipe plumbing.
public enum ClaudeCLI {

    public enum CLIError: Error, LocalizedError, Sendable {
        case binaryNotFound
        case launchFailed(String)
        case nonZeroExit(code: Int32, stderr: String)
        case emptyReply

        public var errorDescription: String? {
            switch self {
            case .binaryNotFound:
                return "Claude CLI not found (install Claude Code or check your PATH)"
            case .launchFailed(let message):
                return "Failed to launch claude: \(message)"
            case .nonZeroExit(let code, let stderr):
                return "claude -p failed: \(stderr.isEmpty ? "exit \(code)" : String(stderr.prefix(200)))"
            case .emptyReply:
                return "Empty reply from claude -p"
            }
        }
    }

    /// Every place a `claude` install lands, in priority order: the native
    /// installer, Homebrew/system prefixes, then the Node version managers
    /// (Volta, Bun, fnm, nvm's newest node) and a custom npm prefix.
    public static func findBinary(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        isExecutable: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) },
        listDirectory: (String) -> [String] = {
            (try? FileManager.default.contentsOfDirectory(atPath: $0)) ?? []
        }
    ) -> String? {
        let homePath = home.path
        var candidates = [
            "\(homePath)/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(homePath)/.claude/local/claude",
            "\(homePath)/.volta/bin/claude",
            "\(homePath)/.bun/bin/claude",
            "\(homePath)/.npm-global/bin/claude"
        ]
        if let prefix = environment["NPM_CONFIG_PREFIX"] ?? environment["npm_config_prefix"], !prefix.isEmpty {
            candidates.append(URL(fileURLWithPath: prefix).appendingPathComponent("bin/claude").path)
        }
        let fnmRoot = "\(homePath)/Library/Application Support/fnm/node-versions"
        for version in sortedVersions(listDirectory(fnmRoot)) {
            candidates.append("\(fnmRoot)/\(version)/installation/bin/claude")
        }
        let nvmRoot = "\(homePath)/.nvm/versions/node"
        for version in sortedVersions(listDirectory(nvmRoot)) {
            candidates.append("\(nvmRoot)/\(version)/bin/claude")
        }
        return candidates.first(where: isExecutable)
    }

    /// `v22.3.0` > `v20.0.0` > `v18.1.0`: numeric, newest first. Non-numeric
    /// components count as 0, so stray entries (`.DS_Store`) never crash.
    static func sortedVersions(_ names: [String]) -> [String] {
        func key(_ name: String) -> [Int] {
            name.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                .split(separator: ".").map { Int($0) ?? 0 }
        }
        return names.sorted { key($0).lexicographicallyPrecedes(key($1)) }.reversed()
    }

    /// The PATH a `claude` child needs: a GUI app inherits only the system
    /// directories, and an npm-installed `claude` is a `#!/usr/bin/env node`
    /// script. Order: `claudeDirectory` (when given), `~/.local/bin`,
    /// `/usr/local/bin`, `/opt/homebrew/bin`, then the inherited PATH.
    /// Repeated directories keep only their first (highest-priority) place.
    public static func searchPath(
        claudeDirectory: String? = nil,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        inheritedPath: String? = ProcessInfo.processInfo.environment["PATH"]
    ) -> String {
        let extras = ["\(home.path)/.local/bin", "/usr/local/bin", "/opt/homebrew/bin"]
        let inherited = (inheritedPath ?? "/usr/bin:/bin").split(separator: ":").map(String.init)
        var seen = Set<String>()
        return (([claudeDirectory].compactMap { $0 }) + extras + inherited)
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .joined(separator: ":")
    }

    /// The directory holding `binaryPath`, so a script-installed `claude`
    /// (`#!/usr/bin/env node`) finds the `node` that sits beside it.
    public static func directory(ofBinary binaryPath: String) -> String {
        URL(fileURLWithPath: binaryPath).deletingLastPathComponent().path
    }

    /// Runs `claude -p` with `prompt` on stdin and returns trimmed stdout.
    ///
    /// Robustness: stdout/stderr are drained CONCURRENTLY with the run (a child writing
    /// more than the ~64KB pipe buffer would otherwise deadlock against the wait), the wait
    /// happens off the cooperative pool (so a slow reply doesn't pin a concurrency thread),
    /// and stdin is written with the throwing API so a broken pipe can't raise an
    /// uncatchable Obj-C exception. An empty `model` omits `--model` (claude's default).
    public static func run(
        prompt: String,
        systemPrompt: String,
        model: String,
        timeout: TimeInterval
    ) async throws -> String {
        guard let claudePath = findBinary() else { throw CLIError.binaryNotFound }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        var args = ["-p", "--system-prompt", systemPrompt]
        if !model.isEmpty { args += ["--model", model] }
        process.arguments = args

        let stdinPipe = Pipe(), stdoutPipe = Pipe(), stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = searchPath(claudeDirectory: directory(ofBinary: claudePath))
        // Mark this as a programmatic/headless claude invocation so a session
        // tracker's hooks (which this child process inherits) can tell it apart
        // from a real interactive user session and not record it — e.g.
        // stenographer's EnvelopeBuilder drops events carrying this marker.
        env["AGENTIC_TOOLKIT_HEADLESS"] = "1"
        process.environment = env

        do {
            try process.run()
        } catch {
            throw CLIError.launchFailed(error.localizedDescription)
        }

        // A dead child closes the pipe; the legacy non-throwing write(_:) would raise an
        // uncatchable Obj-C exception on the broken pipe. A closed pipe here is benign.
        do {
            try stdinPipe.fileHandleForWriting.write(contentsOf: Data(prompt.utf8))
            try stdinPipe.fileHandleForWriting.close()
        } catch {
            // Child exited before reading stdin — read whatever it emitted.
        }

        let timeoutTask = Task {
            try? await Task.sleep(for: .seconds(timeout))
            if process.isRunning { process.terminate() }
        }
        async let stdoutData = readToEnd(stdoutPipe.fileHandleForReading)
        async let stderrData = readToEnd(stderrPipe.fileHandleForReading)
        await waitForExit(process)
        timeoutTask.cancel()

        let reply = (String(data: await stdoutData, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let stderr = (String(data: await stderrData, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            throw CLIError.nonZeroExit(code: process.terminationStatus, stderr: stderr)
        }
        guard !reply.isEmpty else { throw CLIError.emptyReply }
        return reply
    }

    /// Reads a file handle to EOF on a background queue — concurrent with the child, never
    /// blocking a Swift concurrency thread.
    private static func readToEnd(_ handle: FileHandle) async -> Data {
        await withCheckedContinuation { (continuation: CheckedContinuation<Data, Never>) in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: (try? handle.readToEnd()) ?? Data())
            }
        }
    }

    /// Awaits process exit off the cooperative pool (`waitUntilExit()` blocks its thread).
    private static func waitForExit(_ process: Process) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .utility).async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
    }
}
