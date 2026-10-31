import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

/// Drives real git in a temp repo and real shells through the session registry.
@MainActor
final class ReviewServiceTests: XCTestCase {

    private let fixBranch = "partner/review-fixes"

    private var directory: URL!
    private var repo: PartnerGitFixture!
    private var store: PartnerStore!
    private var registry: PartnerSessionRegistry!
    private var settings: SettingsStore!
    private var notifier: PartnerNotifier!
    private var paths: PartnerPaths!
    private var service: ReviewService!
    private var posts: [(String, String)] = []
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReviewServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        repo = try PartnerGitFixture()
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
        registry = PartnerSessionRegistry(store: store, environment: { [:] }, detector: ManualSessionEventDetector())
        settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                 secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        settings.set("opus", for: UserSettings.partnerReviewsReviewerModel)
        posts = []
        notifier = PartnerNotifier(store: store, settings: settings,
                                   post: { [unowned self] in posts.append(($0, $1)) })
        paths = PartnerPaths(home: directory, token: "kitchen-test")
        service = makeService()
    }

    override func tearDown() async throws {
        _ = registry.closeAll()
        service = nil; registry = nil; store = nil; notifier = nil; repo = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeService() -> ReviewService {
        ReviewService(store: store, sessions: registry, notifier: notifier, paths: paths, git: repo.review,
                      worktree: ReviewWorktree(git: repo.review), settings: settings,
                      steps: { PartnerJobDefaults.codeReviews().steps }, now: { [unowned self] in clock })
    }

    /// Commits `file` on main and queues a review for that commit.
    @discardableResult
    private func queue(file: String, day: Int, message: String, branch: String = "main",
                       repoID: String = "repo") throws -> PartnerReview {
        let sha = try repo.commit(file: file, day: day, message: message)
        return try queueReview(sha: sha, subject: message, branch: branch, repoID: repoID, day: day)
    }

    @discardableResult
    private func queueReview(sha: String, subject: String, branch: String = "main", repoID: String = "repo",
                             day: Int = 1) throws -> PartnerReview {
        let parent = try repo.review.parentSync(of: sha, in: repo.directory)
        let review = PartnerReview(
            id: "\(repoID):\(sha)", repoID: repoID, repoPath: repo.directory.path, repoName: "demo", sha: sha,
            parent: parent, branch: branch, subject: subject, author: "Ann",
            committedAt: Date(timeIntervalSince1970: 1_767_225_600 + TimeInterval(day) * 86_400))
        try store.insertReview(review)
        return review
    }

    private func attentionItems() throws -> [AttentionItem] {
        try store.attentionItems(includeDoneCompletedAfter: .distantPast)
    }

    // MARK: - start

    func testStartSkipsCommitNoLongerInBranch() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")
        try repo.git("reset", "--hard", "HEAD~1")

        let started = try await service.start(id: review.id)

        XCTAssertEqual(started.review.state, .skipped)
        XCTAssertTrue(started.review.skipReason?.contains("no longer") ?? false, started.review.skipReason ?? "nil")
        XCTAssertTrue(started.steps.isEmpty)
        let stored = try XCTUnwrap(store.review(id: review.id))
        XCTAssertEqual(stored.state, .skipped)
        XCTAssertEqual(stored.finishedAt, clock)
        XCTAssertTrue(registry.sessions.isEmpty, "no session opened for a skipped review")
    }

    func testStartRefusesSecondRunningInSameRepo() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let first = try queue(file: "b.txt", day: 2, message: "second")
        let second = try queue(file: "c.txt", day: 3, message: "third")
        _ = try await service.start(id: first.id)

        do {
            _ = try await service.start(id: second.id)
            XCTFail("a second review in the same repo started")
        } catch ReviewError.anotherRunningInRepo {
        }
        XCTAssertEqual(try store.review(id: second.id)?.state, .queued)
        XCTAssertEqual(registry.sessions.count, 1)
    }

    func testOverlappingStartsInSameRepoLetOnlyOneThrough() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let first = try queue(file: "b.txt", day: 2, message: "second")
        let second = try queue(file: "c.txt", day: 3, message: "third")

        // Both calls begin before either finishes its git work; only the reservation taken before the first
        // suspension keeps the second out.
        let service: ReviewService = service
        let one = Task { await Self.outcome { try await service.start(id: first.id) } }
        let two = Task { await Self.outcome { try await service.start(id: second.id) } }
        let results = [await one.value, await two.value]

        XCTAssertEqual(results.filter { $0 == "started" }.count, 1, "\(results)")
        XCTAssertEqual(results.filter { $0 == "another running" }.count, 1, "\(results)")
        XCTAssertEqual(try store.reviews(state: .running).count, 1)
        XCTAssertEqual(registry.sessions.count, 1)
    }

    private static func outcome(_ body: () async throws -> PartnerReviewStart) async -> String {
        do {
            _ = try await body()
            return "started"
        } catch ReviewError.anotherRunningInRepo {
            return "another running"
        } catch {
            return "\(error)"
        }
    }

    func testStartRefusesAReviewThatIsNotQueued() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")
        _ = try await service.start(id: review.id)
        do {
            _ = try await service.start(id: review.id)
            XCTFail("a running review started again")
        } catch ReviewError.notQueued {
        }
    }

    func testStartPreparesWorktreeOpensSessionFillsSteps() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")

        let started = try await service.start(id: review.id)

        XCTAssertEqual(started.worktreePath, paths.reviewsDirectory.appendingPathComponent("demo").path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: started.worktreePath))
        XCTAssertEqual(try repo.git("-C", started.worktreePath, "branch", "--show-current")
                        .trimmingCharacters(in: .whitespacesAndNewlines), fixBranch)
        XCTAssertEqual(started.fixBranch, fixBranch)
        XCTAssertEqual(started.steps.count, 3)
        XCTAssertEqual(started.steps[0].command, "claude --model opus --dangerously-skip-permissions")
        XCTAssertEqual(started.steps[1].command, "/code-review high \(review.sha)")
        XCTAssertTrue(started.steps[2].command.contains("Reviewed-Commit: \(review.sha)"), started.steps[2].command)
        XCTAssertTrue(started.steps[2].command.contains("on \(fixBranch)"), started.steps[2].command)
        XCTAssertTrue(started.steps[2].command.contains("(none)"), "no later commits: \(started.steps[2].command)")

        XCTAssertEqual(started.review.state, .running)
        XCTAssertEqual(started.review.startedAt, clock)
        let stored = try XCTUnwrap(store.review(id: review.id))
        XCTAssertEqual(stored.state, .running)
        XCTAssertEqual(registry.sessions.count, 1)
        let session = try XCTUnwrap(registry.sessions.first)
        XCTAssertEqual(session.reviewID, review.id)
        XCTAssertEqual(session.directory, started.worktreePath)
        XCTAssertEqual(session.title, "review \(review.sha.prefix(7))")
        XCTAssertEqual(stored.sessionID, session.id.uuidString)
        XCTAssertEqual(try store.sessions().first?.reviewID, review.id, "the stored record names the review")
        XCTAssertEqual(try store.reviewSetting(repoID: "repo", key: "worktree_path"), started.worktreePath)
    }

    func testEmptyReviewerModelDropsTheModelOption() async throws {
        settings.set("", for: UserSettings.partnerReviewsReviewerModel)
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")

        let started = try await service.start(id: review.id)

        XCTAssertEqual(started.steps[0].command, "claude --dangerously-skip-permissions")
        XCTAssertEqual(started.steps[1].command, "/code-review high \(review.sha)")
    }

    func testWorktreeForANonDefaultBranchIsNamedAfterIt() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        try repo.git("switch", "-c", "feature/x")
        let review = try queue(file: "b.txt", day: 2, message: "second", branch: "feature/x")
        try repo.git("switch", "main")

        let started = try await service.start(id: review.id)

        XCTAssertEqual(started.worktreePath, paths.reviewsDirectory.appendingPathComponent("demo-feature-x").path)
        XCTAssertEqual(started.review.state, .running)
    }

    func testSupersededListAndTipDiffComputedAtStart() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")
        try repo.commit(file: "other.txt", day: 3, message: "unrelated")
        let later = try repo.commit(file: "b.txt", day: 4, message: "rewrite b", content: "rewritten\n")

        let started = try await service.start(id: review.id)

        XCTAssertEqual(started.review.supersededBy, [later])
        XCTAssertEqual(try store.review(id: review.id)?.supersededBy, [later])
        XCTAssertFalse(started.tipDiff.isEmpty)
        XCTAssertTrue(started.tipDiff.contains("rewritten"), started.tipDiff)
        XCTAssertFalse(started.tipDiff.contains("other.txt"), "only the reviewed commit's files")
        XCTAssertTrue(started.steps[2].command.contains("(\(later))"), started.steps[2].command)
    }

    func testDirtyWorktreeFailsTheReviewAndRaisesABlockedItem() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let first = try queue(file: "b.txt", day: 2, message: "second")
        let second = try queue(file: "c.txt", day: 3, message: "third")
        let started = try await service.start(id: first.id)
        _ = try service.finish(id: first.id, state: .done, summary: "ok")
        try "scratch".write(to: URL(fileURLWithPath: started.worktreePath).appendingPathComponent("junk.txt"),
                            atomically: true, encoding: .utf8)

        do {
            _ = try await service.start(id: second.id)
            XCTFail("a dirty worktree was reused")
        } catch ReviewWorktree.Failure.dirty {
        }

        let stored = try XCTUnwrap(store.review(id: second.id))
        XCTAssertEqual(stored.state, .failed)
        XCTAssertFalse(stored.summary?.isEmpty ?? true)
        XCTAssertEqual(stored.finishedAt, clock)
        let blocked = try attentionItems().filter { $0.kind == .blocked }
        XCTAssertEqual(blocked.count, 1)
        XCTAssertEqual(blocked.first?.reference["review"], second.id)
        XCTAssertEqual(registry.sessions.count, 1, "no session for the failed review")
    }

    func testGitFailureDuringStartFailsTheReviewInsteadOfLeavingItQueued() async throws {
        let sha = try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queueReview(sha: sha, subject: "first", branch: "gone")

        do {
            _ = try await service.start(id: review.id)
            XCTFail("a review of a missing branch started")
        } catch is GitClientError {
        }

        XCTAssertEqual(try store.review(id: review.id)?.state, .failed)
        XCTAssertEqual(try attentionItems().filter { $0.kind == .blocked }.count, 1)
        // The reservation was released: another review in the repo can start.
        let next = try queue(file: "b.txt", day: 2, message: "second")
        let started = try await service.start(id: next.id)
        XCTAssertEqual(started.review.state, .running)
    }

    // MARK: - next, finish, requeue

    func testNextListsQueuedWithConcurrencyAndRunning() async throws {
        settings.set(2, for: UserSettings.partnerReviewsConcurrency)
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let first = try queue(file: "b.txt", day: 2, message: "second")
        let second = try queue(file: "c.txt", day: 3, message: "third")
        _ = try await service.start(id: first.id)

        let next = try service.next()

        XCTAssertEqual(next.reviews.map(\.id), [second.id])
        XCTAssertEqual(next.concurrency, 2)
        XCTAssertEqual(next.running, 1)
    }

    func testFinishCreatesNotificationItem() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")
        _ = try await service.start(id: review.id)
        clock += 60

        let finished = try service.finish(id: review.id, state: .done, summary: "fixed two, skipped one")

        XCTAssertEqual(finished.state, .done)
        XCTAssertEqual(finished.summary, "fixed two, skipped one")
        XCTAssertEqual(finished.finishedAt, clock)
        XCTAssertEqual(try store.review(id: review.id), finished)
        let items = try attentionItems().filter { $0.kind == .notification }
        XCTAssertEqual(items.count, 1)
        XCTAssertTrue(items.first?.text.hasPrefix("review done") ?? false, items.first?.text ?? "nil")
        XCTAssertEqual(items.first?.reference["review"], review.id)
        XCTAssertEqual(posts.first?.0, "review done")
        XCTAssertEqual(registry.sessions.count, 1, "finish closes nothing")
    }

    func testFinishRefusesAQueuedStateAndAFinishedReview() async throws {
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")
        XCTAssertThrowsError(try service.finish(id: review.id, state: .running, summary: ""))
        _ = try service.finish(id: review.id, state: .skipped, summary: "not worth it")
        XCTAssertEqual(try store.review(id: review.id)?.skipReason, "not worth it")
        XCTAssertThrowsError(try service.finish(id: review.id, state: .done, summary: "again"))
        XCTAssertThrowsError(try service.finish(id: "nope", state: .done, summary: ""))
    }

    func testRequeueInterrupted() throws {
        let sha = try repo.commit(file: "a.txt", day: 1, message: "first")
        var running = try queueReview(sha: sha, subject: "first")
        running.state = .running
        running.sessionID = "s1"
        running.startedAt = clock
        try store.updateReview(running)
        let sha2 = try repo.commit(file: "b.txt", day: 2, message: "second")
        var done = try queueReview(sha: sha2, subject: "second", day: 2)
        done.state = .done
        try store.updateReview(done)

        XCTAssertEqual(try service.requeueInterrupted(), 1)

        let requeued = try XCTUnwrap(store.review(id: running.id))
        XCTAssertEqual(requeued.state, .queued)
        XCTAssertNil(requeued.sessionID)
        XCTAssertNil(requeued.startedAt)
        XCTAssertEqual(try store.review(id: done.id)?.state, .done)
        XCTAssertEqual(try service.requeueInterrupted(), 0)
    }

    // MARK: - Tools

    private func toolSource() -> PartnerToolSource {
        PartnerToolSource(callerID: { "c1" }, store: store, sessions: registry, projects: { [] },
                          notifier: notifier, reviews: service)
    }

    private func call(_ source: PartnerToolSource, _ name: String, _ args: [String: Any] = [:]) async throws
        -> (content: String, isError: Bool) {
        await source.callTool(name: name, argumentsJSON: try JSONSerialization.data(withJSONObject: args),
                              caller: "c1")
    }

    private func object(_ text: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any], text)
    }

    func testReviewToolsAreListedOnlyWithAService() async {
        let names = await toolSource().toolDefinitions().map(\.name)
        XCTAssertTrue(names.contains("partner_review_next"))
        XCTAssertTrue(names.contains("partner_review_start"))
        XCTAssertTrue(names.contains("partner_review_finish"))
        let plain = PartnerToolSource(callerID: { "c1" }, store: store, sessions: registry, projects: { [] },
                                      notifier: notifier)
        let plainNames = await plain.toolDefinitions().map(\.name)
        XCTAssertFalse(plainNames.contains("partner_review_next"))
    }

    func testReviewToolsRoundTrip() async throws {
        let source = toolSource()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")

        let next = try await call(source, "partner_review_next")
        XCTAssertFalse(next.isError, next.content)
        let nextObject = try object(next.content)
        XCTAssertEqual((nextObject["reviews"] as? [[String: Any]])?.first?["id"] as? String, review.id)
        XCTAssertEqual(nextObject["concurrency"] as? Int, 1)
        XCTAssertEqual(nextObject["running"] as? Int, 0)

        let start = try await call(source, "partner_review_start", ["id": review.id])
        XCTAssertFalse(start.isError, start.content)
        let startObject = try object(start.content)
        XCTAssertEqual((startObject["review"] as? [String: Any])?["state"] as? String, "running")
        XCTAssertEqual((startObject["steps"] as? [Any])?.count, 3)

        let refused = try await call(source, "partner_review_start", ["id": review.id])
        XCTAssertTrue(refused.isError)

        let finish = try await call(source, "partner_review_finish",
                                    ["id": review.id, "state": "done", "summary": "clean"])
        XCTAssertFalse(finish.isError, finish.content)
        XCTAssertEqual(try object(finish.content)["state"] as? String, "done")

        let badState = try await call(source, "partner_review_finish",
                                      ["id": review.id, "state": "queued", "summary": ""])
        XCTAssertTrue(badState.isError)
    }

    func testSkippedStartIsNotAToolError() async throws {
        let source = toolSource()
        try repo.commit(file: "a.txt", day: 1, message: "first")
        let review = try queue(file: "b.txt", day: 2, message: "second")
        try repo.git("reset", "--hard", "HEAD~1")

        let start = try await call(source, "partner_review_start", ["id": review.id])

        XCTAssertFalse(start.isError, start.content)
        let reviewObject = try XCTUnwrap(try object(start.content)["review"] as? [String: Any])
        XCTAssertEqual(reviewObject["state"] as? String, "skipped")
    }
}

private extension ReviewGit {
    /// The fixture's commit's first parent, read with plain git so setup does not depend on the code under test.
    func parentSync(of sha: String, in repo: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", repo.path, "rev-list", "--parents", "-n", "1", sha]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let parts = (String(bytes: data, encoding: .utf8) ?? "").split(whereSeparator: { $0 == " " || $0 == "\n" })
        return parts.count > 1 ? String(parts[1]) : ReviewGit.emptyTree
    }
}
