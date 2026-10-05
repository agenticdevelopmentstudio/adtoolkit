
### Construction and Opaque Connection Type

- **generic-connection-parameter**: The worker client MUST accept its database connection value only as an opaque type parameter and MUST NOT import or reference any concrete connection type of its own.
- **constructor-injected-configuration**: The constructor MUST accept exactly one configuration argument shaped as a cycle-timeout duration plus worker data carrying the connection value and the status configuration, and MUST store it unchanged for the lifetime of the instance; every later spawn MUST read the connection value and configuration from that same stored value.

### Spawn and Worker Entry Resolution

- **lazy-spawn-on-first-call**: Running a cycle MUST spawn a worker only when no worker currently exists, and MUST reuse the existing worker on every subsequent call until it is cleared to nothing by a timeout, a crash, or an exit.
- **worker-entry-via-package-exports**: Spawning MUST resolve the worker's entry point through the host package's own published-exports mechanism, and MUST NOT use a relative filesystem path to the worker's source file.
- **cooldowns-attached-at-spawn**: Spawning MUST construct the worker's data as the stored connection value and status configuration plus a cooldowns field set to the current value of the shared cooldown-state buffer, and this cooldowns field MUST NOT be read from the caller-supplied worker data.
- **cooldown-buffer-shared-across-respawns**: Every respawn (a new spawn after the worker reference was cleared) MUST attach the same live cooldown-state buffer as the previous spawn, so a provider cooldown recorded before a respawn remains in force afterward.

### Cycle Request Dispatch

- **monotonic-sequence-numbers**: Each cycle run MUST assign the request a sequence number strictly greater than every sequence number assigned by any earlier call on the same instance, starting at `1` for the instance's first call, and this counter MUST NOT be reset by a respawn.
- **single-request-per-call**: Running a cycle MUST post exactly one cycle-request message (carrying the sequence number and a full-sync flag) to the worker per call, and MUST NOT post more than one message for that call under any circumstance.

### Timeout Handling

- **cycle-timeout-rejection-message**: If no cycle-reply for a call's sequence number arrives within the configured cycle-timeout duration, the call's promise MUST reject with an error whose message is exactly `` monitor cycle exceeded <cycleTimeoutMs>ms — worker terminated; next cycle respawns it `` , with `<cycleTimeoutMs>` substituted by the configured value in milliseconds.
- **timeout-terminates-and-clears-worker**: On that same timeout, the client MUST remove the timed-out sequence number's entry from the pending-request table, MUST clear its stored worker reference to nothing, and MUST terminate the timed-out worker, so the next cycle run spawns a fresh worker.

### Reply Correlation

- **reply-ok-resolves-void**: A cycle-reply carrying an ok flag of `true` MUST resolve the pending promise matching its sequence number with no value.
- **reply-not-ok-rejects-with-message**: A cycle-reply carrying an ok flag of `false` MUST reject the pending promise matching its sequence number with an error whose message is the reply's error field when present, or the literal string `monitor cycle failed` when the error field is absent.
- **reply-clears-timer-and-pending-entry**: On receiving any cycle-reply that matches a sequence number still in the pending-request table, the client MUST clear that entry's timeout timer and remove the entry from the table before resolving or rejecting its promise.
- **unmatched-reply-ignored**: A cycle-reply whose sequence number has no entry in the pending-request table (already timed out and removed, or never issued) MUST be ignored — the client MUST NOT throw, log, or otherwise act on it.

### Worker Crash and Exit

- **worker-error-rejects-all-pending**: On the worker's error event, the client MUST reject every entry currently in the pending-request table with an error whose message is `` monitor worker crashed: <err.message> `` .
- **worker-exit-rejects-all-pending**: On the worker's exit event, regardless of exit code, the client MUST reject every entry currently in the pending-request table with an error whose message is `` monitor worker exited (<code>) `` .
- **crash-or-exit-clears-worker-reference-conditionally**: On either event, the client MUST clear its stored worker reference to nothing only if that reference still points at the worker instance the event fired on, leaving it untouched if a newer worker has already replaced it.
- **failall-tolerates-empty-pending**: The crash/exit handling MUST NOT throw when the pending-request table is already empty — including the case where an error event and an exit event both fire for the same crash, or where an exit event follows a termination whose own timeout branch already removed and settled that entry.
- **terminated-worker-exit-cascades-to-sibling-pending**: When a termination call (from a timeout on one sequence number) causes the worker's exit event to fire, that event MUST still reject every OTHER entry currently in the pending-request table for that worker — even one whose own cycle-timeout window has not yet elapsed — with the exit-event message, not a timeout message.

### Concurrency

- **no-single-flight-guard**: The worker client MUST NOT prevent two or more cycle runs from being in flight simultaneously against the same worker; each MUST be tracked independently by its own sequence number in the pending-request table, with no serialization of the underlying message posts.

