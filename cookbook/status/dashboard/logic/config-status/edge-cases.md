
- **Absent `isActive`**: An endpoint without the field MUST be treated as active, keeping its warning (MUST; config-status-002).
- **Absent `ignoreProjectWarning`**: Treated as not opted out (MUST; config-status-007).
- **Both opt-outs set**: `ignoreProjectWarning: true` together with `isActive: false` yields `true` from the fold and `"ignored"` for an unwired endpoint, the same as either alone (MUST).
- **Paused and wired**: Classifies `configured`; pausing never downgrades a wired endpoint (MUST; config-status-004).
- **Infra kinds**: `health`, `custom` and `dns` classify `configured` even when paused or unwired (MUST; config-status-008).
- **Half-wired endpoint**: A `platform` without a `deployProject`, or the reverse, counts as unwired (MUST).
- **Empty strings**: `""` for `platform` or `deployProject` counts as missing (MUST; config-status-010).
- **Non-boolean values at runtime**: A value such as `isActive: 0` or `ignoreProjectWarning: "yes"` from untyped data is not `=== false` or `=== true`, so it is not an opt-out. The boolean type is the caller's precondition; no runtime check exists (MUST, as stated in no-validation).
- **Absent endpoint**: Passing no endpoint at all would fail on property access; the input contract forbids it and there is no guard (fact, not a handled case).
- **Concurrent access**: Not applicable — the functions are pure and synchronous and share no state, so calls cannot interleave.
- **Error states and offline**: Not applicable — the module performs no I/O, so there is no dependency that can fail or go offline.
- **Engine rule changes**: Any change to the engine's classifier (for example a new non-deploy kind) applies here unchanged, because this module only delegates (MUST, per status-delegates-to-engine).

