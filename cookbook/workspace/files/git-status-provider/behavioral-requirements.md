
- **color-mapping-per-status**: Each status value MUST resolve to a fixed
  hue, expressed as a color value in the platform's primary UI color type:
  orange for modified, green for added and untracked, red for deleted, blue
  for renamed and copied, purple for conflicted, and gray for ignored.
- **secondary-color-mapping-per-status**: On a platform whose UI layer ships
  more than one native color type, the same status-to-hue mapping MUST also
  be provided as a color value in each additional color type: orange for
  modified, green for added and untracked, red for deleted, blue for renamed
  and copied, purple for conflicted, and gray for ignored (see Platform
  Notes for the exact types used on Apple platforms).
- **color-representations-parity**: For every status value, every color
  representation the platform provides MUST name the same semantic hue
  (orange/orange, green/green, red/red, blue/blue, purple/purple,
  gray/gray) — two (or more) spellings of one fact rather than separate
  facts, so whichever UI layer draws a badge, red still means deleted.
- **refresh-result-cases**: The refresh-result type MUST provide exactly two
  cases, a status case wrapping the resulting status value and an
  unavailable case, and MUST be safe to share across concurrent observers.
- **observer-registration**: The observer-registration operation MUST
  register the supplied observer under a fresh UUID key so it receives
  every result the provider produces from the moment of registration
  onward, and MUST NOT replay any result delivered before it was
  registered.
- **observation-token-unregisters-on-release**: The observation token
  returned by the observer-registration operation MUST be the only way to
  stop receiving results; releasing it MUST remove the corresponding entry
  from the observers map, triggered automatically by the token's own
  deallocation rather than by a separate unregister call.
- **weak-reference-in-cancellation-closure**: The unregistration action
  associated with an observation token MUST hold a weak reference to the
  provider, so an outstanding, unreleased token MUST NOT keep the provider
  alive.
- **broadcast-to-all-observers**: A single refresh call's result MUST be
  delivered to every observer registered on the provider at delivery time,
  not only to whichever caller triggered the refresh.
- **ui-thread-delivery**: Every observer invocation MUST occur on the UI
  thread (see Platform Notes for the exact mechanism used on Apple
  platforms).
- **immediate-start-when-idle**: A refresh call made while no run is in
  flight (`isRunning == false`) MUST set `isRunning` and start a new run
  immediately, without waiting for any other event.
- **coalesced-overlap**: A refresh call made while a run is already in
  flight MUST NOT start a second concurrent status check; it MUST instead
  set `isQueued` and return, leaving the in-flight run to trigger the
  follow-up after it finishes delivering.
- **bounded-burst-cost**: Any number of refresh calls that arrive while one
  run is in flight MUST be coalesced into at most one follow-up run,
  because `isQueued` is a single boolean rather than a counter — a burst of
  N overlapping calls MUST cost at most two status-check invocations in
  total, never N.
- **success-delivers-status-and-logs**: When the underlying status check
  succeeds, the refresh operation MUST wrap the result in the status case,
  and MUST log one info-level message naming the resulting file and
  directory counts (see Logging, and Platform Notes for the exact privacy
  annotation used on Apple platforms).
- **cancellation-yields-unavailable**: When the underlying status check is
  cancelled, the refresh operation MUST return the unavailable case rather
  than propagating the cancellation, and MUST NOT emit an error-level log
  for that case — cancellation is reported as "we do not know," never
  treated as evidence the tree is clean.
- **failure-yields-unavailable-never-empty**: When the underlying status
  check fails for any reason other than cancellation, the refresh operation
  MUST return the unavailable case, never a default or empty status value,
  so a consumer cannot mistake "git could not be asked" for "the tree is
  clean".
- **error-log-omits-git-output**: The error-level log emitted on a
  non-cancellation failure MUST be built from a sanitized description of
  the underlying git-client error when the error originates from the git
  client, or from the error's type name otherwise, and MUST NOT use the
  error's full description or otherwise include git's raw standard-error
  text.
- **injectable-client-with-shared-default**: Construction MUST accept a git
  client and MUST default it to the shared git client instance when the
  caller supplies none.
- **thread-safe-mutable-state**: `observers`, `isRunning`, and `isQueued`
  MUST be read and written only under a single lock guarding all of the
  provider's mutable state, and the provider as a whole MUST be safe to
  share across concurrent callers on the strength of that discipline, since
  it holds no other mutable state (see Platform Notes for the exact locking
  primitive used on Apple platforms).

