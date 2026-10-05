
- **Null/empty input**: `text` is a required, non-optional string value at
  construction, so a missing value is not representable. An empty string
  (`""`) renders an empty label with no guard against it in source.
- **Boundary values**: Not applicable in the numeric-input sense — the
  view's only input is a caller-supplied string; it has no length limit,
  minimum/maximum, or other caller-configurable numeric range for a
  boundary to test.
- **Concurrent access**: Not applicable — the view is confined to the main
  UI thread; construction or mutation of it from off that thread is
  rejected before it happens, so there is no concurrent-access surface to
  define behavior for.
- **Error states (dependency/network failure)**: Not applicable — the view
  performs no I/O, network call, or dependency lookup of any kind.
- **Offline/disconnected state**: Not applicable — the view performs no
  network operation of its own.
- **Very long text with no width constraint**: with the label free to
  shrink horizontally and required to keep the height its content needs,
  the label wraps and grows taller only once something constrains the
  view's own width (a container's width constraint, or a stack/grid cell) —
  `fills-view-edge-to-edge`'s edge-to-edge pins carry that width straight
  through to the label. Nothing constrains the view's own width by default
  (`compresses-and-hugs-loosely-horizontally`), so the layout system has no
  authoritative width to wrap against until the container supplies one: a
  container that does not constrain the view's width leaves the label's
  wrapped height ambiguous at that layout pass. The container MUST constrain
  the view's width for `wraps-across-lines`/`resists-vertical-compression`
  to produce a determinate multi-line height.
- **Text reassigned after construction**: callers mutate the label's text
  directly (as several call sites in the codebase do); each reassignment
  triggers the platform's standard content-size invalidation, which
  re-wraps and re-measures the label at its next layout pass — this is
  standard behavior for a text element reached through the exposed label
  property, not custom code in this view itself (see Configuration).

