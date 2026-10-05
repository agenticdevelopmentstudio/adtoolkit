
- **Null or undefined input.** The server-side membership check called with
  `null` or `undefined` MUST return `false` — its signature accepts both
  explicitly and an early not-null guard rejects each before the allowlist
  check runs.
- **Empty string input.** The server-side membership check called with
  `''` MUST return `false` — the empty string is not one of the three
  allowlisted spellings.
- **Case-mismatched input.** The server-side membership check called with
  `'LOCAL'`, `'Production'`, `'PRODUCTION'` MUST return `false` — the
  comparison is case-sensitive and the source performs no normalization
  step.
- **Whitespace-padded build-time value.** A value of `'staging '` (trailing
  space, the shape of a real configuration typo) for the build-time-inlined
  variable MUST leave the build-time flag at `false` — the equality
  comparison performs no trimming.
- **Build-time variable unset at module load.** The build-time flag MUST be
  `false` — all three comparisons fail against an absent value.
- **Environment value changes after module load.** The build-time flag MUST
  NOT reflect a later change to the build-time-inlined variable in the same
  running process — it was computed once at first module evaluation;
  observing a new value requires a fresh module evaluation (a process
  restart, or, in a test, an explicit module-state reset followed by a
  re-import).
- **Non-string runtime value reaching the membership check.** If a value
  that is not a string (e.g. a number) crosses in despite the declared
  parameter type, a strict-equality membership check against the allowlist
  simply fails to match any of the three strings, and the function MUST
  return `false` without throwing.
- **Malformed or invalid input needing sanitization.** Not applicable
  beyond the fail-closed cases above — the function's entire purpose IS
  the validation (a strict allowlist membership test); there is no
  separate class of "malformed but not-yet-rejected" input.
- **Concurrent access.** Not applicable in the usual sense — the allowlist
  and the build-time flag are immutable values computed once at module
  load in a single-threaded execution model, and the server-side
  membership check is a pure function with no shared mutable state, so no
  two calls can interleave to produce an inconsistent result; this is a
  fact of the execution model, not an untested assumption.
- **Error / dependency-unavailable states.** Not applicable — the module
  performs no file, network, or database I/O, so there is no dependency
  that can be "unavailable."
- **Offline or disconnected state.** Not applicable — the module makes no
  network call of any kind.
- **Cancellation and timeouts.** Not applicable — every operation is a
  synchronous, in-memory comparison; there is no asynchronous or
  long-running work to cancel or time out.
- **Missing file or unreachable server.** Not applicable to this module at
  runtime — it reads only environment variables. (The cross-repo drift
  check that reads this file's *source text* runs inside a separate
  backend process's own test suite, not inside this module.)

