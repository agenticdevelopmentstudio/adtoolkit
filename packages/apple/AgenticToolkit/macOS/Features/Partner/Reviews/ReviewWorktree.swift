import Foundation
import AgenticToolkitCore

/// Keeps one review worktree per repo on a fix branch and brings it up to the branch tip before each review.
public struct ReviewWorktree: Sendable {

    public enum Outcome: Sendable, Equatable { case created, fastForwarded, reset, rebased, upToDate }

    public enum Failure: Error, Equatable {
        /// The worktree has uncommitted or untracked changes; nothing was touched.
        case dirty
        /// Rebasing the fix branch onto the tip conflicted; the rebase was aborted. Carries git's stderr.
        case rebaseConflict(String)
    }

    private let git: ReviewGit

    public init(git: ReviewGit = ReviewGit()) {
        self.git = git
    }

    /// Brings `worktree` (on `fixBranch`) up to the tip of `branch` in `repo`, creating it when needed.
    public func prepare(repo: URL, branch: String, fixBranch: String, worktree: URL) async throws -> Outcome {
        let tip = try await sha(of: branch, in: repo)

        guard try await git.localBranches(in: repo).contains(fixBranch) else {
            _ = try await git.run(["worktree", "add", "-b", fixBranch, worktree.path, tip], in: repo)
            return .created
        }

        if !FileManager.default.fileExists(atPath: worktree.path) {
            _ = try await git.run(["worktree", "prune"], in: repo)
            _ = try await git.run(["worktree", "add", worktree.path, fixBranch], in: repo)
        }

        guard try await git.isClean(worktree: worktree) else { throw Failure.dirty }

        let fix = try await sha(of: fixBranch, in: repo)
        if fix == tip { return .upToDate }

        if try await git.isAncestor(fix, of: tip, in: repo) {
            // The fix branch has nothing the tip lacks. It either sits on the tip's own line of history
            // (the tip simply moved on) or arrived through a merge.
            let firstParentLine = try await git.run(["rev-list", "--first-parent", tip], in: repo)
                .split(separator: "\n").map(String.init)
            _ = try await git.run(["reset", "--hard", tip], in: worktree)
            return firstParentLine.contains(fix) ? .fastForwarded : .reset
        }

        do {
            _ = try await git.run(["rebase", tip], in: worktree)
        } catch GitClientError.commandFailed(_, _, let standardError) {
            _ = try? await git.run(["rebase", "--abort"], in: worktree)
            throw Failure.rebaseConflict(standardError)
        }
        return .rebased
    }

    private func sha(of ref: String, in repo: URL) async throws -> String {
        try await git.run(["rev-list", "-n", "1", ref], in: repo).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
