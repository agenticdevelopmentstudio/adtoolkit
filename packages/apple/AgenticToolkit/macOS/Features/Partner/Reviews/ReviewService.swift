import Foundation
import AgenticToolkitCore
import os

/// Why a review tool refused.
public enum ReviewError: Error, LocalizedError, Equatable {
    case notFound(String)
    /// `start` takes only a queued review.
    case notQueued(String, PartnerReviewState)
    /// Reviews in one repo share its worktree, so they run one at a time.
    case anotherRunningInRepo(String)
    /// `finish` takes `done`, `failed` or `skipped`, for a review that is still queued or running.
    case cannotFinish(String, PartnerReviewState)

    public var errorDescription: String? {
        switch self {
        case .notFound(let id): return "no review \(id)"
        case .notQueued(let id, let state): return "review \(id) is \(state.rawValue), not queued"
        case .anotherRunningInRepo(let repo): return "another review is already running in \(repo)"
        case .cannotFinish(let id, let state): return "review \(id) cannot be finished as or from \(state.rawValue)"
        }
    }
}

/// The app's half of a code review: the git checks, the worktree, the session and the bookkeeping behind
/// `partner_review_next`, `partner_review_start` and `partner_review_finish`. What a session's screen means is
/// the partner's call, not this type's.
@MainActor
public final class ReviewService {

    private let store: PartnerStore
    private let sessions: PartnerSessionRegistry
    private let notifier: PartnerNotifier
    private let paths: PartnerPaths
    private let git: ReviewGit
    private let worktree: ReviewWorktree
    private let settings: SettingsStore
    private let steps: () -> [PartnerJobStep]
    private let now: () -> Date

    /// Repos with a `start` between its checks and its final write. Taken before the first suspension, so two
    /// overlapping starts in one repo cannot both pass the one-at-a-time check while git runs.
    private var startingRepos: Set<String> = []

    public init(store: PartnerStore, sessions: PartnerSessionRegistry, notifier: PartnerNotifier, paths: PartnerPaths,
                git: ReviewGit = ReviewGit(), worktree: ReviewWorktree = ReviewWorktree(),
                settings: SettingsStore = UserSettings.shared, steps: @escaping () -> [PartnerJobStep],
                now: @escaping () -> Date = Date.init) {
        self.store = store
        self.sessions = sessions
        self.notifier = notifier
        self.paths = paths
        self.git = git
        self.worktree = worktree
        self.settings = settings
        self.steps = steps
        self.now = now
    }

    /// Queued reviews oldest first, the concurrency limit, and how many are running.
    public func next() throws -> (reviews: [PartnerReview], concurrency: Int, running: Int) {
        let concurrency = max(1, settings.get(UserSettings.partnerReviewsConcurrency))
        return (try store.reviews(state: .queued), concurrency, try store.reviewCounts().running)
    }

    /// Starts one queued review: skips it when its commit has left the branch, otherwise brings the repo's
    /// review worktree to the branch tip, works out what later commits changed, opens a session in the worktree
    /// and returns the job's steps filled in. Any failure on the way marks the review `failed`, raises a
    /// `blocked` attention item and is rethrown, so a review never stays queued or running because git failed.
    public func start(id: String) async throws -> PartnerReviewStart {
        guard let review = try store.review(id: id) else { throw ReviewError.notFound(id) }
        guard review.state == .queued else { throw ReviewError.notQueued(id, review.state) }
        guard !startingRepos.contains(review.repoID),
              try !store.reviews(state: .running).contains(where: { $0.repoID == review.repoID }) else {
            throw ReviewError.anotherRunningInRepo(review.repoName)
        }
        startingRepos.insert(review.repoID)
        defer { startingRepos.remove(review.repoID) }

        let fixBranch = settings.get(UserSettings.partnerReviewsFixBranch)
        let prepared: Prepared
        do {
            guard let found = try await prepare(review, fixBranch: fixBranch) else {
                return try skip(review, fixBranch: fixBranch)
            }
            prepared = found
        } catch {
            markFailed(review, reason: Self.reason(error))
            throw error
        }

        // Finished or requeued by someone else while git ran: leave it as they left it.
        let latest = try store.review(id: id)
        guard let current = latest, current.state == .queued else {
            throw ReviewError.notQueued(id, latest?.state ?? review.state)
        }

        let session = sessions.open(directory: prepared.worktree.path, title: "review \(review.sha.prefix(7))",
                                    firstCommand: nil, reviewID: review.id)
        var running = current
        running.state = .running
        running.sessionID = session.id.uuidString
        running.startedAt = now()
        running.supersededBy = prepared.superseded
        do {
            try store.updateReview(running)
        } catch {
            sessions.close(id: session.id)
            throw error
        }
        do {
            try store.setReviewSetting(repoID: review.repoID, key: "worktree_path", value: prepared.worktree.path)
        } catch {
            Self.logger.error("Recording the review worktree failed: \(error.localizedDescription)")
        }

        let model = settings.get(UserSettings.partnerReviewsReviewerModel)
        let values = [
            "repo": review.repoName, "path": prepared.worktree.path, "branch": review.branch, "sha": review.sha,
            "parent": review.parent, "subject": review.subject, "model": model, "fix_branch": fixBranch,
            "superseded": prepared.superseded.isEmpty ? "none" : prepared.superseded.joined(separator: ", ")
        ]
        return PartnerReviewStart(review: running, worktreePath: prepared.worktree.path, fixBranch: fixBranch,
                                  tipDiff: prepared.tipDiff, steps: Self.fill(steps(), values: values))
    }

