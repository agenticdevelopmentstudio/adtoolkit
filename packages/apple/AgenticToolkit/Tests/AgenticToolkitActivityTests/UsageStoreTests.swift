import XCTest
import AgenticToolkitDatabase
import GRDB
@testable import AgenticToolkitActivity

final class UsageStoreTests: XCTestCase {
    private func makeStore() throws -> UsageStore {
        let db = try BoundedDatabase(path: ":memory:")
        let store = UsageStore(database: db)
        try store.runMigrations()
        return store
    }

    func test_insert_and_read_segment_roundtrips() throws {
        let store = try makeStore()
        let seg = FocusSegment(id: UUID(), startedAt: Date(timeIntervalSince1970: 10),
            endedAt: Date(timeIntervalSince1970: 12), focus: WindowFocus(
                app: AppInfo(bundleID: "com.apple.TextEdit", name: "TextEdit", pid: 3),
                windowID: 9, title: "notes.txt", documentPath: "/tmp/notes.txt"),
            endReason: .focusChange)
        try store.insertSegment(seg)
        let page = try store.segments(sinceRowID: 0, limit: 10)
        XCTAssertEqual(page.segments.count, 1)
        XCTAssertEqual(page.segments[0].focus.documentPath, "/tmp/notes.txt")
        XCTAssertEqual(page.segments[0].endReason, .focusChange)
        XCTAssertNotNil(page.nextCursor)
    }

    func test_closeStaleSpans_closes_open_span_at_last_heartbeat() throws {
        let store = try makeStore()
        let id = UUID()
        try store.openSpan(id: id, machineID: UUID(), startedAt: Date(timeIntervalSince1970: 100))
        try store.heartbeatSpan(id: id, at: Date(timeIntervalSince1970: 130))
        try store.closeStaleSpans()
        let open = try store.openSpanCount()
        XCTAssertEqual(open, 0)
    }

    func testOpenSpanStampsTheMachineID() throws {
        let db = try BoundedDatabase(path: ":memory:")
        let store = UsageStore(database: db)
        try store.runMigrations()
        let machine = UUID()
        try store.openSpan(id: UUID(), machineID: machine, startedAt: Date(timeIntervalSince1970: 10))
        try db.read { db in
            XCTAssertEqual(try String.fetchOne(db, sql: "SELECT machine_id FROM usage_capture_spans"),
                           machine.uuidString)
        }
    }
}
