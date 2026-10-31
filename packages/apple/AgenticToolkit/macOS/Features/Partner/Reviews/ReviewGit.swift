import Foundation
import AgenticToolkitCore

/// The git verbs the Coding Partner's reviews need, as a thin facade over `GitClient`, the toolkit's only
/// door to git. Failures are `GitClientError`; `.commandFailed` carries git's exit status and stderr.
public struct ReviewGit: Sendable {

    /// The hash of git's empty tree: the "parent" of a root commit, so a diff against it still works.
    public static let emptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

    private let client: GitClient

    public init(client: GitClient = .shared) {
        self.client = client
    }

    /// Runs `git <arguments>` in `directory`; the first argument is the verb.
    public func run(_ arguments: [String], in directory: URL) async throws -> String {
        guard let verb = arguments.first else {
            throw GitClientError.launchFailed(verb: "", reason: "no git verb given")
        }
        return try await client.run(verb, Array(arguments.dropFirst()), in: directory)
    }

    /// The target of `origin/HEAD`, else `main`, else `master`, else the current branch (`HEAD` when detached).
    public func defaultBranch(in repo: URL) async throws -> String {
        if let origin = try? await run(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], in: repo)
            .trimmingCharacters(in: .whitespacesAndNewlines), origin.hasPrefix("origin/") {
            return String(origin.dropFirst("origin/".count))
        }
        let branches = try await localBranches(in: repo)
        for candidate in ["main", "master"] where branches.contains(candidate) { return candidate }
        return try await client.currentBranch(in: repo) ?? "HEAD"
    }

    public func localBranches(in repo: URL) async throws -> [String] {
        try await client.branches(in: repo).map(\.name)
    }

    /// Exit status 1 from `merge-base --is-ancestor` is the answer "no", not a failure.
    public func isAncestor(_ sha: String, of branch: String, in repo: URL) async throws -> Bool {
        do {
            _ = try await run(["merge-base", "--is-ancestor", sha, branch], in: repo)
            return true
        } catch GitClientError.commandFailed(_, 1, _) {
            return false
        }
    }

    /// The first parent of `sha`; the empty tree for a root commit.
    public func parent(of sha: String, in repo: URL) async throws -> String {
        let parents = try await run(["rev-list", "--parents", "-n", "1", sha], in: repo)
            .split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        return parents.count > 1 ? parents[1] : Self.emptyTree
    }

    public func changedFiles(parent: String, sha: String, in repo: URL) async throws -> [String] {
        lines(try await run(["diff", "--name-only", parent, sha], in: repo))
    }

    /// Commits after `sha` on `branch` that touch any of `files`, newest first.
    public func supersedingCommits(after sha: String, on branch: String, files: [String],
                                   in repo: URL) async throws -> [String] {
        guard !files.isEmpty else { return [] }
        return lines(try await run(["log", "--format=%H", "\(sha)..\(branch)", "--"] + files, in: repo))
    }

    /// The diff of `files` from `sha` to the tip of `branch`, cut at `maxBytes`.
    public func tipDiff(from sha: String, to branch: String, files: [String], in repo: URL,
                        maxBytes: Int = 200_000) async throws -> String {
        let diff = try await run(["diff", sha, branch, "--"] + files, in: repo)
        guard diff.utf8.count > maxBytes else { return diff }
        // Back off at most three bytes so the cut never lands inside a multi-byte character.
        for cut in stride(from: maxBytes, through: max(0, maxBytes - 3), by: -1) {
            if let text = String(diff.utf8.prefix(cut)) { return text }
        }
        return ""
    }

    /// No modified, staged or untracked files; submodule changes follow the client's submodule setting.
    public func isClean(worktree: URL) async throws -> Bool {
        try await client.status(in: worktree).files.isEmpty
    }

    private func lines(_ output: String) -> [String] {
        output.split(separator: "\n").map(String.init)
    }
}
