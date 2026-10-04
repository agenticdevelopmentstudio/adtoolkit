#if canImport(AgenticToolkitDatabase)
import Foundation
import AgenticToolkitDatabase

/// Starts and stops triggers subject to dual gating, and writes what they emit.
///
/// The two gates are independent and both required: the user's stored opt-in
/// (consent) and the OS permission (capability). A granted permission is not
/// consent, and consent cannot substitute for a permission — so neither one
/// alone starts a trigger.
///
/// The collector is the only thing that mints `ContextEvent`s: triggers hand
/// back a detail and a timestamp, and the machine id and the allowed/not-allowed
/// decision stay in one place.
///
/// More than one trigger may share a `kind` (they share that kind's single
/// opt-in, but each is started, gated, and stopped independently) — so
/// "is this trigger running" is tracked per trigger object, never per kind.
@MainActor
public final class ContextCollector {
    private let store: ContextStore
    private let settings: SettingsStore
    private let machine: MachineDescriptor
    private let gate: any ContextPermissionGate
    private let triggers: [any ContextTrigger]
    private let onWriteError: (@Sendable (Error) -> Void)?

    /// The triggers actually started, keyed by object identity rather than
    /// `kind`. Two triggers can share a `kind`; keying by `kind` would let one
    /// trigger's successful start also "cover" a sibling that never started —
    /// an un-started trigger writing to the store is exactly the consent bug
    /// this collector exists to prevent. An event arriving from a trigger not
    /// in this set is dropped — a trigger that keeps firing after `stop()` (a
    /// stale notification already in flight, say) must not write.
    private var running: Set<ObjectIdentifier> = []

    /// Set by ``stop()`` and cleared by ``start()``. Without it, "stopped" is
    /// only a statement about `running`, which the next resumption of an
    /// in-flight ``refresh()`` happily refills: `refresh` suspends at
    /// `await gate.status(...)`, the daemon shuts down in the meantime, and
    /// the resumed loop calls `startIfAllowed` on every trigger and starts
    /// them all again — after teardown, against a store that is being
    /// released. A flag, not a cancellation check, because the callers that
    /// matter (`ContextStrategy.stop`) are not the task `refresh` runs in.
    private var isStopped = false

    public init(store: ContextStore, settings: SettingsStore, machine: MachineDescriptor,
                gate: any ContextPermissionGate, triggers: [any ContextTrigger],
                onWriteError: (@Sendable (Error) -> Void)? = nil) {
        self.store = store
        self.settings = settings
        self.machine = machine
        self.gate = gate
        self.triggers = triggers
        self.onWriteError = onWriteError
        for trigger in triggers {
            let id = ObjectIdentifier(trigger)
            trigger.onEvent = { [weak self] detail, when in
                self?.record(id: id, detail: detail, at: when)
            }
        }
    }

    public func start() async {
        isStopped = false
        for trigger in triggers {
            if let error = await startIfAllowed(trigger) {
                onWriteError?(error)
            }
        }
    }

    /// After this returns, nothing starts a trigger again until ``start()``.
    public func stop() {
        isStopped = true
        for trigger in triggers where running.contains(ObjectIdentifier(trigger)) {
            trigger.stop()
        }
        running.removeAll()
    }

    /// Persists the choice and applies it immediately, so the user does not
    /// have to restart the daemon for a tick-box to take effect. Acts on
    /// every trigger of `kind` — they share this one opt-in but are started
    /// and stopped independently.
    public func setEnabled(_ kind: ContextEventKind, _ enabled: Bool) async throws {
        try settings.setTriggerEnabled(kind, enabled)
        let matching = triggers.filter { $0.kind == kind }
        if enabled {
            // Every matching trigger is attempted independently — one sibling
            // failing to attach must not stop the others from starting — but
            // the caller still needs to know a start failed, so the first
            // error is reported to onWriteError and rethrown once all
            // matching triggers have been attempted. The opt-in above has
            // already been persisted regardless: "the user said yes but the
            // observer would not attach" is real and must be reportable, not
            // silently undone.
            var firstError: Error?
            for trigger in matching {
                if let error = await startIfAllowed(trigger) {
                    onWriteError?(error)
                    if firstError == nil { firstError = error }
                }
            }
            if let firstError { throw firstError }
        } else {
            for trigger in matching where running.remove(ObjectIdentifier(trigger)) != nil {
                trigger.stop()
            }
        }
    }

    /// Re-evaluates BOTH gates for every trigger: starts the newly-allowed, and
    /// stops any running trigger whose opt-in or OS permission has since been
    /// withdrawn. `start()` gates once; a permission revoked in System Settings
    /// afterwards would otherwise keep the trigger recording forever.
    public func refresh() async {
        guard !isStopped else { return }
        for trigger in triggers {
            // Re-checked every iteration, not only on entry: each `await`
            // below is a suspension point at which `stop()` can run.
            guard !isStopped else { return }
            let id = ObjectIdentifier(trigger)
            if running.contains(id) {
                let stillEnabled = (try? settings.isTriggerEnabled(trigger.kind)) == true
                let stillGranted = await gate.status(trigger.requiredPermission) == .granted
                if !stillEnabled || !stillGranted {
                    trigger.stop()
                    running.remove(id)
                }
            } else if let error = await startIfAllowed(trigger) {
                onWriteError?(error)
            }
        }
    }

