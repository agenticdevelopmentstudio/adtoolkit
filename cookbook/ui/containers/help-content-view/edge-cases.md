
- **Null/empty input**: Setting help content to no content, and setting it
  to content with an empty topics list, both MUST produce the identical
  single-group empty state (see **empty-state**;
  help-content-view-004, help-content-view-005) — the two are
  treated as the same case.
- **Boundary values**: Not applicable in the numeric-input sense — the
  source enforces no minimum or maximum topic count. Content with one
  topic and content with a hundred topics both render every topic
  (**topic-groups**); the scroll view grows to fit any
  count rather than clipping it.
- **Concurrent access**: Not applicable — this component is confined to a
  single thread of execution for its entire lifetime, so there is no
  concurrent-access surface to define behavior for. See Platform Notes for how that confinement is enforced.
- **Error states (dependency/network failure)**: Not applicable — the
  source performs no I/O, network call, or dependency lookup of any kind.
- **Offline/disconnected state**: Not applicable — this component performs
  no network operation of its own.
- **Rapid, repeated content-setting calls**: Each call independently tears
  down and rebuilds the panel (**wholesale-replacement**); the source
  contains no debouncing, coalescing, or in-flight guard, so N calls in
  quick succession perform N full rebuilds.
- **Content-setting called with an unchanged, equal content value**: The
  source performs no equality check against the previously stored content
  before rebuilding — even though the content type supports equality
  comparison — so passing back the same value still discards and rebuilds
  every group and explanation view (**wholesale-replacement**).
- **Very long single topic body**: An Explanation View wraps and grows
  vertically with no line limit (per its own recipe), so a very long body
  makes its group taller and pushes later groups further down the
  scrollable content; nothing in this component's own source truncates or
  limits it.
- **Constructing via a frame-only initializer**: Not possible. This
  component declares its own single way to construct it, with no supported
  frame-only construction path, and unlike some sibling row views it needs
  no fatal-error guard to block that path — its constructor is the only way
  to build one, and it always installs the title label, scroll view, and
  theme observer. See Platform Notes for why the
  language's own initializer-inheritance rules make this true without an
  explicit guard.

