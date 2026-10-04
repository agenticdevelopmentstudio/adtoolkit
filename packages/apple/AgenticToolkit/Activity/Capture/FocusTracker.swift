import Foundation

// Public: `olylod` builds this directly (`FocusTracker()`) and hands it to
// `UsageCollector`'s public initializer. `handle`/`stop`/`current` stay
// internal — only `UsageCollector` (same module) and `@testable` tests call
// them.
public final class FocusTracker {
    private(set) var current: FocusSegment?
    private let makeID: () -> UUID
    public init(makeID: @escaping () -> UUID = UUID.init) { self.makeID = makeID }

    func handle(_ event: FocusEvent, now: Date) -> FocusSegment? {
        switch event {
        case .focus(let f):
            guard let cur = current else { open(f, now); return nil }
            if cur.focus == f { return nil }               // dedupe
            let reason: EndReason = (f.app == cur.focus.app && f.windowID == cur.focus.windowID && f.title != cur.focus.title)
                ? .titleChange : .focusChange
            let closed = close(reason, now)
            open(f, now)
            return closed
        case .idle:    return close(.idle, now)
        case .lock:    return close(.lock, now)
        case .sleep:   return close(.sleep, now)
        case .appQuit(let pid):
            guard current?.focus.app.pid == pid else { return nil }
            return close(.appQuit, now)
        }
    }

    func stop(now: Date) -> FocusSegment? { close(.collectorStop, now) }

    private func open(_ f: WindowFocus, _ now: Date) {
        current = FocusSegment(id: makeID(), startedAt: now, endedAt: nil, focus: f, endReason: nil)
    }
    private func close(_ reason: EndReason, _ now: Date) -> FocusSegment? {
        guard var seg = current else { return nil }
        seg.endedAt = now; seg.endReason = reason
        current = nil
        return seg
    }
}
