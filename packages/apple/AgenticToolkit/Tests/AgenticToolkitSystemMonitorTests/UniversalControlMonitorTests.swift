import Foundation
import Synchronization
import Testing
@testable import AgenticToolkitSystemMonitor

/// Lines and messages below are copied from a real incident: the laptop
/// (49018AB7) was being driven by the Studio (8A330823), tore the session
/// down, and dropped the Studio's input for 37 seconds.
@Suite("UniversalControlSessionLog")
struct UniversalControlSessionLogTests {

    @Test func readsEachSessionMessage() {
        #expect(UniversalControlSessionLog.event(in: "<private>: no virtual service; dropping events") == .droppedInput)
        #expect(UniversalControlSessionLog.event(in: "Current Source Device: 8A330823 -> nil")
            == .sourceChanged(previous: "8A330823", current: nil))
        #expect(UniversalControlSessionLog.event(in: "Current Source Device: nil -> 8A330823")
            == .sourceChanged(previous: nil, current: "8A330823"))
        #expect(UniversalControlSessionLog.event(in: "Connected Devices IDS: [49018AB7,8A330823]")
            == .connectedDevices(["49018AB7", "8A330823"]))
        #expect(UniversalControlSessionLog.event(in: "Connected Devices IDS: []") == .connectedDevices([]))
        #expect(UniversalControlSessionLog.event(in: "Local: 49018AB7, Source: '8A330823', Connected: []'")
            == .localDevice("49018AB7"))
    }

    @Test func ignoresEverythingElse() {
        #expect(UniversalControlSessionLog.event(in: "IDS 8A330823: Device Unavailable") == nil)
        #expect(UniversalControlSessionLog.event(in: "Current Source Device: garbled") == nil)
    }

    @Test func parsesAnNDJSONLine() throws {
        let line = Data("""
            {"timestamp":"2026-10-01 08:23:57.722969-0700","eventMessage":"Current Source Device: 8A330823 -> nil",\
            "subsystem":"com.apple.universalcontrol","category":"EVNT"}
            """.utf8)
        let entry = try #require(UniversalControlSessionLog.parse(line: line))
        #expect(entry.event == .sourceChanged(previous: "8A330823", current: nil))
        #expect(abs(entry.date.timeIntervalSince1970 - 1_790_868_237.722969) < 0.001)
    }

    @Test func skipsWhatLogPrintsAroundTheEntries() {
        #expect(UniversalControlSessionLog.parse(line: Data(#"Filtering the log data using "x""#.utf8)) == nil)
        #expect(UniversalControlSessionLog.parse(line: Data(#"{"count":7,"finished":1}"#.utf8)) == nil)
    }

    @Test func argumentsCarryThePredicate() {
        #expect(UniversalControlSessionLog.streamArguments().suffix(2)
            == ["--predicate", UniversalControlSessionLog.predicate])
        #expect(UniversalControlSessionLog.streamArguments(timeout: .seconds(90)).contains("90s"))
        #expect(UniversalControlSessionLog.historyArguments(lookback: .seconds(60)).prefix(1) == ["show"])
    }
}

@Suite("UniversalControlSessionState")
struct UniversalControlSessionStateTests {

    private let base = Date(timeIntervalSince1970: 1_790_000_000)

    private func at(_ seconds: TimeInterval, _ event: UniversalControlSessionEvent) -> UniversalControlSessionEntry {
        UniversalControlSessionEntry(date: base.addingTimeInterval(seconds), event: event)
    }

    @Test func dropsCloseTogetherAreOneStall() {
        var state = UniversalControlSessionState()
        for second in [0.0, 1, 3, 7, 20, 21] { state.apply(at(second, .droppedInput)) }
        let stalls = state.stalls
        #expect(stalls.count == 2)
        #expect(stalls[0].duration == 7)
        #expect(stalls[1].start == base.addingTimeInterval(20))
    }

    @Test func entriesOutOfOrderEndTheSame() {
        let entries = [
            at(0, .sourceChanged(previous: nil, current: "8A330823")),
            at(1, .connectedDevices(["8A330823"])),
            at(5, .sourceChanged(previous: "8A330823", current: nil)),
            at(6, .droppedInput),
            at(4, .droppedInput)
        ]
        var forward = UniversalControlSessionState()
        entries.forEach { forward.apply($0) }
        var backward = UniversalControlSessionState()
        entries.reversed().forEach { backward.apply($0) }
        backward.apply(entries[4])
        #expect(forward == backward)
        #expect(forward.currentSource == nil)
        #expect(forward.previousSource == "8A330823")
    }

    @Test func pruningForgetsOldDrops() {
        var state = UniversalControlSessionState()
        state.apply(at(0, .droppedInput))
        state.prune(now: base.addingTimeInterval(UniversalControlSessionState.recentWindow + 1))
        #expect(state.stalls.isEmpty)
    }
}

@Suite("UniversalControlMonitor")
struct UniversalControlMonitorTests {

    private static let base = Date(timeIntervalSince1970: 1_790_000_000)

    /// Hands over a fixed set of entries on `start`.
    private final class FixedSource: UniversalControlSessionSource {
        let entries: [UniversalControlSessionEntry]
        let failure: String?
        init(_ entries: [UniversalControlSessionEntry], failure: String? = nil) {
            self.entries = entries
            self.failure = failure
        }
        func start(deliver: @escaping @Sendable (UniversalControlSessionEntry) -> Void) {
            entries.forEach(deliver)
        }
    }

