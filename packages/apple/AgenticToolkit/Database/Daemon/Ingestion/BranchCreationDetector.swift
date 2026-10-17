#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

// MARK: - Branch creation detection

extension DaemonDatabase {

    public struct BranchCreation {
        public let branchName: String
        public let repoPath: String
        public let source: String
    }

    /// Returns a `BranchCreation` when the hook event represents a branch
    /// being created — `EnterWorktree` (uses the response's `worktreeBranch`
    /// field) or a `Bash` command whose text creates a branch via
    /// `git worktree add -b …`, `git checkout -b …`, `git switch -c …`, or
    /// `git branch <name> …`. Returns nil for everything else.
    ///
    /// `repoPath` is the common git dir's parent, so every worktree of the
    /// same repo resolves to the same path — that's what the Stop hook
    /// matches against when it asks "did this session create this branch
    /// in this repo?".
    public func detectBranchCreation(
        eventType: String,
        toolName: String,
        cwd: String,
        hookData: [String: Any]
    ) -> BranchCreation? {
        guard eventType == "PostToolUse" else { return nil }

        if toolName == "EnterWorktree" {
            let response = hookData["tool_response"] as? [String: Any] ?? [:]
            let branch = (response["worktreeBranch"] as? String) ?? ""
            guard !branch.isEmpty else { return nil }
            let path = (response["worktreePath"] as? String)
                ?? (hookData["cwd"] as? String)
                ?? cwd
            let repo = resolveRepoRoot(path: path)
            return BranchCreation(branchName: branch, repoPath: repo, source: "EnterWorktree")
        }

        if toolName == "Bash" {
            let input = hookData["tool_input"] as? [String: Any] ?? [:]
            let command = (input["command"] as? String) ?? ""
            guard let branch = parseBashBranchCreation(command: command) else {
                return nil
            }
            let repo = resolveRepoRoot(path: cwd)
            return BranchCreation(branchName: branch, repoPath: repo, source: "Bash")
        }

        return nil
    }

    /// Subcommand regexes, compiled once. Applied to the portion of a
    /// command segment that follows the leading `git ` token, so they
    /// tolerate global options like `-C <path>` or `-c <key=val>`
    /// between `git` and the subcommand keyword.
    private static let branchSubcommandRegexes: [NSRegularExpression] = {
        let raw: [String] = [
            #"\bworktree\s+add\s+(?:[^-\s][^\s]*\s+)?-b\s+([^\s&|;]+)"#,
            #"\bworktree\s+add\s+-b\s+([^\s&|;]+)"#,
            #"\bcheckout\s+-b\s+([^\s&|;]+)"#,
            #"\bswitch\s+-c\s+([^\s&|;]+)"#,
            #"\bbranch\s+(?!-[dDmM]\b)(?!--(?:delete|move|list)\b)([^\s-][^\s&|;]*)"#
        ]
        return raw.compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    /// Pulls the branch name out of a shell command that creates a branch.
    /// Handles `git worktree add -b <name> …` / `git worktree add … -b <name>`,
    /// `git checkout -b <name> …`, `git switch -c <name>`, and
    /// `git branch <name>` (excluding `-d`/`-D`/`-m`/listing forms).
    ///
    /// Internal (not private) so unit tests can exercise it directly.
    public func parseBashBranchCreation(command: String) -> String? {
        for segment in Self.splitShellSegments(command) {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            // Only match segments where `git` is the invoked command —
            // rejects `echo git branch foo` where git is just an argument.
            guard trimmed.hasPrefix("git "), trimmed.count > 4 else { continue }
            let tail = String(trimmed.dropFirst(4))
            let range = NSRange(tail.startIndex..., in: tail)
            for regex in Self.branchSubcommandRegexes {
                guard let match = regex.firstMatch(in: tail, range: range),
                      match.numberOfRanges > 1,
                      let nameRange = Range(match.range(at: 1), in: tail)
                else { continue }
                let name = String(tail[nameRange])
                if !name.isEmpty { return name }
            }
        }
        return nil
    }

    /// Splits a shell command on top-level separators so each segment
    /// is a candidate invocation. Not a full shell parser — it doesn't
    /// honour quoting — but good enough to reject cases like
    /// `echo "run git branch x"` and to find the `git` call inside
    /// `cd /tmp && git branch x`, `$(git branch x)`, backticks, `{ ... ; }`.
    private static func splitShellSegments(_ command: String) -> [String] {
        var segments: [String] = []
        var current = ""
        for char in command {
            switch char {
            case "&", "|", ";", "`", "(", ")", "{", "}", "\n":
                segments.append(current)
                current = ""
            default:
                current.append(char)
            }
        }
        segments.append(current)
        return segments
    }

    /// Resolves a directory to the parent of its shared `.git` directory
    /// (`git rev-parse --git-common-dir`), so linked worktrees and the
    /// primary working tree for the same repo always produce the same path.
    /// Falls back to the given path on any error.
    private func resolveRepoRoot(path: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "-C", path, "rev-parse", "--path-format=absolute", "--git-common-dir"]
        // A `rev-parse` is milliseconds; one still running at the deadline is
        // parked on a lock or a dead mount and is given up on, not waited for.
        guard let outcome = try? CommandRunner.runToCompletion(process, timeout: Self.repoRootTimeout),
              !outcome.timedOut, outcome.status == 0
        else { return path }
        let gitDir = String(data: outcome.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !gitDir.isEmpty else { return path }
        return (gitDir as NSString).deletingLastPathComponent
    }

    private static let repoRootTimeout: TimeInterval = 30
}
#endif
