
- Null/empty input: `isEdgeEnabled` and `setEdgeEnabled` are non-optional,
  escaping closure parameters; the type system rules out an absent value. A
  closure that always returns `false` from `isEdgeEnabled` is well-defined
  here: every toggle initializes off. No string or collection input in
  this component can be empty in a way that changes its behavior. The
  component provides, and needs, no nil-handling path for either closure
  parameter.
- Boundary values: The four toggles are two-valued (on/off); there is no
  numeric boundary in the Tabs panel. The Spacing panel's numeric range
  (`0...40`) is the default of the spacing control's binding — this
  component passes no explicit range to either binding, so both the frame
  and divider controls inherit `0...40` unmodified. Clamping behavior at 0
  or 40 is the spacing control's own responsibility, not decided in this
  component.
- Concurrent access: Every construction and mutation in this component is
  confined to a single thread, so this component itself has no concurrency
  hazard. Worth noting, though: the frame-spacing and gutter-spacing
  settings are shared, app-wide settings ("App-wide, deliberately... A
  window whose panes are spaced differently from the window beside it
  reads as a bug"), so opening this sheet on two project windows at once
  and editing spacing in one updates the bound control's displayed value
  in the other, since both bind live to the same settings.
- Error states: Not applicable — every call in this component (layout,
  dismissal, `setEdgeEnabled`, the spacing bindings) is synchronous and
  non-throwing; no failure-signaling API appears anywhere in the
  component.
- Offline/disconnected: Not applicable — this component performs no
  networking; every dependency it touches (settings, the injected
  closures, the theme palette) is in-process, local state.
- Last-edge-disable refusal: Per **reverts-checkbox-to-authoritative-state**,
  this component has no independent rule of its own that keeps at least
  one edge enabled; it only reflects whatever `isEdgeEnabled` reports after
  calling `setEdgeEnabled`. The actual "refuse to disable the last edge"
  logic — and its persistence — live entirely outside this component,
  behind the injected closures.
- Out-of-range toggle index: Per **guards-invalid-checkbox-tag**, the toggle
  handler guards the index against the valid edge range before indexing;
  this component's own construction path only ever assigns indices
  `0...3`, so the guard is dead code under normal use, but it is
  source-present, testable behavior: a toggle retagged to an out-of-range
  value externally (e.g., from test code) causes the action to silently
  no-op rather than trap.

