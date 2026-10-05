
- **Null/empty input**: the view model is a non-optional, typed
  constructor parameter; the type system rules out a missing value. An
  empty title on the view model produces a label with an empty string
  and no crash. The component provides, and needs, no nil-handling path
  for its one initializer parameter.
- **Boundary values**: At the stepper's value equal to its minimum or
  maximum, the stepper's own bounds enforcement (given wraparound
  disabled) stops further movement in that direction rather than
  wrapping to the opposite bound; because integer bounds and a fixed
  increment of 1 always land exactly on both ends, every value in the
  range is reachable.
- **Contradictory bounds (minValue > maxValue)**: source forwards the
  view model's minValue/maxValue to the stepper's minimum/maximum with
  no validation or reordering — see the Design Decision on
  inverted-bounds handling.
- **Concurrent access**: Not applicable — the component is confined to
  the UI thread, so all construction and mutation is serialized by the
  platform's concurrency checker (see confines-to-ui-thread).
- **Error states**: Not applicable — every operation in this component
  (the stepper's change notification, the label/value-label text
  updates, and the write to the view model's value) is a synchronous,
  non-throwing call; no error-producing API appears in source.
- **Offline/disconnected state**: Not applicable — the component
  performs no networking of its own; it only reads from and writes to
  an in-process view model.
- **Overwritten external observer**: the view model's change-
  notification callback is a single closure property; per
  replaces-view-model-onchange, the component's initializer
  unconditionally overwrites it, replacing whatever handler (if any) was
  previously registered — the same closure-overwrite behavior the
  checkbox row and the integer field row document. The component MUST
  NOT be assumed to coexist with another change-notification observer
  already registered on the same view model instance.

