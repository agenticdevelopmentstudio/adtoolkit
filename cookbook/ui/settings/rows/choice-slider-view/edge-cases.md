
- Null/empty input: the view model is a non-optional, typed constructor
  parameter, ruled out from being missing by the platform's type system, so
  the component provides, and needs, no nil-handling path for its one
  initializer parameter.
- Boundary values — empty choices: when the view model's choice list is
  empty, the slider's maximum becomes 0 and its tick count becomes 0; the
  longest-label-width computation reduces to 0, so the value label's fixed
  width constraint is 0. The selection-sync logic's index search never
  matches, so the slider and value label are left at their
  construction-time defaults; source performs no guard against, or
  special-casing for, an empty choice list.
- Boundary values — single choice: when the view model has exactly one
  choice, the slider's maximum becomes 0, producing a single,
  non-interactive tick at position 0; source performs no minimum-count
  check.
- Boundary values — view model's value absent from choices: source performs
  no fallback to a default index; see leaves-display-unchanged-for-
  unmatched-value. For implementors: a view model whose current value has
  drifted out of its own choice list (e.g. after a choice list is changed
  elsewhere) leaves the row showing stale slider position and text rather
  than an explicit "no selection" state.
- Concurrent access: Not applicable — the component is confined to the UI
  thread and its value type is constrained to be safely shareable across
  threads, so all construction and mutation is serialized to that thread
  (see confines-to-ui-thread).
- Error states: Not applicable — every operation in this file (the
  slider's activation and the setting-observer write) is a synchronous,
  non-throwing call; no error-producing path appears in source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Overwritten external observer: see **claims-onchange-observer**. The
  view model's external-change handler is a single property, and the
  component's initializer unconditionally assigns it, replacing whatever
  handler (if any) was previously registered on that view model. A caller
  should not rely on its own external-change handler surviving once an
  instance of this component is constructed over the same view model
  instance, since construction silently discards it.
- Value-label text lags the visible tick during a drag: the slider's action
  handler writes the resolved choice's value into the setting observer but
  never writes the value label's text itself; the label is only ever
  updated by the selection-sync logic, called from the view model's
  external-change notification. Because the setting observer delivers that
  callback via a later turn of the UI event loop — not the same call
  stack — the value label can visibly trail the slider's snapped tick
  position while dragging. This is inferred from the interaction between
  the component and the setting-observer mechanism rather than stated in a
  single line of either, it is an observed, source-traceable consequence of
  how the two are wired together, not an implementation choice this
  component itself makes.

