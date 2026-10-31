import Foundation
import AgenticToolkitCore

public struct CrawledCommit: Sendable, Equatable {
    public var sha: String
    public var parent: String
    public var subject: String
    public var author: String
    public var committedAt: Date

    public init(sha: String, parent: String, subject: String, author: String, committedAt: Date) {
        self.sha = sha
        self.parent = parent
        self.subject = subject
        self.author = author
        self.committedAt = committedAt
    }
}

/// Finds recent commits per repo and queues a review for each one not yet seen.
public struct CommitCrawler: Sendable {
    private let git: ReviewGit

    public init(git: ReviewGit = ReviewGit()) {
        self.git = git
    }

    /// Non-merge commits on `branch` since `since`, oldest first. A root commit's parent is git's empty tree.
    public func commits(in repo: URL, branch: String, since: Date) throws -> [CrawledCommit] {
        var arguments = ["log", "--no-merges"]
        if since.timeIntervalSince1970 > 0 {
            arguments.append("--since=\(ISO8601DateFormatter().string(from: since))")
        }
        arguments += ["--format=%H%x1f%P%x1f%s%x1f%an%x1f%cI", branch]
        let formatter = ISO8601DateFormatter()
        let found: [CrawledCommit] = try git.run(arguments, in: repo).split(separator: "\n").compactMap { line in
            let fields = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 5, let date = formatter.date(from: fields[4]) else { return nil }
            let parent = fields[1].split(separator: " ").first.map(String.init) ?? ReviewGit.emptyTree
            return CrawledCommit(sha: fields[0], parent: parent, subject: fields[2], author: fields[3],
                                 committedAt: date)
        }
        return found.reversed()
    }

    /// Queues a review (id `<repoID>:<sha>`) for every commit on each branch not already in the store.
    /// Returns how many were inserted.
    public func crawl(repos: [(id: String, path: String, name: String)], branches: (URL) throws -> [String],
                      since: Date, store: PartnerStore) throws -> Int {
        var inserted = 0
        for repo in repos {
            let url = URL(fileURLWithPath: repo.path)
            for branch in try branches(url) {
                for commit in try commits(in: url, branch: branch, since: since)
                where try !store.reviewExists(repoID: repo.id, sha: commit.sha) {
                    try store.insertReview(PartnerReview(
                        id: "\(repo.id):\(commit.sha)", repoID: repo.id, repoPath: repo.path, repoName: repo.name,
                        sha: commit.sha, parent: commit.parent, branch: branch, subject: commit.subject,
                        author: commit.author, committedAt: commit.committedAt, state: .queued, supersededBy: []))
                    inserted += 1
                }
            }
        }
        return inserted
    }
}
