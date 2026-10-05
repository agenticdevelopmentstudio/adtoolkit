
- **thread-confined-access**: The bridge's every operation MUST run
  confined to the same single, serialized execution context the script
  engine uses to invoke the callbacks it builds.
- **stateless-enum**: The bridge MUST be a stateless collection of
  operations with no stored state; every operation MUST derive its answer
  solely from its arguments and from whichever script call is currently
  active.
- **member-builds-a-block-closure**: Installing a member MUST return a
  callback closure usable directly as the implementation of an adaptor's
  member-defining call.
- **member-block-asserts-isolation-internally**: The callback that
  installing a member returns MUST assert, at the start of its body, that
  it is running on the bridge's confined execution context, since the
  callback's own declared type cannot itself carry that confinement, and
  the script engine calls it from whatever thread made the call.
- **member-captures-owner-weakly**: Installing a member MUST capture the
  owning adaptor instance weakly inside the callback, so the callback's
  continued existence in the extension's script does not keep a
  deallocated adaptor instance alive.
- **member-answers-teardown-response-when-owner-gone**: The callback MUST
  answer the configured teardown response instead of invoking its body,
  when the owning adaptor instance has already been deallocated by the
  time the callback runs.
- **teardown-response-two-cases**: The teardown-response value MUST provide
  exactly two cases, "rejected promise" and "raised exception," and MUST be
  safe to share across concurrent contexts.
- **torn-down-dispatches-by-response**: Answering a teardown response MUST
  answer with a rejected promise for the "rejected promise" case, and MUST
  raise a script exception for the "raised exception" case; it MUST answer
  nothing when there is no active script context.
- **current-arguments-never-nil**: Reading the current call's arguments
  MUST answer an empty list, never nothing, when the active call's
  arguments cannot be read as a list of values or when there is no call in
  flight.
- **array-length-requires-true-array**: Reading an array-like value's
  length MUST require the value to be a genuine array before reading its
  length property, so an object literal carrying a numeric length property
  is never treated as a decodable array.
- **array-length-uses-exact-int32-conversion**: Reading an array-like
  value's length MUST use an exact, bounds-checked conversion of the
  numeric length value, and MUST NOT use a truncating conversion, so a
  length outside the representable range (such as the length of an array
  built with an index count of 4294967295) answers nothing instead of
  wrapping to a small, plausible-looking count.
- **array-length-bounds-decoding**: Reading an array-like value's length
  MUST log an error and answer nothing for any array whose length exceeds
  the maximum decodable array length (100,000).
- **raise-sets-context-exception**: Raising a script exception MUST set
  the active context's exception to a newly built error value and MUST
  always answer nothing.
- **raise-logs-when-error-construction-fails**: Raising a script exception
  MUST log an error when building a fresh error value from the message
  fails, and MUST still leave the call to answer nothing in that case, so
  the caller sees no throw beyond the log line.
- **resolved-promise-nil-becomes-undefined**: Building a resolved promise
  MUST resolve a missing value with the script engine's "undefined," and
  MUST NOT resolve it with "null."
- **resolved-promise-passes-non-nil-through**: Building a resolved promise
  MUST resolve any present value with that value unchanged.
- **rejected-promise-preserves-extension-supplied-reason**: Building a
  rejected promise from a caller-supplied reason MUST build it from the
  given value unchanged, preserving that reason's own error subclass,
  stack, and any custom properties.
- **rejected-promise-from-message-builds-a-fresh-error**: Building a
  rejected promise from a message MUST build a fresh error value from that
  message, delegating to the reason-based builder, and MUST answer nothing
  without producing any promise when that construction fails.
- **settled-promise-nil-resolves-undefined**: Building a settled promise
  MUST resolve with "undefined," via the resolved-promise builder, when the
  input value is missing.
- **settled-promise-passes-a-thenable-through-unchanged**: Building a
  settled promise MUST return the same value unchanged, not a wrapping
  promise, when the input value is a thenable, preserving its identity and
  whatever it later settles with.
- **settled-promise-resolves-a-non-thenable**: Building a settled promise
  MUST resolve with the input value itself, via the resolved-promise
  builder, when the input value is not a thenable.
- **settled-promise-rejects-on-a-throwing-then-getter**: Building a
  settled promise MUST reject with the error a throwing `then` property
  getter raised, rather than resolving with the raw object.
- **settled-promise-rejects-when-dispatch-is-unavailable**: Building a
  settled promise MUST reject with the shared dispatch-unavailable message
  when the context cannot answer whether the input value is thenable,
  rather than guessing "not a thenable" and resolving with the raw object.
- **call-outcome-three-cases**: The call-outcome value MUST provide
  exactly three cases: "returned" (carrying an optional value), "threw"
  (carrying a value), and "unavailable."
