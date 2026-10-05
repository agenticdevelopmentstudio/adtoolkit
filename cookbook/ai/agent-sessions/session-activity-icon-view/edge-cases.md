
- **Null/empty input**: Not applicable — `activity` (a required, non-optional
  3-case activity state) and `isSummarizing` (a required boolean) are both
  required inputs; there is no null or empty variant for either to guard
  against.
- **Boundary values**: Not applicable — the component's only inputs are the
  fixed 3-case activity state and a boolean; there is no numeric or
  range-bound input with a minimum/maximum boundary to test. The layout
  constant (13pt) and animation durations (0.7s, 1.1s) are fixed values, not
  caller-configurable ranges.
- **Concurrent access**: The component defines no lock, queue, or explicit
  thread-isolation of its own. All of its mutable state (`activity`,
  `isSummarizing`, tint, active theme) is touched only at construction, on
  state update, and through the platform's own main-thread-invoked lifecycle
  callbacks; nothing in the source itself prevents the state-update
  operation from being called off the main thread, so the safety of
  concurrent access rests on the platform's general UI-mutation convention
  rather than a guarantee this component enforces.
- **Error states (dependency/network/filesystem failure)**: Not applicable
  — the component performs no I/O, network call, or dependency lookup of any
  kind; its only external input is the `activity`/`isSummarizing` values a
  caller passes in directly.
- **Offline/disconnected state**: Not applicable — the component performs
  no network operation of its own.
- **Missing/unresolvable glyph**: If the platform's icon lookup cannot
  resolve the selected glyph's image, the component clears its rendered
  content and returns — no fallback image, placeholder, or crash (MUST, per
  **unresolvable-symbol-fallback**). All four glyphs the component actually
  selects are real, always-resolvable system icons, so this path is unreached
  in normal operation but is still defined, source-observed behavior.
- **State update called with a real change while not visible on screen**:
  The stop side of the animation swap still runs, but starting the new
  animation is gated on the component being visible on screen, so the new
  animation does not begin until the component is later inserted into the
  display hierarchy (which re-renders and starts it then) (MUST, per
  **animation-restart-on-change** and **window-attach-animation-reinstall**).
- **Rapid repeated state-update calls with unchanged values**: Each call is
  a no-op past the initial equality guard — no redraw, no accessibility
  re-description, no animation churn — which is what keeps a
  continuously-polled "working" spin visually smooth rather than restarting
  from zero on every poll (MUST, per **redundant-update-guard**).

