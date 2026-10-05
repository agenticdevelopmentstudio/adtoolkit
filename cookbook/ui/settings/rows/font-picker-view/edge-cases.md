
- **Null/empty input**: The view model is a non-optional constructor
  parameter; the type system rules out nil. The component provides, and
  needs, no nil-handling path for its one initializer parameter.
- **Boundary values**: Neither this component nor the view model clamps
  or validates the stored point size (a plain persisted numeric value)
  before resolving the actual font. An arbitrary stored size (including
  zero, negative, or extremely large values) is passed straight through
  with no validation in either place. If that combination cannot resolve
  to a real font, the view model falls back to a fixed system monospace
  font - the same fallback path used for an uninstalled font name (see
  next item). That fallback is the view model's responsibility, not this
  component's - a resync reads the view model's font unconditionally and
  gives it straight to the button. See
  **delegates-font-resolution-fallback**.
- **Concurrent access**: Not applicable - the component is confined to the
  UI thread, so all access is serialized to that thread; there is no code
  path by which two threads can mutate the view simultaneously.
- **Error states**: Not applicable - every operation in this file (the
  button's activation, committing the picked font, and the resync reads)
  is a synchronous, non-throwing call; no error-producing path appears in
  source.
- **Offline/disconnected**: Not applicable - the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- **Overwritten external observer**: The view model's external-change
  handler is a single property. The component's initializer
  unconditionally assigns its own resync-calling handler, replacing
  whatever handler (if any) was previously registered on that view model
  instance (see **overwrites-existing-view-model-observer**).
- **Repeated sync after a single font pick**: Picking a font that changes
  both the stored name and size fires a resync more than once for one user
  action. The button's change-callback handler commits the font to the
  view model, then resynchronizes synchronously. The view model writes its
  underlying stored name and size only when each differs from its current
  value; each write that actually occurs independently triggers the view
  model's own change notification on the next turn of the platform's main
  work queue, which invokes this component's resync handler again. So
  picking a font that changes both name and size results in one
  synchronous resync plus up to two further asynchronous resyncs; picking
  the exact font already stored (both guards fail) results in exactly one
  resync. The component performs no debouncing or deduplication of these
  repeated calls; because a resync always re-reads current state rather
  than accumulating it, the redundant calls are observably idempotent (see
  **resyncs-synchronously-after-a-pick**).
- **Reassigning an unchanged label**: A resync unconditionally reassigns
  the label's displayed text to the view model's title on every call, even
  though the view model's title cannot change after construction. The
  component performs no early-exit/equality check before this
  reassignment (see **redraws-label-text-on-every-sync**).
- **Toggling the enabled state to its current value**: The enabled-state
  handler reassigns the button's enabled state and the label's opacity on
  every assignment, including a reassignment to the value already held;
  the platform's property-observation mechanism carries no built-in
  equality guard, and source adds none (see **dims-and-disables-the-row**).

