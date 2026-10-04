import Foundation
import AgenticToolkitCore

/// An `ActivityPersistence` held in memory, for tests and previews.
public final class InMemoryActivityStore: ActivityPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var storedSpans: [ActivitySpanDTO] = []
    private var storedIdle: [(from: String, until: String)] = []   // until "" = open
    private var prunePredicate: @Sendable (ActivitySpanDTO) -> Bool = { _ in true }

    public init() {}

    /// Stands in for "derived": only spans this accepts are pruned.
    /// It runs while the store's lock is held, so it must not touch the store.
    public var prunable: @Sendable (ActivitySpanDTO) -> Bool {
        get { lock.withLock { prunePredicate } }
        set { lock.withLock { prunePredicate = newValue } }
    }

    /// For test setup. The setter replaces the whole array and is not atomic
    /// for a read-modify-write (`store.spans.append(x)` can lose a concurrent write).
    public var spans: [ActivitySpanDTO] {
        get { lock.withLock { storedSpans } }
        set { lock.withLock { storedSpans = newValue } }
    }

    /// For test setup; same non-atomic read-modify-write caveat as `spans`.
    public var idle: [(from: String, until: String)] {
        get { lock.withLock { storedIdle } }
        set { lock.withLock { storedIdle = newValue } }
    }

    public func openActivitySpan(_ span: ActivitySpanDTO) throws {
        lock.withLock { storedSpans.append(span) }
    }

    public func closeActivitySpan(id: String, endedAt: String) throws {
        lock.withLock { close(id: id, endedAt: endedAt) }
    }

    public func retitleActivitySpan(id: String, title: String) throws {
        lock.withLock {
            if let index = storedSpans.firstIndex(where: { $0.id == id }) { storedSpans[index].windowTitle = title }
        }
    }

    public func touchActivitySpan(id: String, at: String) throws {
        lock.withLock {
            if let index = storedSpans.firstIndex(where: { $0.id == id }) { storedSpans[index].lastSeenAt = at }
        }
    }

    public func openIdleInterval(from: String) throws {
        lock.withLock {
            if !storedIdle.contains(where: { $0.until.isEmpty }) { storedIdle.append((from: from, until: "")) }
        }
    }

    public func closeIdleInterval(until: String) throws {
        lock.withLock {
            if let index = storedIdle.firstIndex(where: { $0.until.isEmpty }) { storedIdle[index].until = until }
        }
    }

    @discardableResult
    public func recoverActivity(now: String) throws -> Int {
        lock.withLock {
            let openIdleFrom = storedIdle.filter { $0.until.isEmpty }.map(\.from)
            let open = storedSpans.filter(\.isOpen)
            for span in open {
                let end = ActivityRecovery.recoveredEnd(startedAt: span.startedAt, lastSeenAt: span.lastSeenAt,
                                                        openIdleFrom: openIdleFrom)
                close(id: span.id, endedAt: end)
            }
            for index in storedIdle.indices where storedIdle[index].until.isEmpty { storedIdle[index].until = now }
            return open.count
        }
    }

    @discardableResult
    public func pruneActivity(endedBefore before: String) throws -> Int {
        lock.withLock {
            let spanCount = storedSpans.count
            storedSpans.removeAll { !$0.isOpen && $0.endedAt < before && prunePredicate($0) }
            let idleCount = storedIdle.count
            storedIdle.removeAll { !$0.until.isEmpty && $0.until < before }
            return (spanCount - storedSpans.count) + (idleCount - storedIdle.count)
        }
    }

    public func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        lock.withLock {
            let matching = storedSpans.filter { $0.isOpen || $0.endedAt >= since }
            return Array(matching.sorted { $0.startedAt > $1.startedAt }.prefix(max(0, limit)))
        }
    }

    public func openActivitySpans() throws -> [ActivitySpanDTO] {
        lock.withLock { storedSpans.filter(\.isOpen) }
    }

    /// Caller holds the lock.
    private func close(id: String, endedAt: String) {
        guard let index = storedSpans.firstIndex(where: { $0.id == id }) else { return }
        if UTCTimestamp.seconds(from: storedSpans[index].startedAt, to: endedAt) < 1 {
            storedSpans.remove(at: index)
        } else {
            storedSpans[index].endedAt = endedAt
        }
    }
}
