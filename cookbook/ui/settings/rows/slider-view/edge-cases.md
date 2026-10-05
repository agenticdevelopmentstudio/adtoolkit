
- Null/empty input: the view model is a non-optional, non-escaping-typed
  constructor parameter, so the type system rules out a missing value at
  the call site — this is a property of the parameter's type, not a
  behavior the component implements, so the component provides, and
  needs, no nil-handling path of its own for its one initializer
  parameter.
- Boundary values — inverted/zero-width range: source performs no
  minValue-less-than-maxValue validation before assigning the slider's
  minimum/maximum from the view model, either at initialization or in the
  change-notification re-sync (see slider-view-012). If the view model's
  minValue is greater than or equal to its maxValue, the component adds
  no guard of its own; the resulting slider behavior is whatever the
  platform's slider control does for an equal-or-inverted range. This is
  an absence rather than an enforced rule: nothing in source validates or
  corrects the view model's bounds.
- Concurrent access: Not applicable — the component and its
  change-notification callback are both confined to the UI thread, so
  the platform's concurrency checker serializes all access; there is no
  code path by which two threads can mutate the view simultaneously.
- Error states: Not applicable — every operation in this component (the
  slider's change notification and the write to the view model's value)
  is a synchronous, non-throwing call; no error-producing API appears in
  source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Overwritten external observer: the view model's change-notification
  callback is a single closure property, and the component's initializer
  unconditionally assigns its own handler to it. See the
  one-observer-per-view-model Design Decision for the resulting contract
  and its rationale.
- Asynchronous re-sync timing: the view model's change notification is
  delivered through an observer on a later turn of the main dispatch
  queue rather than synchronously. A commit made inside the slider's own
  change handler therefore does not trigger this component's re-sync
  back synchronously within the same call; the label/range/value re-sync
  in syncs-on-external-change happens on a later turn of the main
  dispatch queue, not inline with the triggering slider action. This is a
  SHOULD-level implementor note: the range and value re-sync SHOULD be
  expected to lag one dispatch-queue turn behind a commit made by this
  same component.