    /// Asks the OS for `permission` on behalf of the triggers that need it,
    /// but only if the user has actually opted into at least one of them.
    ///
    /// The opt-in check is the point (I-4): a permission request is a
    /// once-ever, user-visible act, and the app is not trusted to decide when
    /// it happens. Consent comes first and the capability second — the same
    /// ordering `startIfAllowed` enforces — so a client that asks for
    /// Location while every location trigger is switched off is refused
    /// rather than obeyed.
    ///
    /// `.none` never involves the OS, so it is granted without asking.
    /// On success this also `refresh()`es, so a trigger unblocked by the new
    /// grant starts now rather than at the next 30-second tick.
    public func requestPermission(_ permission: ContextPermission) async -> PermissionRequestResult {
        guard permission != .none else { return .granted }
        let wanted = triggers.contains { trigger in
            trigger.requiredPermission == permission
                && (try? settings.isTriggerEnabled(trigger.kind)) == true
        }
        guard wanted else { return .notNeeded }

        let state = await gate.request(permission)
        await refresh()
        switch state {
        case .granted:      return .granted
        case .denied:       return .denied
        case .undetermined: return .undetermined
        }
    }

    public func states() async -> [TriggerState] {
        var result: [TriggerState] = []
        for trigger in triggers {
            let enabled = (try? settings.isTriggerEnabled(trigger.kind)) ?? false
            let permissionState = await gate.status(trigger.requiredPermission)
            result.append(TriggerState(kind: trigger.kind, isEnabled: enabled,
                                       permission: trigger.requiredPermission,
                                       permissionState: permissionState,
                                       isRunning: running.contains(ObjectIdentifier(trigger))))
        }
        return result
    }

    // MARK: - Private

    /// Attempts to start `trigger` if it is not already running and both
    /// gates allow it. Returns the error thrown by `trigger.start()`, or
    /// `nil` on success or when a gate simply declined (not an error).
    private func startIfAllowed(_ trigger: any ContextTrigger) async -> Error? {
        let id = ObjectIdentifier(trigger)
        guard !isStopped else { return nil }
        guard !running.contains(id) else { return nil }
        guard (try? settings.isTriggerEnabled(trigger.kind)) == true else { return nil }
        guard await gate.status(trigger.requiredPermission) == .granted else { return nil }
        // Both gates are re-checked after the suspension, not just shutdown.
        // `await gate.status(...)` above releases the main actor — the
        // protocol requirement is nonisolated and `async`, so the call hops
        // to the generic executor for every trigger, `.none` ones included —
        // and the settings panel's `setEnabled(kind, false)` runs to
        // completion inside that window. It cannot defend itself: the trigger
        // is not in `running` yet (the insert is below), so the disable path
        // finds nothing to stop. Without this re-read the resumed loop starts
        // a trigger whose stored opt-in now says `false` and records with it
        // until the next `refresh()` tick notices — up to 30 seconds of
        // capture after the owner opted out.
        guard !isStopped else { return nil }
        guard (try? settings.isTriggerEnabled(trigger.kind)) == true else { return nil }
        // Marked running BEFORE `start()`, and unmarked again if `start()`
        // throws (I-1). A trigger may emit synchronously from inside its own
        // `start()` — `PowerTrigger` deliberately does, so the log opens with
        // a known power state, and `AppFocusTrigger` does via
        // `FrontmostFocusAdapter.start()`. With the insert after the call,
        // `record`'s `running` guard threw that opening event away. For
        // `power` that was permanent, not merely a missing first row:
        // the dropped `tick()` still set `last`, so on a desktop Mac (where
        // the reading is a constant) every later tick was deduplicated away
        // and an opted-in trigger wrote nothing for the daemon's whole life.
        //
        // Marking first is safe: `record` is the only reader of `running`,
        // this actor is not re-entered between the two lines, and any event
        // that arrives is by definition from a trigger the two gates above
        // have just approved. If `start()` throws, the trigger is removed
        // again, so a failed start never leaves a trigger marked running.
        running.insert(id)
        do {
            try trigger.start()
            return nil
        } catch {
            // One trigger failing to attach to the OS must not silence the
            // rest — a missing AX observer should not cost us battery data.
            running.remove(id)
            return error
        }
    }

    private func record(id: ObjectIdentifier, detail: ContextEventDetail, at when: Date) {
        guard running.contains(id) else { return }
        do {
            try store.insert(ContextEvent(machineID: machine.id, occurredAt: when, detail: detail))
        } catch {
            onWriteError?(error)
        }
    }
}
#endif
