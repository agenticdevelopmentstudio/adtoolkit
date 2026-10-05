
- **Null/empty input**: The path is a required, non-optional constructor
  parameter, so a missing value is not possible. An empty string (`""`)
  renders an empty (or, with a caption, `"<caption>: "`-only) label with no
  guard against it in source (MUST, per **retains-untruncated-path** and
  **prefixes-optional-caption**).
- **Empty, non-nil caption**: The caption is an optional value, and the
  code that builds the prefix treats an empty string as present, not
  absent. Passing an empty caption produces the displayed and stored
  string `": <path>"` — a leading colon-space with nothing before it —
  since the source guards only against a missing caption, not an empty one
  (MAY: this is observed behavior of an emptiness-blind check, not a MUST
  asserted by **prefixes-optional-caption**, which only distinguishes
  missing from supplied).
- **Boundary values**: Not applicable in the numeric-input sense — this
  component's inputs are caller-supplied strings; it has no length limit,
  minimum, or maximum for a numeric boundary to test.
- **Concurrent access**: Not applicable — the component is confined to a
  single execution context (see Platform Notes); there is no
  concurrent-access surface to define behavior for.
- **Error states (dependency/network failure)**: Not applicable — the
  component performs no I/O, network call, or dependency lookup of any
  kind; it does not validate that the path refers to anything that exists
  on disk.
- **Offline/disconnected state**: Not applicable — the component performs
  no network operation of its own.
- **Caption alone exceeds the available width**: Middle truncation
  truncates the whole rendered string (`"<caption>: <path>"`) uniformly,
  not the path portion specifically. The design rationale describes the
  caption as sitting at "the head, which middle truncation never eats" —
  true whenever there is enough width to preserve some of the head, but at
  a width narrower than the caption text itself, truncation will begin
  eliding characters from within the caption too, since no code in this
  component treats the caption boundary specially (MAY: this is observed
  fallthrough behavior at extreme widths, not a MUST that
  **truncates-middle** itself asserts — the requirement only names which
  truncation mode is set).
- **Very long path with no width constraint**: with the label permitted to
  shrink and no minimum width declared, a container that constrains the
  view's width forces the label to truncate further; if nothing constrains
  the view's width, layout falls back to whatever the container gives it,
  since neither the label nor the view expresses a preferred or maximum
  width of its own in source (MUST, per **yields-width-to-container**).