    /// Sets a queued or running review to `done`, `failed` or `skipped` and leaves a "review done" item for the
    /// owner. Closes nothing: the session stays for the owner to read.
    public func finish(id: String, state: PartnerReviewState, summary: String) throws -> PartnerReview {
        guard var review = try store.review(id: id) else { throw ReviewError.notFound(id) }
        guard [.done, .failed, .skipped].contains(state) else { throw ReviewError.cannotFinish(id, state) }
        guard [.queued, .running].contains(review.state) else { throw ReviewError.cannotFinish(id, review.state) }
        review.state = state
        review.summary = summary
        review.finishedAt = now()
        if state == .skipped, review.skipReason == nil { review.skipReason = summary }
        try store.updateReview(review)
        try notifier.notify(title: "review done",
                            body: "\(review.repoName) \(review.sha.prefix(7)) \(state.rawValue): \(summary)",
                            reference: ["review": review.id], createdBy: "partner")
        return review
    }

    /// At app start: every review left `running` by the last run goes back to the queue. Returns how many.
    public func requeueInterrupted() throws -> Int {
        let interrupted = try store.reviews(state: .running)
        for var review in interrupted {
            review.state = .queued
            review.sessionID = nil
            review.startedAt = nil
            try store.updateReview(review)
        }
        return interrupted.count
    }

    // MARK: - Start's parts

    private struct Prepared {
        var worktree: URL
        var superseded: [String]
        var tipDiff: String
    }

    /// `nil` when the commit is no longer in its branch.
    private func prepare(_ review: PartnerReview, fixBranch: String) async throws -> Prepared? {
        let repo = URL(fileURLWithPath: review.repoPath)
        let branchRef = "refs/heads/\(review.branch)"
        guard try await git.isAncestor(review.sha, of: branchRef, in: repo) else { return nil }

        let defaultBranch = try await git.defaultBranch(in: repo)
        let name = review.branch == defaultBranch
            ? review.repoName
            : "\(review.repoName)-\(review.branch.replacingOccurrences(of: "/", with: "-"))"
        let directory = paths.reviewsDirectory.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: paths.reviewsDirectory, withIntermediateDirectories: true)
        _ = try await worktree.prepare(repo: repo, branch: review.branch, fixBranch: fixBranch, worktree: directory)

        let files = try await git.changedFiles(parent: review.parent, sha: review.sha, in: repo)
        let superseded = try await git.supersedingCommits(after: review.sha, on: branchRef, files: files, in: repo)
        let tipDiff = try await git.tipDiff(from: review.sha, to: branchRef, files: files, in: repo)
        return Prepared(worktree: directory, superseded: superseded, tipDiff: tipDiff)
    }

    private func skip(_ review: PartnerReview, fixBranch: String) throws -> PartnerReviewStart {
        var skipped = review
        skipped.state = .skipped
        skipped.skipReason = "commit is no longer in \(review.branch)"
        skipped.finishedAt = now()
        try store.updateReview(skipped)
        return PartnerReviewStart(review: skipped, worktreePath: "", fixBranch: fixBranch, tipDiff: "", steps: [])
    }

    private func markFailed(_ review: PartnerReview, reason: String) {
        var failed = review
        failed.state = .failed
        failed.summary = reason
        failed.finishedAt = now()
        do {
            try store.updateReview(failed)
            try notifier.notify(kind: .blocked, title: "review of \(review.repoName) \(review.sha.prefix(7)) failed",
                                body: reason, reference: ["review": review.id], createdBy: "partner")
        } catch {
            Self.logger.error("Recording review \(review.id) as failed: \(error.localizedDescription)")
        }
    }

    private static func reason(_ error: Error) -> String {
        switch error {
        case ReviewWorktree.Failure.dirty:
            return "the review worktree has uncommitted changes"
        case ReviewWorktree.Failure.rebaseConflict(let detail):
            return "rebasing the fix branch onto the tip conflicted: \(detail)"
        case ReviewWorktree.Failure.notReviewWorktree(let detail):
            return detail
        default:
            return error.localizedDescription
        }
    }

    /// An empty model means Claude Code's own default: the `--model {model}` option is dropped, not left blank.
    static func fill(_ steps: [PartnerJobStep], values: [String: String]) -> [PartnerJobStep] {
        guard values["model"]?.isEmpty ?? true else { return PartnerStepTemplate.fill(steps, values: values) }
        let withoutModel = steps.map { step in
            var trimmed = step
            trimmed.command = step.command.replacingOccurrences(
                of: #"[ \t]*--model(?:[ \t]+|=)\{model\}"#, with: "", options: .regularExpression)
            return trimmed
        }
        return PartnerStepTemplate.fill(withoutModel, values: values)
    }
}

extension ReviewService: Loggable {
    public static nonisolated let logger = makeLogger()
}
