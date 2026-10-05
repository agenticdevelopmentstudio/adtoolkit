
- **Decision**: resolve the worker entry through the package's own `exports` map (`@agentic-toolkit/status-server/worker`) rather than a relative path to `worker.ts`.
  **Rationale**: the source comment states it plainly — a container image ships no `tsx`/TypeScript loader, so a relative path to the `.ts` source "would work in dev and die on first boot in prod"; resolving through `exports` always lands on the built `dist/monitor/worker.js`, "the only form guaranteed runnable in that container." `worker-boot.int.test.ts` exercises exactly this resolution path under bare `node`.
  **Approved**: pending
- **Decision**: attach the shared `cooldownState()` buffer inside `spawn()` itself rather than accepting it as part of the caller-supplied `opts.workerData`.
  **Rationale**: the source comment states the monitor cycle (worker thread) and the API thread's dashboard enumerations poll the SAME provider tokens, so a 429 either sees must back both off; sourcing the buffer internally on every spawn — rather than trusting the caller to keep passing the current one — guarantees a respawned worker always re-adopts the live registry, so an in-force cooldown survives a respawn.
  **Approved**: pending
- **Decision**: on a cycle timeout, reject only that call's own pending entry directly and terminate the worker without awaiting `worker.terminate()`'s own returned promise, relying on the resulting `"exit"` event to clean up every other pending entry.
  **Rationale**: the source comment states the intent directly — "kill the whole thread so its abandoned work stops consuming the container, and let the next cycle start clean" — and separately notes "terminate() also fires 'exit', which is why failAll below must tolerate an already-settled entry." The practical effect, not spelled out in the timeout branch itself, is that a timeout on one in-flight cycle also fails every other cycle sharing that worker; a reader of only the timeout branch would not expect that.
  **Approved**: pending
- **Decision**: never reset `seq` across a respawn.
  **Rationale**: not called out in a comment, but it is what makes `unmatched-reply-ignored` correct — if `seq` were reset to a value a still-terminating old worker might still emit a stale reply for, that reply could be mismatched to an unrelated, newer cycle. A monotonically increasing `seq` for the instance's whole lifetime makes any stale reply from a terminated worker unambiguously unmatchable.
  **Approved**: pending