- **call-outcome-and-settlement-stay-context-confined**: The call-outcome
  value, the settlement value, and the then-lookup result MUST NOT be
  declared safe to share across concurrent contexts (unlike the
  teardown-response value), since each carries a value confined to the
  bridge's own execution context; every producer and consumer stays
  confined to that same context.
- **call-outcome-returned-nil-is-not-void-success**: A caller MUST treat
  "returned" carrying no value as "no value was read back" — distinct from
  both success and failure — never as "the callback returned nothing,"
  which is "returned" holding a value for "undefined."
- **call-refuses-when-trampoline-cannot-be-installed**: Calling back into
  an extension's callback MUST answer "unavailable," and MUST NOT invoke
  the callback directly, when the callback has no active context or the
  dispatch trampoline's call helper cannot be installed in that context.
- **call-normalizes-nullish-this-arg**: Calling back into an extension's
  callback MUST bind the call's receiver as the script engine's
  "undefined" when the caller passes nothing.
- **call-catches-the-callbacks-own-throw**: Calling back into an
  extension's callback MUST answer "threw" carrying the reason — never let
  the exception reach the host's own exception handling — when a call
  through this bridge's own trampoline reports failure.
- **outcome-refuses-a-malformed-trampoline-record**: Reading a dispatch
  outcome MUST log an error and answer "unavailable" when the settled
  value is not an object, or its success flag is missing or not a boolean.
- **outcome-requires-error-property-on-failure**: Reading a dispatch
  outcome MUST answer "unavailable," not "threw," when the success flag is
  false but the record's error property is absent.
- **can-dispatch-checks-both-helpers-present**: Checking whether dispatch
  is possible MUST answer true only when both the call helper and the
  then-lookup helper are present and neither "undefined" nor "null" on the
  trampoline; it MUST NOT invoke either to verify callability.
- **can-dispatch-installs-the-trampoline-as-a-side-effect**: Checking
  whether dispatch is possible MUST evaluate and cache the trampoline in
  the active context if it has not already been installed, so a later
  dispatch in the same context finds it cached.
- **dispatch-unavailable-message-is-shared-verbatim**: The
  dispatch-unavailable message MUST produce the identical message text
  used by every refusal on the dispatch-unavailable path, naming the
  context by its resolved name.
- **observe-rejection-leaves-value-unchanged**: Observing a thenable's
  rejection MUST attach the handler to a promise derived from the value's
  `then` member, and MUST leave the input value itself as what the caller
  keeps and hands back to the extension; the derived promise MUST be
  discarded.
- **observe-rejection-only-attaches-to-a-thenable**: Observing a thenable's
  rejection MUST answer false, and attach nothing, when the input value is
  not a thenable, when reading its `then` member throws, or when calling
  `then` throws.
- **observe-rejection-reads-the-rejection-reason-off-the-actual-arguments**:
  The rejection handler observing a thenable's rejection builds MUST read
  its argument from the current call's arguments, not from a declared
  formal parameter.
- **settlement-non-thenable-is-fulfilled-with-itself**: Reading a value's
  settlement MUST answer "fulfilled" with that value immediately when the
  value is not a thenable.
- **settlement-resumes-the-continuation-exactly-once**: Reading a value's
  settlement MUST resume its underlying suspended call at most once even
  when the extension's own `then` implementation calls both handlers,
  calls one handler more than once, or throws after a handler already
  fired; the first settlement by call order MUST win.
- **settlement-does-not-time-out**: Reading a value's settlement MUST
  impose no timeout on a thenable that never settles, matching upstream VS
  Code's own behavior for a promise given to an API such as
  `showQuickPick` that never resolves.
- **settlement-handlers-capture-no-live-value**: Neither the fulfillment
  nor the rejection handler passed to the extension's `then` MUST NOT capture
  a script value directly; each MUST read its argument from the current
  call's arguments or mint a fresh "undefined" from the active context at
  call time.
- **settlement-missing-argument-fulfills-as-undefined**: A handler invoked
  with no argument MUST settle the read as a value holding "undefined,"
  not as "unavailable" and not as an absent result.
- **settlement-unavailable-when-context-cannot-mint-undefined**: Reading a
  value's settlement MUST answer "unavailable" before attaching any
  handler, when the context can no longer produce a value for "undefined."
- **settlement-getter-throw-becomes-rejected**: Reading a value's
  settlement MUST answer "rejected" with the thrown value, and MUST NOT
  let the exception reach the context's own exception handling, when
  reading the value's `then` member throws.
- **then-function-distinguishes-four-outcomes**: Looking up a value's
  `then` function MUST distinguish "not thenable" (no callable `then`),
  "thenable" (carrying a value), "threw" (carrying a value, when reading
  `then` raised), and "unavailable" (the lookup itself could not be
  performed); callers MUST NOT conflate "unavailable" with "not thenable."
