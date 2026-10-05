
- **Empty title**: a window with `title` equal to `""` — window info MUST accept it (info-empty-title); the window matcher's fallback fingerprint then uses `appOnly` with an empty `titlePattern`.
- **Empty or whitespace pattern**: `titlePattern` of `""` or `" "` — window fingerprint MUST store it verbatim; whether it matches is the matcher's decision (an empty regex scores 0, a pattern shorter than the minimum substring length scores 0 unless it is an exact match).
- **Invalid regex source**: `titlePattern` that does not compile, with `appAndTitleRegex` — the fingerprint MUST accept it; the matcher logs the error and returns no match, so the error is reported, not swallowed.
- **Empty context**: `windowSnapshots` is empty — the live-window count MUST return `0`, looking up a snapshot by `id` MUST return no value, both remove operations MUST return no value, and both update operations MUST return `false`.
- **All dormant**: every snapshot has `windowID` absent — the live-window count MUST return `0` and the remove-by-`windowID` and update-by-`windowID` operations MUST match nothing for any argument.
- **Duplicate live window IDs in one context**: reachable only by adding window snapshots directly with distinct `id`s — the by-`windowID` operations MUST act on the first match in list order only (remove-by-window-id); the managing layer prevents this state.
- **Duplicate snapshot IDs**: reachable only by constructing `windowSnapshots` directly — adding a snapshot, removing by `id`, looking up by `id` and updating by `id` MUST act on the first match only.
- **Stale focus**: `lastFocusedWindowID` set to an ID not in `windowSnapshots` — window context MUST keep it (focus-not-validated); consumers resolving it get no value from looking up by `id`.
- **Focus cleared only by removal**: replacing the focused snapshot by adding a window snapshot, or making it dormant through an update, MUST leave `lastFocusedWindowID` unchanged.
- **Boundary values**: window and display identifiers at their minimum and maximum representable values, a `pid` of `0` or negative, `layer` at any representable value, and a zero- or negative-size frame MUST be stored unchanged; none of the types range-checks numeric fields.
- **Malformed color**: `color` of `""`, `"red"` or `"#GGG"` MUST be stored verbatim; interpreting it is the renderer's job, and the field's documented `#`-prefixed hex form is only the caller's precondition.
- **Unknown strategy on disk**: persisted JSON with a `matchStrategy` string not among the four raw values — decoding MUST fail, failing the whole enclosing context's decode (strategy-unknown-raw); the context store wraps that failure in its "Failed to decode data at <path>" error.
- **Older or newer schema**: JSON missing a required key MUST fail to decode (missing-key-throws); extra unknown keys MUST be ignored by the decoder.
- **Concurrent access**: all types are safe to use across concurrent execution contexts, with no shared mutable state; each mutation acts on the caller's own copy, and it is the platform's and caller's responsibility, not the type's, to prevent simultaneous access to one variable.
- **Error states**: none of the operations can fail; "not found" is reported as an absent value or `false` and the only throwing paths are serialization decoding, which surfaces a decoding error to the caller.
- **Cancellation and timeouts**: not applicable; every operation is a synchronous in-memory computation with nothing to cancel.
- **Offline or disconnected state**: not applicable; the types perform no network access.

