
- Empty or all-whitespace `entityLabel`: the confirm gate MUST stay permanently disabled because
  the trimmed label's length check fails — no input can arm the Transfer button.
- Empty destination list: the dropdown menu content MUST render with no items when there are no
  candidate destinations.
- Deeply nested `children`: rendering MUST recurse through every level of nesting present, with
  no depth limit enforced.
- Duplicate `(kind, slug)` pairs across destination targets: callers MUST supply unique
  `(kind, slug)` pairs, since nothing in this component deduplicates them; the identity used to key
  each rendered item and match "(current)" is derived from `(kind, slug)`, so duplicates produce a
  rendering-list key collision.
- Concurrent selection (rapid re-choice): a sequence counter is the sole guard against a
  superseded preflight's resolution overwriting newer state; every settled preflight result MUST be
  checked against the current sequence number before it is allowed to touch state.
- Re-selecting the currently chosen target: choosing MUST run again from scratch — clearing the
  typed value, restarting the preflight, and advancing the sequence counter — since there is no
  short-circuit for choosing the same target twice.
- `currentTarget` undefined: no candidate MUST be treated as the current target when
  `currentTarget` itself is undefined, so no menu item is marked current/disabled from that guard
  alone.
- `currentTarget.kind` defined but a candidate target's `kind` undefined (or vice versa): MUST fall
  back to a slug-only match and treat the two as the same current target — the legacy behavior kept
  for targets that carry no `kind` (a nested Product).
- Error states: preflight and confirm rejections are both covered under
  `preview-error-shown-inline` and `transfer-error-shown-inline-dialog-stays-open` above, including
  the non-error-object rejection fallback text.
- Offline/disconnected state: this component performs no network call of its own; the preflight and
  confirm operations are caller-supplied asynchronous functions, and a connectivity failure surfaces
  through their rejection exactly like any other error — no behavior beyond the generic error
  handling above is defined or needed at this layer.

