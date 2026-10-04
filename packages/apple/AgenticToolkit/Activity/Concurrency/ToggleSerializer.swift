import Foundation
import os

/// FIFO-per-key serializer for latest-wins toggle convergence.
///
/// The bug this fixes: an independent, unordered `Task` spawned per request
/// lets two rapid calls apply out of order — the *older* request's `Task`
/// finishing last and silently overriding a newer one. This guarantees that
/// cannot happen, keyed by a `String` so independent toggles (e.g. two
/// different switches) converge independently of one another and never block
/// each other.
///
/// "Latest wins": the newest request for a key wins entirely, as one whole
/// unit — its value, its own `apply` closure, and its own `onResult` all
/// travel together, so a request superseded before it is ever applied is
/// dropped in full, not queued — its `apply` never runs and its `onResult`
/// (if any; `ReplyOnce`-backed callers get this for free) is simply never
/// invoked, and `ReplyOnce`'s own `deinit` answers it with `false` once the
/// dropped closure is released. That is a deliberately honest answer: the
/// superseded request never actually took effect, not even partially — no
/// caller's closure can run on another caller's behalf.
public final class ToggleSerializer: Sendable {
    private struct Pending {
        let value: Bool
        let apply: @Sendable (Bool) async -> Bool
        let onResult: (@Sendable (Bool) -> Void)?
    }
    private struct State {
        var pending: [String: Pending] = [:]
        var driving: Set<String> = []
    }
    private let lock = OSAllocatedUnfairLock(initialState: State())

    public init() {}

    /// Records `(value, apply, onResult)` as `key`'s pending request,
    /// synchronously, before this call returns — so concurrent callers still
    /// record their requests in true arrival order even though `apply` runs
    /// later, asynchronously, and a later call's whole unit replaces an
    /// earlier one's outright. If nothing is currently driving `key` toward
    /// convergence, becomes the driver: applies the latest pending request's
    /// own `apply`, using its own `onResult`, then checks again for one that
    /// arrived while `apply` was in flight, until the key's queue is empty.
    public func request(
        _ key: String, _ value: Bool,
        onResult: (@Sendable (Bool) -> Void)? = nil,
        apply: @escaping @Sendable (Bool) async -> Bool
    ) {
        // The superseded request is carried OUT of the critical section and
        // released here, at the end of this statement, rather than inside it.
        //
        // Overwriting the dictionary entry releases whatever it held, and for
        // the callers this exists for that release is not inert: a dropped
        // `Pending` holds the last reference to a `ReplyOnce`, whose `deinit`
        // answers the XPC reply with `false`. Running that under
        // `OSAllocatedUnfairLock` — which is not recursive — means an XPC
        // reply, and any code it reaches, executes while this lock is held;
        // a reply handler that called back into `request` for the same
        // serializer would deadlock outright, and every other reply pays the
        // cost of blocking the toggle queue while it runs.
        let (shouldDrive, superseded) = lock.withLock { state -> (Bool, Pending?) in
            let replaced = state.pending.updateValue(
                Pending(value: value, apply: apply, onResult: onResult), forKey: key)
            if state.driving.contains(key) { return (false, replaced) }
            state.driving.insert(key)
            return (true, replaced)
        }
        _ = superseded
        guard shouldDrive else { return }
        Task {
            while true {
                let next = lock.withLock { state -> Pending? in
                    guard let pending = state.pending.removeValue(forKey: key) else {
                        state.driving.remove(key)
                        return nil
                    }
                    return pending
                }
                guard let pending = next else { return }
                let result = await pending.apply(pending.value)
                pending.onResult?(result)
            }
        }
    }
}
