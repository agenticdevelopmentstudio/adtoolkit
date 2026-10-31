import Foundation

/// Inbound events waiting for the partner's next turn, oldest first.
///
/// An entry whose ``PartnerInbound/coalescingKey`` matches one already queued
/// replaces it in place: it keeps the position and takes the newer payload.
public struct PartnerTurnQueue: Sendable {
    private var entries: [PartnerInbound] = []

    public init() {}

    public var count: Int { entries.count }

    public mutating func enqueue(_ inbound: PartnerInbound) {
        if let key = inbound.coalescingKey,
           let index = entries.firstIndex(where: { $0.coalescingKey == key }) {
            entries[index] = inbound
        } else {
            entries.append(inbound)
        }
    }

    /// Puts `inbound` ahead of everything queued, without coalescing: for a
    /// notice the partner must read before any waiting event.
    public mutating func enqueueFirst(_ inbound: PartnerInbound) {
        entries.insert(inbound, at: 0)
    }

    public mutating func next() -> PartnerInbound? {
        entries.isEmpty ? nil : entries.removeFirst()
    }
}
