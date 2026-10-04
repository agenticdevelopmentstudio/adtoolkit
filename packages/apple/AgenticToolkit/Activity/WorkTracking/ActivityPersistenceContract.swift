import Foundation
import AgenticToolkitCore

/// Checks every `ActivityPersistence` must pass. Returns failure messages
/// (empty = pass) so a host can run them from its own XCTest target.
/// Prune is not here: what "derived" means is the host's.
/// The protocol does not expose idle intervals, so the checks observe them
/// through recovery.
public enum ActivityPersistenceContract {
    private static let base = "2026-10-01T09:00:00Z"

    private static func at(_ offset: Int) -> String {
        UTCTimestamp.adding(offset, to: base) ?? base
    }

    private static func span(_ id: String, start: Int = 0) -> ActivitySpanDTO {
        ActivitySpanDTO(id: id, bundleId: "com.apple.dt.Xcode", appName: "Xcode", windowTitle: "t",
                        startedAt: at(start), tz: "UTC")
    }

    private typealias Check = (any ActivityPersistence, inout [String]) throws -> Void

    public static func runAll(_ make: () throws -> any ActivityPersistence) throws -> [String] {
        var failures: [String] = []
        let checks: [(String, Check)] = [
            ("open then close", openThenClose),
            ("close under 1s", closeUnderOneSecond),
            ("retitle and touch", retitleAndTouch),
            ("single open idle interval", singleOpenIdle),
            ("closed idle interval", closedIdle),
            ("recovery with heartbeat", recoveryWithHeartbeat),
            ("recovery without heartbeat", recoveryWithoutHeartbeat),
            ("recovery with idle", recoveryWithIdle),
            ("listing", listing)
        ]
        for (name, check) in checks {
            var local: [String] = []
            try check(try make(), &local)
            failures += local.map { "\(name): \($0)" }
        }
        return failures
    }

    private static func endedAt(_ store: any ActivityPersistence, _ id: String) throws -> String? {
        try store.activitySpans(since: at(-10), limit: 50).first { $0.id == id }?.endedAt
    }

    private static func openThenClose(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.closeActivitySpan(id: "a", endedAt: at(60))
        if !(try store.openActivitySpans()).isEmpty { out.append("span still open after close") }
        let ended = try endedAt(store, "a")
        if ended != at(60) { out.append("endedAt is \(ended ?? "nil"), expected \(at(60))") }
    }

    private static func closeUnderOneSecond(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.closeActivitySpan(id: "a", endedAt: base)
        if !(try store.activitySpans(since: at(-10), limit: 10)).isEmpty { out.append("sub-second span was kept") }
    }

    private static func retitleAndTouch(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.retitleActivitySpan(id: "a", title: "new")
        try store.touchActivitySpan(id: "a", at: at(30))
        let found = try store.openActivitySpans().first
        if found?.windowTitle != "new" { out.append("title not changed") }
        if found?.lastSeenAt != at(30) { out.append("lastSeenAt not set") }
    }

    private static func singleOpenIdle(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.touchActivitySpan(id: "a", at: at(120))
        try store.openIdleInterval(from: at(60))
        try store.openIdleInterval(from: at(30))   // ignored: one is already open
        try store.recoverActivity(now: at(3600))
        let ended = try endedAt(store, "a")
        if ended != at(60) { out.append("span ended \(ended ?? "nil"), expected the first idle start \(at(60))") }
    }

    private static func closedIdle(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.touchActivitySpan(id: "a", at: at(120))
        try store.openIdleInterval(from: at(60))
        try store.closeIdleInterval(until: at(90))
        try store.recoverActivity(now: at(3600))
        let ended = try endedAt(store, "a")
        if ended != at(120) { out.append("closed idle still affected recovery, ended \(ended ?? "nil")") }
    }

    private static func recoveryWithHeartbeat(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.touchActivitySpan(id: "a", at: at(120))
        let count = try store.recoverActivity(now: at(3600))
        if count != 1 { out.append("expected 1 span closed, got \(count)") }
        let ended = try endedAt(store, "a")
        if ended != at(120) { out.append("ended \(ended ?? "nil"), expected heartbeat \(at(120))") }
    }

    private static func recoveryWithoutHeartbeat(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.recoverActivity(now: at(3600))
        if !(try store.activitySpans(since: at(-10), limit: 10)).isEmpty {
            out.append("span with no heartbeat ends at its start and should be deleted")
        }
    }

    private static func recoveryWithIdle(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("a"))
        try store.touchActivitySpan(id: "a", at: at(120))
        try store.openIdleInterval(from: at(60))
        try store.recoverActivity(now: at(3600))
        let ended = try endedAt(store, "a")
        if ended != at(60) { out.append("ended \(ended ?? "nil"), expected idle start \(at(60))") }
        // The idle interval was closed at `now`, so a new one may open (it would be ignored if still open).
        try store.openActivitySpan(span("b", start: 4000))
        try store.touchActivitySpan(id: "b", at: at(4100))
        try store.openIdleInterval(from: at(4050))
        try store.recoverActivity(now: at(5000))
        let second = try endedAt(store, "b")
        if second != at(4050) { out.append("idle interval not closed by recovery, b ended \(second ?? "nil")") }
    }

    private static func listing(_ store: any ActivityPersistence, _ out: inout [String]) throws {
        try store.openActivitySpan(span("old", start: 0))
        try store.closeActivitySpan(id: "old", endedAt: at(60))
        try store.openActivitySpan(span("mid", start: 100))
        try store.closeActivitySpan(id: "mid", endedAt: at(160))
        try store.openActivitySpan(span("live", start: 200))
        let ids = try store.activitySpans(since: at(-10), limit: 10).map(\.id)
        if ids != ["live", "mid", "old"] { out.append("got \(ids), expected newest first including open") }
        let limited = try store.activitySpans(since: at(-10), limit: 2).map(\.id)
        if limited != ["live", "mid"] { out.append("limit not respected: \(limited)") }
    }
}