    private static let agent = ProcessSample(
        pid: 1138,
        name: "UniversalControl",
        path: "/System/Library/CoreServices/UniversalControl.app/Contents/MacOS/UniversalControl",
        residentBytes: 0,
        cpuTimeNanoseconds: 0
    )

    private func monitor(
        _ events: [(TimeInterval, UniversalControlSessionEvent)],
        now: TimeInterval,
        running: Bool = true,
        failure: String? = nil
    ) -> UniversalControlMonitor {
        let entries = events.map {
            UniversalControlSessionEntry(date: Self.base.addingTimeInterval($0.0), event: $0.1)
        }
        return UniversalControlMonitor(
            feed: FixedSource(entries, failure: failure),
            processes: { running ? [Self.agent] : [] },
            now: { Self.base.addingTimeInterval(now) }
        )
    }

    private let session: [(TimeInterval, UniversalControlSessionEvent)] = [
        (0, .localDevice("49018AB7")),
        (1, .connectedDevices(["8A330823"])),
        (1, .sourceChanged(previous: nil, current: "8A330823"))
    ]

    @Test func offWhenTheAgentIsNotRunning() {
        let reading = monitor(session + [(2, .droppedInput)], now: 3, running: false).sample()
        #expect(reading.level == .normal)
        #expect(reading.value == "Off")
    }

    @Test func connectedSessionIsNormal() {
        let reading = monitor(session, now: 60).sample()
        #expect(reading.id == "universal-control")
        #expect(reading.level == .normal)
        #expect(reading.value == "Connected")
        #expect(reading.detail == "1 Mac · input from 8A330823")
    }

    @Test func thisMacAsSourceIsNamed() {
        let handover: (TimeInterval, UniversalControlSessionEvent) =
            (2, .sourceChanged(previous: "8A330823", current: "49018AB7"))
        let reading = monitor(session + [handover], now: 60).sample()
        #expect(reading.detail == "1 Mac · input from this Mac")
    }

    @Test func idleWithNoOneConnected() {
        let reading = monitor(session + [(2, .connectedDevices([]))], now: 60).sample()
        #expect(reading.value == "Idle")
    }

    @Test func droppingInputNowIsCritical() {
        let stall: [(TimeInterval, UniversalControlSessionEvent)] = [
            (10, .sourceChanged(previous: "8A330823", current: nil)),
            (10, .connectedDevices([])),
            (19, .droppedInput),
            (40, .droppedInput),
            (44, .droppedInput)
        ]
        let reading = monitor(session + stall, now: 50).sample()
        #expect(reading.level == .critical)
        #expect(reading.value == "Dropping input")
        #expect(reading.detail.hasPrefix("From 8A330823 for 4s"))
    }

    @Test func aRecentStallIsAWarning() {
        let stall: [(TimeInterval, UniversalControlSessionEvent)] = [
            (10, .sourceChanged(previous: "8A330823", current: nil)),
            (11, .droppedInput),
            (14, .droppedInput),
            (30, .sourceChanged(previous: nil, current: "8A330823"))
        ]
        let reading = monitor(session + stall, now: 120).sample()
        #expect(reading.level == .warning)
        #expect(reading.value == "1 input stall")
        #expect(reading.detail.contains("for 3s"))
    }

    @Test func aStallPastTheWindowIsForgotten() {
        let stall: [(TimeInterval, UniversalControlSessionEvent)] = [(11, .droppedInput)]
        let reading = monitor(session + stall, now: 12 + UniversalControlSessionState.recentWindow).sample()
        #expect(reading.level == .normal)
    }

    @Test func anUnreadableLogIsUnavailable() {
        let reading = monitor([], now: 0, failure: "log exited 64").sample()
        #expect(reading.level == .unknown)
        #expect(reading.detail == "log exited 64")
    }
}

@Suite("UniversalControlSessionFeed")
struct UniversalControlSessionFeedTests {

    private final class Received: Sendable {
        let events = Mutex<[UniversalControlSessionEvent]>([])
    }

    @Test func deliversWhatTheCommandPrints() async throws {
        let line = #"{"timestamp":"2026-10-01 08:23:57.722969-0700","#
            + #""eventMessage":"Connected Devices IDS: [8A330823]"}"#
        let feed = UniversalControlSessionFeed(
            executableURL: URL(fileURLWithPath: "/bin/echo"),
            streamArguments: [line],
            historyArguments: nil
        )
        let received = Received()
        feed.start { entry in received.events.withLock { $0.append(entry.event) } }
        for _ in 0..<100 where received.events.withLock({ $0.isEmpty }) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(received.events.withLock { $0.first } == .connectedDevices(["8A330823"]))
        #expect(feed.failure == nil)
    }

    @Test func reportsACommandThatFails() async throws {
        let feed = UniversalControlSessionFeed(
            executableURL: URL(fileURLWithPath: "/usr/bin/false"),
            streamArguments: [],
            historyArguments: nil
        )
        feed.start { _ in }
        for _ in 0..<100 where feed.failure == nil {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(feed.failure?.hasPrefix("log exited 1") == true)
    }
}
