import Foundation
import AgenticToolkitCore
import os

/// The code-reviews job's timer work: before each tick, crawl every listed project that is not opted out for
/// commits in the window and queue them, then summarise the queue for the tick message.
@MainActor
public final class CodeReviewsScheduler {

    private let store: PartnerStore
    private let crawler: CommitCrawler
    private let git: ReviewGit
    private let projects: @MainActor () -> [PartnerToolSource.Project]
    private let settings: SettingsStore
    private let now: () -> Date

    public init(store: PartnerStore, crawler: CommitCrawler = CommitCrawler(), git: ReviewGit = ReviewGit(),
                projects: @escaping @MainActor () -> [PartnerToolSource.Project],
                settings: SettingsStore = UserSettings.shared, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.crawler = crawler
        self.git = git
        self.projects = projects
        self.settings = settings
        self.now = now
    }

    /// Runs the crawl off the main actor and returns "N queued, M running, K inserted this crawl".
    public func crawlAndSummarise() async -> String {
        let repos = projects()
            .filter { !$0.path.isEmpty && !isOptedOut($0.id) }
            .map { (id: $0.id, path: $0.path, name: $0.name) }
        let since = now().addingTimeInterval(-TimeInterval(settings.get(UserSettings.partnerReviewsWindowHours)) * 3600)
        let includeOthers = settings.get(UserSettings.partnerReviewsIncludeOtherBranches)
        let store = store, crawler = crawler, git = git
        let inserted = await Task.detached {
            await Self.crawl(repos: repos, since: since, includeOtherBranches: includeOthers,
                             store: store, crawler: crawler, git: git)
        }.value
        do {
            let counts = try store.reviewCounts()
            return "\(counts.queued) queued, \(counts.running) running, \(inserted) inserted this crawl"
        } catch {
            Self.logger.error("Counting reviews failed: \(error.localizedDescription, privacy: .public)")
            return "review counts unavailable, \(inserted) inserted this crawl"
        }
    }

    /// One repo at a time, so a repo whose git calls throw (moved, not a repo, a branch deleted mid-crawl) is
    /// skipped and logged and the rest still queue.
    private nonisolated static func crawl(repos: [(id: String, path: String, name: String)], since: Date,
                                          includeOtherBranches: Bool, store: PartnerStore, crawler: CommitCrawler,
                                          git: ReviewGit) async -> Int {
        var inserted = 0
        for repo in repos {
            do {
                inserted += try await crawler.crawl(repos: [repo], branches: { url in
                    let main = try await git.defaultBranch(in: url)
                    guard includeOtherBranches else { return [main] }
                    return [main] + (try await git.localBranches(in: url)).filter { $0 != main }
                }, since: since, store: store)
            } catch {
                logger.error("""
                    Crawling \(repo.name, privacy: .public) at \(repo.path, privacy: .public) failed; skipped: \
                    \(error.localizedDescription, privacy: .public)
                    """)
            }
        }
        return inserted
    }

    /// An unreadable setting counts as opted out: skipping a repo for one crawl is cheaper than reviewing one
    /// the owner opted out of.
    private func isOptedOut(_ repoID: String) -> Bool {
        do {
            return try store.reviewSetting(repoID: repoID, key: "opted_out") == "1"
        } catch {
            Self.logger.error("Reading opted_out for \(repoID, privacy: .public) failed: \(error.localizedDescription)")
            return true
        }
    }
}

extension CodeReviewsScheduler: Loggable {
    public static nonisolated let logger = makeLogger()
}
