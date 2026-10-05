
- **Null/empty input**: an empty set of item titles MUST make presenting a
  request add a single `OK` button and return nothing unconditionally, per
  **empty-items-single-ok** (MUST).
- **Null/empty input**: an absent detail MUST be treated as "assign nothing
  to the detail text," not coerced to an empty string, per
  **detail-text-conditional** (MUST).
- **Null/empty input**: an empty message string MUST be accepted and
  assigned to the message text unchanged; the code performs no non-empty
  validation, so a caller MUST NOT assume the message is non-empty before
  this presenter is reached (MUST NOT).
- **Boundary values**: item titles of exactly one entry, unflagged, MUST
  make planning the button layout return a two-entry plan (`[0, nothing]`),
  and computing the Escape-key position MUST then assign Escape to the
  second (cancel) slot, since the plan has more than one entry (MUST).
- **Boundary values**: item titles of exactly one entry, flagged as a close
  affordance, MUST make planning the button layout return a one-entry plan
  (`[0]`) holding that item's own index, and computing the Escape-key
  position MUST return nothing for it, leaving that sole button's default
  key equivalent untouched, per the source's own rationale for why a
  one-entry plan is the exception (MUST).
- **Boundary values**: every entry in the item titles flagged (two or more
  items) MUST make planning the button layout return a one-entry plan
  holding only the *last* flagged index; every other flagged item's button
  MUST NOT be added (MUST / MUST NOT).
- **Concurrent access**: this component's confinement to a single execution
  context serializes the synchronous portion of each presentation call on
  a given instance, but does not by itself serialize the calls across the
  asynchronous wait inside resolving the response — see
  **concurrent-presentation-ordering** below.
- **Concurrent access**: an instance MUST NOT be called from outside its
  own confined execution context except by an asynchronous call across
  that boundary (MUST NOT).
- **Error states**: resolving the presentation window returning nothing (no
  window anywhere in the app) MUST cause the message to be logged at error
  level and MUST resolve presenting a request to nothing rather than
  crash, fail, or block the caller, per **drop-when-no-window** and
  **dropped-message-logged** (MUST).
- **Error states**: a button index computed from the alert's response that
  does not index into the button-plan entries MUST resolve to nothing
  rather than trap on an out-of-bounds access, per
  **out-of-range-response-resolves-absent** (MUST).
- **Cancellation and timeouts**: presenting a request defines no timeout of
  its own and does not observe cancellation of its enclosing task; a caller
  whose enclosing task is cancelled while awaiting presentation MUST NOT
  assume the alert is dismissed or the underlying wait is resumed early,
  because the source implements no cancellation-handling path for this call
  (MUST NOT).
- **Offline or disconnected state**: not applicable — the source performs
  no network access of its own.
- **Missing file or unreachable server**: not applicable — the source opens
  no file and makes no network or process call of its own.

- **concurrent-presentation-ordering**: this component is confined to a
  single execution context, so each presentation call's synchronous
  portion runs serially, but that confinement is reentrant at the
  asynchronous wait inside resolving the response: a second call MAY reach
  the underlying presentation call before the first alert is dismissed. The
  presenter adds no queuing or coalescing of its own; a second alert on the
  same window is ordered by the platform's own alert queue, and each call's
  wait resumes independently with its own alert's response.

