
- **Empty capabilities list.** The reports check called with an empty
  capabilities list MUST return `false` for every case — an empty list
  contains no match for any spelling set, and no crash occurs. MUST.
- **Bare resolved model with no evidence.** A resolved model with no
  description, "good for" text, capabilities, or tools flag set MUST have
  the has check return `false` for every case except when extra text
  alone supplies conversation evidence. MUST.
- **Boundary values: not applicable in the numeric sense.** The only
  bounded input is this capability type itself, a fixed four-case type
  with no numeric range to bound. The capabilities list and the extra
  text are unbounded collections/strings with no length check anywhere in
  the source.
- **Concurrent access.** This type is safe to pass across concurrent
  boundaries; every operation is a pure function of its arguments with no
  shared mutable state, and the resolved model is itself a value type
  comparable for equality and safe to pass across concurrent boundaries,
  built from immutable fields. Concurrent calls from any context MUST be
  safe with no additional synchronization — this is safe by construction,
  not merely untested.
- **Error states: not applicable.** No operation on this type raises an
  error, returns an error type, or calls anything that can fail; the
  reports check, has check, and capabilities-of computation are total
  functions over their arguments.
- **Offline/disconnected: not applicable.** This component performs no
  network or file I/O; it operates only on in-memory strings and an
  already-resolved model value.
- **Duplicate/redundant spellings.** A capabilities list containing
  `"tools"`, `"tool_use"`, and `"TOOLS"` together MUST still yield a
  `true` reports check for `tools` — matching one entry is sufficient,
  and repeated matches change nothing observable. MUST.
- **Unrecognized capability string.** A capabilities list containing
  `"moonwalk"` MUST NOT match any case; the reports check MUST return
  `false` for all four cases, and the has check for `tools` still falls
  back to the resolved model's tools flag rather than treating the
  unknown string as evidence. MUST.
- **Extra text present but empty.** An empty extra-text string MUST
  behave identically to an absent extra text for word-matching purposes:
  the use-facets computation joins the non-empty text pieces with a
  space, and an empty piece contributes no additional words to match
  against. MUST.

