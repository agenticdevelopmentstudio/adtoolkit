import Combine
import SQLite3
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

final class PartnerStoreReviewsTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerStoreReviewsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: databasePath)
    }

    override func tearDownWithError() throws {
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private var databasePath: String { directory.appendingPathComponent("Partner.db").path }

    private func makeReview(_ id: String, sha: String? = nil, repo: String = "repo-a", at seconds: TimeInterval = 1_000,
                            state: PartnerReviewState = .queued) -> PartnerReview {
        PartnerReview(id: id, repoID: repo, repoPath: "/r/\(repo)", repoName: repo, sha: sha ?? "sha-\(id)",
               parent: "parent-\(id)", branch: "main", subject: "subject \(id)", author: "Ann",
               committedAt: Date(timeIntervalSince1970: seconds), state: state)
    }

    private func rawExec(_ sql: String) {
        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open_v2(databasePath, &handle, SQLITE_OPEN_READWRITE, nil), SQLITE_OK)
        defer { sqlite3_close(handle) }
        XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK, sql)
    }

    func testInsertAndFetchRoundTrips() throws {
        var item = makeReview("a")
        item.supersededBy = ["x", "y"]
        item.summary = "fine"
        item.startedAt = Date(timeIntervalSince1970: 2_000)
        try store.insertReview(item)
        XCTAssertEqual(try store.review(id: "a"), item)
        XCTAssertNil(try store.review(id: "missing"))
    }

    func testDuplicateRepoAndShaIsRejected() throws {
        try store.insertReview(makeReview("a", sha: "s"))
        XCTAssertThrowsError(try store.insertReview(makeReview("b", sha: "s")))
        XCTAssertNoThrow(try store.insertReview(makeReview("c", sha: "s", repo: "repo-b")))
    }

    func testInsertIfNewSkipsACommitAlreadyListed() throws {
        XCTAssertTrue(try store.insertReviewIfNew(makeReview("a", sha: "s")))
        XCTAssertFalse(try store.insertReviewIfNew(makeReview("b", sha: "s")))
        XCTAssertFalse(try store.insertReviewIfNew(makeReview("a", sha: "other")))
        XCTAssertTrue(try store.insertReviewIfNew(makeReview("c", sha: "s", repo: "repo-b")))
        XCTAssertEqual(try store.reviews(state: nil).map(\.id).sorted(), ["a", "c"])
    }

    func testUpdateReplacesFieldsAndRejectsUnknownID() throws {
        try store.insertReview(makeReview("a"))
        var item = try XCTUnwrap(try store.review(id: "a"))
        item.state = .done
        item.sessionID = "sess"
        item.finishedAt = Date(timeIntervalSince1970: 3_000)
        item.summary = "ok"
        item.skipReason = "none"
        item.supersededBy = ["z"]
        try store.updateReview(item)
        XCTAssertEqual(try store.review(id: "a"), item)
        XCTAssertThrowsError(try store.updateReview(makeReview("nope")))
    }

    func testQueuedOrderedOldestCommitFirst() throws {
        try store.insertReview(makeReview("new", at: 3_000))
        try store.insertReview(makeReview("old", at: 1_000))
        try store.insertReview(makeReview("mid", at: 2_000))
        try store.insertReview(makeReview("done", at: 500, state: .done))
        XCTAssertEqual(try store.reviews(state: .queued).map(\.id), ["old", "mid", "new"])
        XCTAssertEqual(try store.reviews(state: .done).map(\.id), ["done"])
        XCTAssertEqual(try store.reviews(state: nil).count, 4)
    }

    func testReviewExists() throws {
        try store.insertReview(makeReview("a", sha: "s1"))
        XCTAssertTrue(try store.reviewExists(repoID: "repo-a", sha: "s1"))
        XCTAssertFalse(try store.reviewExists(repoID: "repo-b", sha: "s1"))
        XCTAssertFalse(try store.reviewExists(repoID: "repo-a", sha: "s2"))
    }

    func testCounts() throws {
        XCTAssertTrue(try store.reviewCounts() == (0, 0, 0, 0, 0))
        try store.insertReview(makeReview("a"))
        try store.insertReview(makeReview("b"))
        try store.insertReview(makeReview("c", state: .running))
        try store.insertReview(makeReview("d", state: .done))
        try store.insertReview(makeReview("e", state: .failed))
        try store.insertReview(makeReview("f", state: .skipped))
        try store.insertReview(makeReview("g", state: .skipped))
        XCTAssertTrue(try store.reviewCounts() == (2, 1, 1, 1, 2))
    }

    func testPerRepoSettings() throws {
        XCTAssertNil(try store.reviewSetting(repoID: "repo-a", key: "opted_out"))
        try store.setReviewSetting(repoID: "repo-a", key: "opted_out", value: "1")
        XCTAssertEqual(try store.reviewSetting(repoID: "repo-a", key: "opted_out"), "1")
        XCTAssertNil(try store.reviewSetting(repoID: "repo-b", key: "opted_out"))
        try store.setReviewSetting(repoID: "repo-a", key: "opted_out", value: "0")
        XCTAssertEqual(try store.reviewSetting(repoID: "repo-a", key: "opted_out"), "0")
        try store.setReviewSetting(repoID: "repo-a", key: "opted_out", value: nil)
        XCTAssertNil(try store.reviewSetting(repoID: "repo-a", key: "opted_out"))
    }

    func testWritesAnnounceReviewsChange() throws {
        var seen: [PartnerStore.Change] = []
        let cancellable = store.changes.sink { seen.append($0) }
        try store.insertReview(makeReview("a"))
        try store.setReviewSetting(repoID: "r", key: "k", value: "v")
        cancellable.cancel()
        XCTAssertEqual(seen, [.reviews, .reviews])
    }

    func testVersionOneDatabaseMigratesToTwoKeepingRows() throws {
        try store.setValue("keep", forKey: "probe")
        try store.upsert(PartnerJob(id: "j", name: "J", isEnabled: true, scheduleSeconds: nil, guidelines: "g",
                                    steps: [], isBuiltIn: false))
        store = nil
        rawExec("DROP TABLE review; DROP TABLE review_setting; DELETE FROM schema_migrations WHERE version = 2")
        store = try PartnerStore(path: databasePath)
        XCTAssertEqual(try store.schemaVersion(), 2)
        XCTAssertEqual(try store.value(forKey: "probe"), "keep")
        XCTAssertEqual(try store.jobs().map(\.id), ["j"])
        try store.insertReview(makeReview("a"))
        XCTAssertEqual(try store.reviews(state: nil).count, 1)
    }
}
