
- **Null/empty input**: title is a required, non-optional string
  parameter, so the type system rules out a missing value. An empty
  string renders an empty title label, with no guard against it in
  source — a consequence of **sets-title-text-from-caller**. caption is
  optional and defaults to absent; an explicit empty string is still
  present/non-absent, so it still constructs a caption view whose label
  renders empty, since **creates-caption-view-when-caption-given** does
  not special-case an empty but present string.
- **Boundary values**: Not applicable in the numeric sense — the
  component's only inputs are the two caller-supplied strings; it has no
  caller-configurable numeric range. A very long title is clipped, not
  wrapped, because the component never reconfigures the title label's
  wrap settings; a very long caption wraps across more lines instead,
  because its width is matched to the stack (**matches-caption-width-to-stack**)
  while the caption view itself is configured to wrap.
- **Concurrent access**: Not applicable — the component is confined to
  the UI thread; construction or mutation of the component, its title
  label, or its caption view from off that thread is rejected.
- **Error states (dependency/network failure)**: Not applicable — the
  source performs no I/O, network call, or dependency lookup of any kind.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking of its own.
- **Caption text reassigned after construction**: The component exposes
  its caption-label accessor, so a caller with a present caption can
  reassign that label's displayed text directly, reached through the
  forwarding accessor rather than any update/set-text method the
  component itself defines. This mirrors the pattern the Explanation View
  recipe's own `updates-text-via-label-property` requirement documents
  for that view (see
  `adtoolkit://cookbook/ui/settings/layout/explanation-view#exposes-label-property`;
  also Design Decisions).
- **Constructed with no caption and later needing one**: The caption view
  is constructed once at construction time and never reassigned; the
  source provides no way to add a caption to a component instance that
  was built without one — a caller that needs a caption supplies it at
  construction. This is a source-traceable consequence of
  **omits-caption-view-when-caption-nil**: no method exists to set the
  caption view after construction returns.

