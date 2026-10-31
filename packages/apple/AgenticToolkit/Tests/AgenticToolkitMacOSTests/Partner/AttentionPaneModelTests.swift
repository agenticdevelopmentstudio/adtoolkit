import Combine
import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class AttentionPaneModelTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var cancellables: Set<AnyCancellable> = []

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AttentionPaneModelTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func seed() throws {
        let tenDaysAgo = Date().addingTimeInterval(-10 * 86_400)
        try store.insert(AttentionItem(kind: .question, text: "Which branch?", createdBy: "partner"))
        try store.insert(AttentionItem(kind: .notification, text: "Review done", state: .sent, createdBy: "partner"))
        try store.insert(AttentionItem(kind: .blocked, text: "Old", state: .done, createdBy: "partner",
                                       createdAt: tenDaysAgo, updatedAt: tenDaysAgo, completedAt: tenDaysAgo))
    }

    func testReloadSplitsOpenFromDoneAndDropsDoneOlderThanRetention() throws {
        try seed()
        let model = AttentionPaneModel(store: store, retentionDays: { 7 })
        model.reload()
        XCTAssertEqual(model.open.count, 2)
        XCTAssertEqual(Set(model.open.map(\.kind)), [.question, .notification])
        XCTAssertTrue(model.done.isEmpty)
    }

    func testDoneWithinRetentionIsListedUnderDone() throws {
        try seed()
        let model = AttentionPaneModel(store: store, retentionDays: { 30 })
        model.reload()
        XCTAssertEqual(model.open.count, 2)
        XCTAssertEqual(model.done.map(\.text), ["Old"])
    }

    func testAnAttentionChangeReloads() throws {
        try seed()
        let model = AttentionPaneModel(store: store, retentionDays: { 7 })
        model.reload()
        XCTAssertEqual(model.open.count, 2)

        let reloaded = expectation(description: "reloaded after insert")
        model.$open
            .dropFirst()
            .sink { items in if items.count == 3 { reloaded.fulfill() } }
            .store(in: &cancellables)
        try store.insert(AttentionItem(kind: .blocked, text: "Stuck", createdBy: "partner"))
        wait(for: [reloaded], timeout: 2)
        XCTAssertEqual(model.open.count, 3)
    }

    func testCardActionPerKindAndState() {
        func item(_ kind: AttentionKind, _ state: AttentionState) -> AttentionItem {
            AttentionItem(kind: kind, text: "x", state: state, createdBy: "partner")
        }
        XCTAssertEqual(AttentionPaneModel.cardAction(for: item(.question, .open)), .discuss)
        XCTAssertEqual(AttentionPaneModel.cardAction(for: item(.question, .discussing)), .resolved)
        XCTAssertEqual(AttentionPaneModel.cardAction(for: item(.blocked, .open)), .resolved)
        XCTAssertEqual(AttentionPaneModel.cardAction(for: item(.notification, .open)), .confirm)
        XCTAssertEqual(AttentionPaneModel.cardAction(for: item(.notification, .sent)), .sending)
        XCTAssertEqual(AttentionPaneModel.cardAction(for: item(.question, .done)), .done)
    }

    func testDiscussionReplyCarriesTheItemID() {
        let inbound = PartnerSplitViewController.discussionReply(itemID: "A1", text: "Use main.")
        guard case .owner(let text, let attribution) = inbound else { return XCTFail("not an owner line") }
        XCTAssertEqual(text, "Regarding attention item A1:\nUse main.")
        XCTAssertEqual(attribution?.sourceID, "attention:A1")
        XCTAssertEqual(attribution?.name, "Discuss")
    }
}
