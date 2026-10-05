
- Null/empty input: the view model is a non-optional, typed constructor
  parameter, ruled out from being missing by the platform's type system, so
  the component needs no nil-handling path for its one initializer
  parameter. The view model's title as an empty string produces a label
  with an empty string and no crash.
- Boundary values: Not applicable — the bound value is boolean, a two-value
  type with no minimum/maximum or intermediate range to bound.
- Concurrent access: Not applicable — the component is confined to the UI
  thread, so all construction and mutation is serialized to that thread
  (see **confines-to-ui-thread**).
- Error states: Not applicable — every operation in this file (the
  toggle's activation and the setting-observer write) is a synchronous,
  non-throwing call; no error-producing path appears in source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Overwritten external observer: the view model's external-change handler
  is a single property. The component's initializer unconditionally
  assigns its own handler, replacing whatever handler (if any) was
  previously registered on that view model (see
  **claims-sole-onchange-observer**). Constructing a second instance of
  this component (or any other observer) against the same view model
  silently drops the earlier handler.