- **helper-source-is-evaluated-at-most-once-per-context**: Installing the
  shared trampoline helper MUST evaluate its source at most once per
  context, caching the result under a non-enumerable, non-writable,
  non-configurable global name, and reading the cached value back on
  every later call.
- **trampoline-object-is-frozen-before-caching**: The trampoline object
  MUST be frozen before it is cached, so a member-level reassignment is
  refused in addition to a whole-binding reassignment.
- **sharedHelper-adopts-whatever-object-it-finds**: Installing the shared
  trampoline helper MUST adopt whatever object already exists under its
  cached global name rather than verifying its provenance, for a context
  reached before anything has called the trampoline installer.
- **install-trampoline-is-not-fatal-to-activation**: Installing the
  trampoline MUST answer nothing, through the shared-helper installer's own
  logging, rather than failing the caller, when the eager install fails,
  leaving the lazy path through the call and dispatch-check operations as
  the fallback.
- **helper-function-rejects-nullish-members**: Reading a named helper
  function from the trampoline MUST answer nothing when the named member
  on the trampoline is "undefined" or "null," in addition to when the
  trampoline itself could not be installed.
- **context-name-fallback**: Resolving a context's name MUST answer
  `"<unnamed>"` when the context has no name of its own.
- **disposable-idempotent-by-construction**: Building a disposable MUST
  return an object whose dispose operation calls the supplied cleanup
  action on its first invocation and MUST do nothing on every later
  invocation, tracked by a disposed flag captured in the returned
  callback's own closure.
- **sub-namespace-factory-evaluated-once-per-context**: Installing the
  sub-namespace factory MUST evaluate its source at most once per context,
  matching the shared trampoline helper's caching pattern under its own
  fixed global name.
- **sub-namespace-unimplemented-member-throws-named-error**: A stub built
  by the sub-namespace builder MUST throw a not-implemented error — an
  error named "NotImplementedError" with a member-path property equal to
  the sub-namespace's path joined with the key — from its property-read
  trap, for any key that is neither an implemented member nor one of the
  shim's probe keys.
- **sub-namespace-probe-keys-answer-quietly**: The property-read trap MUST
  answer a quiet feature-detection value, never throw, for every key in
  the probe-key list (the standard object-prototype own names plus `then`,
  `toJSON`, `__esModule`, `default`, `inspect`, `prototype`, `nodeType`,
  and `$$typeof`), even when that key is not implemented.
- **sub-namespace-is-read-only**: The property-write and property-delete
  traps MUST both throw a type error naming the sub-namespace's path and
  the key, and MUST NOT allow any assignment or deletion to succeed
  silently.
- **sub-namespace-table-has-no-inherited-prototype**: The object holding
  the sub-namespace's implemented members MUST be built with no inherited
  prototype, so standard object-prototype member names are never already
  present in it before any real member is added.
- **sub-namespace-records-misses-only-when-a-recorder-is-supplied**: The
  property-read trap's throwing branch MUST call the miss recorder with
  the full member path when a miss recorder is supplied, and MUST NOT call
  it — while still throwing the same not-implemented error — when none is
  supplied.
- **sub-namespace-records-probes-only-from-has-and-descriptor**: The probe
  recorder MUST be invoked only from the property-existence and
  descriptor-lookup traps' negative branches, and MUST NOT be invoked from
  a property read of a probe-key name or from a symbol key.
- **sub-namespace-swallows-a-throwing-recorder**: A throw from the miss
  recorder or the probe recorder itself MUST be caught and discarded, and
  MUST NOT replace the not-implemented error the extension is entitled to
  see, or turn a boolean-returning trap into an uncaught throw.
- **sub-namespace-returns-nil-when-factory-or-table-unavailable**:
  Building a sub-namespace MUST answer nothing when the factory could not
  be installed in the active context, or when the context cannot produce
  an object with no inherited prototype to hold the sub-namespace's
  members.
- **logger-conformance**: The bridge MUST participate in the host's
  logging convention, exposing a logger as the destination for every
  failure that has no extension-facing channel.
- **confined-value-box-never-crosses-isolation**: The confined-value box
  MUST only ever carry a value already confined to one execution context
  across a signature that requires concurrency safety, never to move a
  value between execution contexts.
- **bridge-value-box-is-a-named-specialization**: The bridge-value box
  MUST be a named specialization of the confined-value box, not a second,
  independent box declaration.
- **promise-settlement-box-carries-a-fixed-pair**: The promise-settlement
  box MUST hold exactly one promise's resolve and reject values, read back
  only by name, and MUST NOT double as a general-purpose value box.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

