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
        /// The directory is not a worktree of the repo (another repo's checkout, a plain folder, the main
        /// checkout), so no destructive verb was run in it. Carries the reason.
        case notReviewWorktree(String)
    }

    private let git: ReviewGit

    public init(git: ReviewGit = ReviewGit()) {
        self.git = git
    }

    /// Brings `worktree` (on `fixBranch`) up to the tip of `branch` in `repo`, creating it when needed.
    public func prepare(repo: URL, branch: String, fixBranch: String, worktree: URL) async throws -> Outcome {
        guard let tip = try await git.resolveCommit("refs/heads/\(branch)", in: repo) else {
            throw GitClientError.commandFailed(verb: "resolve", exitStatus: 1,
                                               standardError: "no branch named \(branch)")
        }

        guard try await git.resolveCommit("refs/heads/\(fixBranch)", in: repo) != nil else {
            _ = try await git.run(["worktree", "add", "-b", fixBranch, worktree.path, tip], in: repo)
            return .created
        }

        if !FileManager.default.fileExists(atPath: worktree.path) {
            _ = try await git.run(["worktree", "prune"], in: repo)
            _ = try await git.run(["worktree", "add", worktree.path, fixBranch], in: repo)
        }

        // Observe the worktree before running anything destructive in it.
        let wanted = Self.canonical(worktree)
        guard let entry = try await git.worktrees(in: repo)
            .first(where: { !$0.isMain && !$0.isBare && Self.canonical($0.directory) == wanted }) else {
            throw Failure.notReviewWorktree("\(worktree.path) is not a worktree of \(repo.path)")
        }

        guard try await git.isClean(worktree: worktree) else { throw Failure.dirty }

        if entry.branch != fixBranch {
            // Detached, or on a branch of the session's own making: put it back on the fix branch first, so
            // the reset and rebase below move the branch and not whatever HEAD happened to be.
            _ = try await git.run(["switch", fixBranch], in: worktree)
        }

        guard let fix = try await git.resolveCommit("refs/heads/\(fixBranch)", in: repo) else {
            throw Failure.notReviewWorktree("branch \(fixBranch) disappeared from \(repo.path)")
        }
        if fix == tip { return .upToDate }

        if try await git.isAncestor(fix, of: tip, in: repo) {
            // The fix branch has nothing the tip lacks. It either sits on the tip's own line of history (the
            // tip simply moved on) or arrived through a merge: walking the tip's first parents down to fix
            // ends exactly on fix only in the first case.
            let walk = try await git.run(["rev-list", "--first-parent", "--parents", "\(fix)..\(tip)"], in: repo)
            let oldest = walk.split(separator: "\n").last?.split(separator: " ").dropFirst().first
            _ = try await git.run(["reset", "--hard", tip], in: worktree)
            return oldest.map(String.init) == fix ? .fastForwarded : .reset
        }

        do {
            _ = try await git.run(["rebase", tip, fixBranch], in: worktree)
        } catch {
            // Whatever stopped the rebase (a conflict, a timeout), never leave it half done. The abort's own
            // failure must not replace the rebase's error: that error is what the owner needs to read.
            var abortError: Error?
            do { _ = try await git.run(["rebase", "--abort"], in: worktree) } catch { abortError = error }
            throw Self.rebaseFailure(error, abortError: abortError)
        }
        return .rebased
    }

    /// The error a failed rebase is reported with: a git failure becomes ``Failure/rebaseConflict(_:)``
    /// with its stderr, and an abort that also failed is appended as "(abort failed: …)", so the worktree
    /// left mid-rebase is named. Anything else is passed on unless the abort failed too.
    static func rebaseFailure(_ error: Error, abortError: Error?) -> Error {
        let abortNote = abortError.map { abort -> String in
            var detail = abort.localizedDescription
            if case GitClientError.commandFailed(_, _, let standardError) = abort,
               !standardError.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                detail = standardError.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return " (abort failed: \(detail))"
        }
        if case GitClientError.commandFailed(_, _, let standardError) = error {
            return Failure.rebaseConflict(standardError + (abortNote ?? ""))
        }
        guard let abortNote else { return error }
        return Failure.rebaseConflict(error.localizedDescription + abortNote)
    }

    /// Standardized with symlinks resolved, so `/var/...` and `/private/var/...` compare equal.
    private static func canonical(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }
}
