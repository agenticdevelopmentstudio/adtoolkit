import XCTest
@testable import AgenticToolkitMacOS

final class BrowserHistoryStoreTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHistoryStoreTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> BrowserHistoryStore {
        try BrowserHistoryStore(path: directory.appendingPathComponent("BrowserHistory.db").path)
    }

    func testOpeningCreatesTheFileAndItsDirectory() throws {
        let store = try makeStore()
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.databasePath))
        XCTAssertEqual(try store.count(), 0)
    }

    func testRecordedVisitsComeBackNewestFirst() throws {
        let store = try makeStore()
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        try store.record(URL(string: "https://example.com/a")!, title: "A", at: older)
        try store.record(URL(string: "https://example.com/b")!, title: "B", at: newer)

        let recent = try store.recent()
        XCTAssertEqual(recent.map(\.title), ["B", "A"])
        XCTAssertEqual(recent.first?.visitedAt, newer)
        XCTAssertEqual(try store.count(), 2)
    }

    func testATitleThatArrivesLaterIsFiledAgainstItsVisit() throws {
        let store = try makeStore()
        let id = try store.record(URL(string: "https://example.com")!, title: "")
        try store.updateTitle(ofVisit: id, to: "Example Domain")
        XCTAssertEqual(try store.recent().first?.title, "Example Domain")
    }

    func testSearchMatchesAddressOrTitle() throws {
        let store = try makeStore()
        try store.record(URL(string: "https://swift.org")!, title: "Swift")
        try store.record(URL(string: "https://example.com/docs")!, title: "Docs")
        try store.record(URL(string: "https://example.com")!, title: "Example")

        XCTAssertEqual(try store.search("swift").map(\.title), ["Swift"], "matched on the address")
        XCTAssertEqual(try store.search("Doc").map(\.title), ["Docs"], "matched on the title")
        XCTAssertEqual(try store.search("example.com").count, 2)
        XCTAssertEqual(try store.search("nowhere").count, 0)
    }

    /// `%` and `_` are LIKE's wildcards; typed into the search they mean
    /// themselves.
    func testSearchTakesWildcardsLiterally() throws {
        let store = try makeStore()
        try store.record(URL(string: "https://example.com/100%25")!, title: "100% done")
        try store.record(URL(string: "https://example.com/snake_case")!, title: "snake_case")
        try store.record(URL(string: "https://example.com/plain")!, title: "plain")

        XCTAssertEqual(try store.search("%").map(\.title), ["100% done"])
        XCTAssertEqual(try store.search("e_c").map(\.title), ["snake_case"], "`_` is not a one-character wildcard")
        XCTAssertEqual(try store.search("\\").count, 0)
    }

    func testRemovingOneVisitLeavesTheRest() throws {
        let store = try makeStore()
        let first = try store.record(URL(string: "https://example.com/1")!, title: "1")
        try store.record(URL(string: "https://example.com/2")!, title: "2")
        try store.remove(visit: first)
        XCTAssertEqual(try store.recent().map(\.title), ["2"])
    }

    func testRemovingVisitsBeforeACutoffKeepsTheNewerOnes() throws {
        let store = try makeStore()
        let cutoff = Date(timeIntervalSince1970: 5_000)
        try store.record(URL(string: "https://example.com/old")!, title: "old", at: cutoff.addingTimeInterval(-1))
        try store.record(URL(string: "https://example.com/new")!, title: "new", at: cutoff.addingTimeInterval(1))
        try store.removeVisits(before: cutoff)
        XCTAssertEqual(try store.recent().map(\.title), ["new"])
    }

    func testRemoveAllForgetsEverything() throws {
        let store = try makeStore()
        try store.record(URL(string: "https://example.com")!, title: "")
        try store.record(URL(string: "https://example.org")!, title: "")
        try store.removeAll()
        XCTAssertEqual(try store.count(), 0)
        XCTAssertTrue(try store.recent().isEmpty)
    }

    func testTheFileSurvivesReopening() throws {
        do {
            let store = try makeStore()
            try store.record(URL(string: "https://example.com")!, title: "kept")
        }
        let reopened = try makeStore()
        XCTAssertEqual(try reopened.recent().map(\.title), ["kept"])
    }
}
