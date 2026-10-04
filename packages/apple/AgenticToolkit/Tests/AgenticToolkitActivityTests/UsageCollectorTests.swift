import XCTest
import AgenticToolkitDatabase
import GRDB
@testable import AgenticToolkitActivity

@MainActor
final class UsageCollectorTests: XCTestCase {
    func test_focus_then_switch_persists_one_closed_segment() throws {
        let db = try BoundedDatabase(path: ":memory:")
        let store = UsageStore(database: db); try store.runMigrations()
        let focus = FakeFocusSource(); let windows = FakeWindowSource()
        let idle = FakeIdleSource(); let power = FakePowerSource()
        var clock = Date(timeIntervalSince1970: 0)
        let collector = UsageCollector(store: store, tracker: FocusTracker(),
            focus: focus, windows: windows, idle: idle, power: power, machineID: UUID(),
            now: { clock }, makeID: UUID.init)
        collector.start()
        let a = WindowFocus(app: AppInfo(bundleID: "A", name: "A", pid: 1), windowID: 1, title: "x", documentPath: nil)
        let b = WindowFocus(app: AppInfo(bundleID: "B", name: "B", pid: 2), windowID: 2, title: "y", documentPath: nil)
        focus.emit(a)
        clock = clock.addingTimeInterval(4)
        focus.emit(b)                       // closes A
        let page = try store.segments(sinceRowID: 0, limit: 10)
        XCTAssertEqual(page.segments.count, 1)
        XCTAssertEqual(page.segments[0].focus.app.bundleID, "A")
        XCTAssertEqual(page.segments[0].durationMs, 4000)
    }

    func testWindowEventsAreNoLongerWrittenToTheRetiredTable() throws {
        // context_event_window replaces usage_window_events exactly; two tables
        // recording the same fact is two tables that eventually disagree.
        //
        // Positive control first, and not optional (M-4): without it, "0
        // rows in usage_window_events" below could be true for the wrong
        // reason — nothing happened at all — rather than because the event
        // moved to its new table. Prove the same kind of window event still
        // lands in context_event_window before proving it no longer lands
        // in usage_window_events.
        let contextDB = try BoundedDatabase(path: ":memory:")
        let contextStore = ContextStore(database: contextDB); try contextStore.runMigrations()
        let contextMachineID = UUID()
        try contextStore.upsertMachine(
            MachineDescriptor(id: contextMachineID, platform: .macOS, nativeID: "NATIVE",
                              nativeIDKind: .ioPlatformUUID, hostname: "h", model: "m",
                              osVersion: "26.0"),
            seenAt: Date(timeIntervalSince1970: 1_000))
        let contextSource = FakeWindowSource()
        let contextTrigger = WindowLifecycleContextTrigger(source: contextSource,
                                                            now: { Date(timeIntervalSince1970: 6_000) })
        contextTrigger.onEvent = { detail, when in
            try? contextStore.insert(ContextEvent(machineID: contextMachineID, occurredAt: when, detail: detail))
        }
        try contextTrigger.start()
        contextSource.emit(.created, AppInfo(bundleID: "A", name: "A", pid: 1), 5, "win")
        let contextRowCount = try contextDB.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_event_window") ?? 0
        }
        XCTAssertEqual(contextRowCount, 1, "positive control: a window event must still land somewhere")

        let db = try BoundedDatabase(path: ":memory:")
        let store = UsageStore(database: db); try store.runMigrations()
        let windows = FakeWindowSource()
        let collector = UsageCollector(store: store, tracker: FocusTracker(),
            focus: FakeFocusSource(), windows: windows, idle: FakeIdleSource(),
            power: FakePowerSource(), machineID: UUID(), now: { Date() }, makeID: UUID.init)
        collector.start()
        windows.emit(.created, AppInfo(bundleID: "A", name: "A", pid: 1), 5, "win")
        let count = try db.read { db in try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM usage_window_events") ?? 0 }
        XCTAssertEqual(count, 0)
    }
}
