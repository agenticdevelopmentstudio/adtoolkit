
- **Empty batch**: running a match over an empty list, with a valid port,
  MUST still perform the two snapshot reads and MUST resolve to
  `{added: 0, skipped: [], notes: []}`. The progress callback is never
  called because there are no items.
- **Missing client and missing api**: the run MUST reject with the
  `client-required` error before any network call.
- **Project with no domain**: the engine's planner owns the verdict. The
  match operation MUST pass the project descriptor through unchanged and
  report whatever skip reason comes back.
- **Domain wired to another live project**: the run MUST record a skip with
  the engine's reason `that domain is already wired to <existingProject>`.
  This is a conflict, not an error.
- **Environment slot already taken**: the run MUST record a skip with the
  reason `its site's <environment> endpoint is already wired to
  <existingProject>`.
- **Opted-out or paused endpoint**: the endpoint MUST reach the engine with
  `ignoreProjectWarning: true`, so the engine's opt-out rules apply to it.
  Its `isActive` value never reaches the engine directly.
- **Per-project network failure**: the failing project MUST appear in
  `skipped` with the error message as its reason, and the batch MUST
  continue.
- **Snapshot read failure or backend unreachable**: the match operation MUST
  reject. The caller renders the failure (the per-platform project panel
  shows `Match failed — <message>`).
- **Non-error thrown value**: the skip reason MUST be a string conversion of
  the thrown value, per the engine's own formatting.
- **Concurrent runs**: two overlapping match-operation calls each MUST plan
  against their own snapshot. Neither sees the other's writes, and the
  backend's conflict handling decides the outcome. Guarding against this is
  the caller's job.
- **Hung request**: no timeout exists in this module. The run MUST stay
  pending until the client's transport settles, and the progress callback
  stops advancing.
- **Detail block with exactly 5 rows**: the block MUST list all 5 rows with
  no remainder line.
- **Detail block with 6 rows**: the block MUST list 5 rows followed by
  `…and 1 more`.
- **Project names or reasons containing newlines or bullets**: they MUST be
  inserted verbatim. The detail blocks do no escaping or sanitizing.

