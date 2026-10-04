import Foundation
import os

/// Guarantees a completion closure is invoked exactly once: at most once
/// because repeat calls are dropped, and at least once because releasing this
/// object without an answer sends `fallback` instead.
///
/// XPC reply blocks are the motivating case. Replying twice traps inside
/// libxpc and takes the whole process down; never replying leaves the peer
/// waiting until the connection itself dies. Neither property is checkable at
/// the point where a reply block is handed to a closure that answers it from
/// another actor, later — which is exactly the shape the daemon's XPC service
/// uses.
///
/// The at-least-once half is `deinit`, so it fires whenever the last reference
/// goes away unanswered — including the common `Task { guard let self else
/// { return } }` early return, which drops its captures. A closure that keeps
/// this object alive forever gets no fallback; that is deliberate, since a
/// reply may legitimately be pending for a long time.
///
/// Nothing here is platform-specific: it is a lock and reference counting.
public final class ReplyOnce<Value: Sendable>: Sendable {
    private let pending: OSAllocatedUnfairLock<(@Sendable (Value) -> Void)?>
    private let fallback: Value

    public init(fallback: Value, _ reply: @escaping @Sendable (Value) -> Void) {
        self.fallback = fallback
        self.pending = OSAllocatedUnfairLock(initialState: reply)
    }

    /// Answers with `value`. Every call after the first is ignored.
    public func callAsFunction(_ value: Value) {
        take()?(value)
    }

    deinit {
        take()?(fallback)
    }

    /// Claims the closure, leaving nothing behind. Taking under the lock is
    /// what makes "exactly once" true when two threads race to answer.
    private func take() -> (@Sendable (Value) -> Void)? {
        pending.withLock { reply in
            defer { reply = nil }
            return reply
        }
    }
}
