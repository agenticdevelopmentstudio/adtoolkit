
- Null/empty input: the view model and formatter are both required
  constructor parameters, ruled out from being missing by the platform's
  type system, so the component needs no nil-handling path for either.
- Boundary values — inverted/zero-width range: source performs no
  minimum-less-than-maximum validation before assigning the slider's
  minimum/maximum from the view model (see **does-not-validate-range**).
  If the view model's minimum is greater than or equal to its maximum, the
  resulting slider behavior is whatever the platform's slider control does
  for an equal-or-inverted range.
- Concurrent access: Not applicable — the component and the formatter are
  both confined to the UI thread, so all construction and mutation is
  serialized to that thread; there is no code path by which two threads
  can mutate the component simultaneously.
- Error states: Not applicable — every operation in this file (reading the
  slider's reported value, calling the formatter, and writing the setting
  observer's value) is a synchronous, non-throwing call; no error-producing
  path appears in source.
- Offline/disconnected: Not applicable — the component performs no
  networking of its own; it only reads from and writes to an in-process
  view model.
- Overwritten external observer: the view model's external-change handler
  is a single property, and the component's initializer unconditionally
  overwrites it (see **overwrites-view-model-onchange**). Constructing a
  second instance of this component (or any other observer) against the
  same view model silently drops the earlier handler; the component MUST
  NOT be assumed to coexist with another external-change observer already
  registered on the same view model instance.
- Caption can change a second time after release: the component sets the
  caption optimistically from the slider's reported value before writing
  to the setting observer. If that write causes the setting observer to
  clamp or otherwise transform the value and re-report an external change,
  the component's sync logic then overwrites the caption with the
  formatter applied to the view model's value — the view model's actual
  accepted value, not the optimistic reported value. This is inferred from
  the interaction between the live-update and sync logic rather than
  stated as a single line in source; it is a SHOULD-level note for
  implementors: the caption SHOULD be expected to update a second time,
  after slider release, without further user action, whenever the view
  model does not accept a value as-given.

