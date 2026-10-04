#if os(macOS)
import XCTest
@testable import AgenticToolkitActivity

private struct ScriptedPowerReader: PowerStatusReading {
    /// `@unchecked Sendable` earned by a lock — the same idiom as
    /// `MutableFakePermissionGate` in `ContextFakes.swift`. `PowerStatusReading`
    /// requires `Sendable`, and `read()` both reads the script and advances
    /// the cursor, so the two have to move together under one lock rather
    /// than by assertion.
    final class Box: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [PowerDetail?] = []
        var readings: [PowerDetail?] {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }

        /// Returns the reading at the cursor and advances it, clamped at the
        /// last entry, as one atomic step.
        func next() -> PowerDetail? {
            lock.withLock { () -> PowerDetail? in
                guard !stored.isEmpty else { return nil }
                let value = stored[min(index, stored.count - 1)]
                index = min(index + 1, stored.count - 1)
                return value
            }
        }

        private var index = 0
    }
    let box: Box
    func read() -> PowerDetail? { box.next() }
}

@MainActor
final class PowerTriggerTests: XCTestCase {
    private func makeTrigger(_ readings: [PowerDetail?])
    -> (PowerTrigger, () -> [PowerDetail]) {
        let box = ScriptedPowerReader.Box()
        box.readings = readings
        let t = PowerTrigger(interval: 10, reader: ScriptedPowerReader(box: box),
                             now: { Date(timeIntervalSince1970: 3_000) })
        let rec = Recorder()
        t.onEvent = { d, _ in if case .power(let p) = d { rec.details.append(p) } }
        return (t, { rec.details })
    }

    private final class Recorder { var details: [PowerDetail] = [] }

    func testDeclaresItsKindAndNeedsNoPermission() {
        let (t, _) = makeTrigger([PowerDetail(source: .ac, percent: 100, isCharging: false)])
        XCTAssertEqual(t.kind, ContextEventKind.power)
        XCTAssertEqual(t.requiredPermission, ContextPermission.none)
    }

    func testEmitsTheFirstReadingImmediately() throws {
        let (t, details) = makeTrigger([PowerDetail(source: .battery, percent: 71, isCharging: false)])
        try t.start()
        XCTAssertEqual(details().count, 1)
        XCTAssertEqual(details()[0].source, .battery)
        XCTAssertEqual(details()[0].percent, 71)
    }

    func testDoesNotRepeatAnUnchangedReading() throws {
        // A power state that has not moved is not an event; repeating it every
        // minute would bury the transitions that matter.
        let same = PowerDetail(source: .ac, percent: 100, isCharging: false)
        let (t, details) = makeTrigger([same, same, same])
        try t.start()
        t.tick(); t.tick()
        XCTAssertEqual(details().count, 1)
    }

    func testEmitsWhenAnyFieldChanges() throws {
        let (t, details) = makeTrigger([
            PowerDetail(source: .ac, percent: 100, isCharging: false),
            PowerDetail(source: .battery, percent: 100, isCharging: false),
            PowerDetail(source: .battery, percent: 99, isCharging: false),
            PowerDetail(source: .battery, percent: 99, isCharging: true),
        ])
        try t.start()
        t.tick(); t.tick(); t.tick()
        XCTAssertEqual(details().count, 4)
        XCTAssertEqual(details().map(\.source), [.ac, .battery, .battery, .battery])
    }

    func testAnUnreadableStatusEmitsNothingRatherThanGuessing() throws {
        let (t, details) = makeTrigger([nil])
        try t.start()
        t.tick()
        XCTAssertEqual(details().count, 0)
    }

    func testStopEndsEmission() throws {
        let (t, details) = makeTrigger([
            PowerDetail(source: .ac, percent: 100, isCharging: false),
            PowerDetail(source: .battery, percent: 50, isCharging: false),
        ])
        try t.start()
        t.stop()
        t.tick()
        XCTAssertEqual(details().count, 1)
    }

    func testSystemReaderAlwaysDescribesThisMachinesPower() {
        // NOT "a Mac always has at least one power source" — that assumption is
        // false. `IOPSCopyPowerSourcesList` enumerates only battery/UPS-backed
        // sources, and on a desktop (verified on a Mac Studio drawing straight
        // from wall power, no UPS) the list is EMPTY.
        //
        // The reader still owes an answer there: no battery means wall power,
        // so it reports `.ac` with no charge figures. Asserting non-nil is
        // therefore a real assertion on every Mac, not a tautology — it fails
        // if the empty-list case ever goes back to returning nil, which would
        // make the power trigger silently dead on every desktop.
        let detail = SystemPowerStatusReader().read()
        let unwrapped = try? XCTUnwrap(detail)
        XCTAssertNotNil(unwrapped, "a machine with no battery is on AC, not unknown")
        if let unwrapped {
            XCTAssertTrue(unwrapped.source == .ac || unwrapped.source == .battery)
            if let percent = unwrapped.percent {
                XCTAssertTrue((0...100).contains(percent), "charge must be a percentage")
            }
        }
    }
}
#endif
