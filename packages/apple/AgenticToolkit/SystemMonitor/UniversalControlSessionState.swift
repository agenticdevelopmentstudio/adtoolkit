import Foundation

/// What the log has said about this Mac's Universal Control session, folded
/// from `UniversalControlSessionEntry`s.
///
/// Entries reach it from two places that overlap and race — the history read
/// at start and the live stream — so each field keeps the date of the entry
/// that set it and only a newer entry replaces it. Applying the same entry
/// twice, or two entries out of order, ends in the same state.
public struct UniversalControlSessionState: Sendable, Equatable {

    /// How far back dropped input is remembered and reported.
    public static let recentWindow: TimeInterval = 15 * 60
    /// Drops this close together are one stall.
    public static let stallGap: TimeInterval = 5

    /// One run of dropped input, first drop to last.
    public struct Stall: Sendable, Equatable {
        public let start: Date
        public let end: Date
        public var duration: TimeInterval { end.timeIntervalSince(start) }
    }

    private struct Stamped<Value: Sendable & Equatable>: Sendable, Equatable {
        var value: Value
        var date: Date
    }

    private var source: Stamped<String?>?
    /// The last Mac that was the source, kept when the source goes to `nil`:
    /// that is whose input a stall is dropping.
    private var lastSource: Stamped<String>?
    private var connected: Stamped<[String]>?
    private var local: Stamped<String>?
    /// Sorted.
    private var drops: [Date] = []

    public init() {}

    public var currentSource: String? { source?.value ?? nil }
    public var previousSource: String? { lastSource?.value }
    public var connectedDevices: [String] { connected?.value ?? [] }
    public var localDevice: String? { local?.value }
    /// Whether anything about the session has been seen yet.
    public var hasSessionState: Bool { source != nil || connected != nil }

    public mutating func apply(_ entry: UniversalControlSessionEntry) {
        let date = entry.date
        switch entry.event {
        case .droppedInput:
            // A stall is its first and last drop, so a repeat adds nothing.
            guard !drops.contains(date) else { return }
            let index = drops.firstIndex { $0 > date } ?? drops.endIndex
            drops.insert(date, at: index)
        case let .sourceChanged(previous, current):
            Self.update(&source, to: current, at: date)
            if let named = current ?? previous { Self.update(&lastSource, to: named, at: date) }
        case .connectedDevices(let devices):
            Self.update(&connected, to: devices, at: date)
        case .localDevice(let id):
            Self.update(&local, to: id, at: date)
        }
    }

    /// Forgets drops older than `recentWindow` before `now`.
    public mutating func prune(now: Date) {
        let cutoff = now.addingTimeInterval(-Self.recentWindow)
        drops.removeAll { $0 < cutoff }
    }

    /// The stalls in the drops still remembered, oldest first.
    public var stalls: [Stall] {
        var stalls: [Stall] = []
        for drop in drops {
            if let last = stalls.last, drop.timeIntervalSince(last.end) <= Self.stallGap {
                stalls[stalls.count - 1] = Stall(start: last.start, end: drop)
            } else {
                stalls.append(Stall(start: drop, end: drop))
            }
        }
        return stalls
    }

    private static func update<Value>(_ field: inout Stamped<Value>?, to value: Value, at date: Date) {
        if let existing = field, existing.date > date { return }
        field = Stamped(value: value, date: date)
    }
}
