import Foundation

public enum PartnerReviewState: String, Codable, Sendable { case queued, running, done, failed, skipped }

/// One commit the partner reviews (or declines to review).
public struct PartnerReview: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var repoID: String
    public var repoPath: String
    public var repoName: String
    public var sha: String
    public var parent: String
    public var branch: String
    public var subject: String
    public var author: String
    public var committedAt: Date
    public var state: PartnerReviewState
    public var sessionID: String?
    public var startedAt: Date?
    public var finishedAt: Date?
    public var summary: String?
    public var skipReason: String?
    /// SHAs of later commits whose review replaced this one.
    public var supersededBy: [String]

    public init(
        id: String, repoID: String, repoPath: String, repoName: String, sha: String, parent: String,
        branch: String, subject: String, author: String, committedAt: Date, state: PartnerReviewState = .queued,
        sessionID: String? = nil, startedAt: Date? = nil, finishedAt: Date? = nil, summary: String? = nil,
        skipReason: String? = nil, supersededBy: [String] = []
    ) {
        self.id = id
        self.repoID = repoID
        self.repoPath = repoPath
        self.repoName = repoName
        self.sha = sha
        self.parent = parent
        self.branch = branch
        self.subject = subject
        self.author = author
        self.committedAt = committedAt
        self.state = state
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.summary = summary
        self.skipReason = skipReason
        self.supersededBy = supersededBy
    }
}

/// What `partner_review_start` returns.
public struct PartnerReviewStart: Codable, Sendable, Equatable {
    public var review: PartnerReview
    public var worktreePath: String
    public var fixBranch: String
    public var tipDiff: String
    public var steps: [PartnerJobStep]

    public init(review: PartnerReview, worktreePath: String, fixBranch: String, tipDiff: String,
                steps: [PartnerJobStep]) {
        self.review = review
        self.worktreePath = worktreePath
        self.fixBranch = fixBranch
        self.tipDiff = tipDiff
        self.steps = steps
    }
}
