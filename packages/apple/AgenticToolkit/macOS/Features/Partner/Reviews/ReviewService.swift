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
    /// ``UserSettings/partnerReviewsConcurrency`` reviews are already running, across all repos.
    case concurrencyLimit(Int)

    public var errorDescription: String? {
        switch self {
        case .notFound(let id): return "no review \(id)"
        case .notQueued(let id, let state): return "review \(id) is \(state.rawValue), not queued"
        case .anotherRunningInRepo(let repo): return "another review is already running in \(repo)"
        case .cannotFinish(let id, let state): return "review \(id) cannot be finished as or from \(state.rawValue)"
        case .concurrencyLimit(let limit):
            return "\(limit) review\(limit == 1 ? " is" : "s are") already running, the most allowed at once"
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

    /// Queued reviews oldest first, the running ones (so a partner with a fresh conversation can see what
    /// holds the limit), the concurrency limit, and how many are running.
    public func next() throws -> (reviews: [PartnerReview], runningReviews: [PartnerReview], concurrency: Int,
                                  running: Int) {
        let concurrency = max(1, settings.get(UserSettings.partnerReviewsConcurrency))
        let running = try store.reviews(state: .running)
        return (try store.reviews(state: .queued), running, concurrency, running.count)
    }

    /// Starts one queued review: skips it when its commit has left the branch, otherwise brings the repo's
    /// review worktree to the branch tip, works out what later commits changed, opens a session in the worktree
    /// and returns the job's steps filled in. A failure in the git work marks the review `failed`, raises a
    /// `blocked` attention item and is rethrown, so a review never stays queued because git failed. A store
    /// failure after that leaves the review queued, closes any session it opened and is rethrown; nothing ever
    /// leaves it running without a session.
    public func start(id: String) async throws -> PartnerReviewStart {
        guard let review = try store.review(id: id) else { throw ReviewError.notFound(id) }
        guard review.state == .queued else { throw ReviewError.notQueued(id, review.state) }
        let running = try store.reviews(state: .running)
        guard !startingRepos.contains(review.repoID), !running.contains(where: { $0.repoID == review.repoID }) else {
            throw ReviewError.anotherRunningInRepo(review.repoName)
        }
        // The guidelines ask the partner to respect the limit; this holds it to it. Starts still in their git
        // work count, so overlapping starts in different repos cannot together pass it.
        let limit = max(1, settings.get(UserSettings.partnerReviewsConcurrency))
        guard running.count + startingRepos.count < limit else { throw ReviewError.concurrencyLimit(limit) }
        startingRepos.insert(review.repoID)
        defer { startingRepos.remove(review.repoID) }

        let baseFixBranch = try store.reviewSetting(repoID: review.repoID, key: "fix_branch")
            .flatMap { $0.isEmpty ? nil : $0 } ?? settings.get(UserSettings.partnerReviewsFixBranch)
        let prepared: Prepared
        do {
            switch try await prepare(review, baseFixBranch: baseFixBranch) {
            case .skip(let reason): return try skip(review, reason: reason, fixBranch: baseFixBranch)
            case .ready(let found): prepared = found
            }
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
        var started = current
        started.state = .running
        started.sessionID = session.id.uuidString
        started.startedAt = now()
        started.supersededBy = prepared.superseded
        do {
            try store.updateReview(started)
        } catch {
            sessions.close(id: session.id)
            throw error
        }
        do {
            try store.setReviewSetting(repoID: review.repoID, key: prepared.worktreeKey,
                                       value: prepared.worktree.path)
        } catch {
            Self.logger.error("Recording the review worktree failed: \(error.localizedDescription)")
        }

        let model = settings.get(UserSettings.partnerReviewsReviewerModel)
        let values = [
            "repo": review.repoName, "path": prepared.worktree.path, "branch": review.branch, "sha": review.sha,
            "parent": review.parent, "subject": review.subject, "model": model, "fix_branch": prepared.fixBranch,
            "superseded": prepared.superseded.isEmpty ? "none" : prepared.superseded.joined(separator: ", ")
        ]
        return PartnerReviewStart(review: started, worktreePath: prepared.worktree.path, fixBranch: prepared.fixBranch,
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

    /// At every partner start: each review left `running` whose session is not open in this process goes back
    /// to the queue, since nothing can finish it any more. A review whose session is still open stays running.
    /// Returns how many were requeued.
    public func requeueInterrupted() throws -> Int {
        let open = Set(sessions.sessions.map(\.id.uuidString))
        let interrupted = try store.reviews(state: .running).filter { review in
            guard let sessionID = review.sessionID else { return true }
            return !open.contains(sessionID)
        }
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
        /// The `review_setting` key the worktree's path is recorded under.
        var worktreeKey: String
        var fixBranch: String
        var superseded: [String]
        var tipDiff: String
    }

    private enum Preparation {
        case skip(String)
        case ready(Prepared)
    }

    /// The default branch's reviews use `baseFixBranch` and `reviews/<repo>-<id>`; any other branch gets
    /// `<base>-<branch>` and `reviews/<repo>-<id>-<branch>`, since git checks a branch out in one worktree only.
    /// `<id>` is the first 8 characters of the repo id, so two listed repos with one name get two directories.
    /// A worktree already recorded for the repo and branch is reused wherever it is: its fix branch is checked
    /// out there, and git refuses to check it out a second time.
    private func prepare(_ review: PartnerReview, baseFixBranch: String) async throws -> Preparation {
        let repo = URL(fileURLWithPath: review.repoPath)
        let branchRef = "refs/heads/\(review.branch)"
        guard try await git.resolveCommit(branchRef, in: repo) != nil else {
            return .skip("branch \(review.branch) no longer exists")
        }
        guard try await git.isAncestor(review.sha, of: branchRef, in: repo) else {
            return .skip("commit is no longer in \(review.branch)")
        }

        let isDefault = try await review.branch == git.defaultBranch(in: repo)
        let suffix = isDefault ? "" : "-\(Self.refSafe(review.branch))"
        let fixBranch = baseFixBranch + suffix
        let worktreeKey = isDefault ? "worktree_path" : "worktree_path:\(review.branch)"
        let directory = try store.reviewSetting(repoID: review.repoID, key: worktreeKey)
            .flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) }
            ?? paths.reviewsDirectory.appendingPathComponent(Self.worktreeName(review) + suffix)
        try FileManager.default.createDirectory(at: paths.reviewsDirectory, withIntermediateDirectories: true)
        _ = try await worktree.prepare(repo: repo, branch: review.branch, fixBranch: fixBranch, worktree: directory)

        let files = try await git.changedFiles(parent: review.parent, sha: review.sha, in: repo)
        let superseded = try await git.supersedingCommits(after: review.sha, on: branchRef, files: files, in: repo)
        let tipDiff = try await git.tipDiff(from: review.sha, to: branchRef, files: files, in: repo)
        return .ready(Prepared(worktree: directory, worktreeKey: worktreeKey,
                               fixBranch: fixBranch, superseded: superseded, tipDiff: tipDiff))
    }

    /// `<repo name>-<first 8 of the repo id>`, both made safe as a file name.
    static func worktreeName(_ review: PartnerReview) -> String {
        "\(refSafe(review.repoName))-\(refSafe(review.repoID).prefix(8))"
    }

    /// `name` with every character git refuses in a ref, and `/`, turned into `-`; also safe as a file name.
    static func refSafe(_ name: String) -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        var result = String(name.map { allowed.contains($0) ? $0 : "-" })
        while result.contains("..") { result = result.replacingOccurrences(of: "..", with: "-") }
        if result.hasSuffix(".lock") { result.removeLast(".lock".count) }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return result.isEmpty ? "-" : result
    }

    /// Writes only over a review still queued: one finished while git ran keeps what its finisher wrote.
    private func skip(_ review: PartnerReview, reason: String, fixBranch: String) throws -> PartnerReviewStart {
        guard var skipped = try store.review(id: review.id), skipped.state == .queued else {
            let current = try store.review(id: review.id) ?? review
            return PartnerReviewStart(review: current, worktreePath: "", fixBranch: fixBranch, tipDiff: "",
                                      steps: [])
        }
        skipped.state = .skipped
        skipped.skipReason = reason
        skipped.finishedAt = now()
        try store.updateReview(skipped)
        return PartnerReviewStart(review: skipped, worktreePath: "", fixBranch: fixBranch, tipDiff: "", steps: [])
    }

    /// Like `skip`, leaves a review someone finished while git ran alone, and raises no item for it.
    private func markFailed(_ review: PartnerReview, reason: String) {
        do {
            guard var failed = try store.review(id: review.id), failed.state == .queued else { return }
            failed.state = .failed
            failed.summary = reason
            failed.finishedAt = now()
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
