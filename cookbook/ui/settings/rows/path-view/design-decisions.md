
- **Decision**: Override the label's default single-line, clipped
  configuration so it stays limited to one line while still honoring its
  truncation mode, rather than using the platform default that makes a
  single-line control ignore truncation mode (AppKit/UIKit source: sets
  `usesSingleLineMode = false` while keeping `maximumNumberOfLines = 1`).
  **Rationale**: source comments state directly that "`wraps = false` rather
  than `usesSingleLineMode = true`: single-line mode is what makes the cell
  ignore `lineBreakMode`, and the line break is the whole point here" — with
  `usesSingleLineMode` left `true`, `lineBreakMode = .byTruncatingMiddle`
  would be silently ignored.
  **Approved**: pending
- **Decision**: an optional caption is placed at the head of the displayed
  string (`"<caption>: <path>"`), rather than after the path or in a
  separate label.
  **Rationale**: source comments explain that the head is "which middle
  truncation never eats," so placing the caption there means "the row still
  says what it is at any width" — a caption placed at the tail or the middle
  would be the first thing lost as the view narrows.
  **Approved**: pending
- **Decision**: the label's tooltip and accessibility value are both set
  to the raw path, never the caption-prefixed display string, while
  selecting and copying the label's text yields the full display string
  (caption-prefixed, when a caption is supplied).
  **Rationale**: documented here as a source quirk rather than smoothed
  over. The design rationale frames this as one guarantee — "the drawn
  text is lossy by design, so the three ways of asking for it all answer
  with the path itself" — but the three ways do not, in fact, answer
  identically: tooltip and accessibility value strip the caption while
  copy-via-selection keeps it, because copying reads the label's full
  displayed text (AppKit/UIKit source: `NSTextField.stringValue`) rather
  than a separately-tracked "path" value. This asymmetry is unchanged for
  this recipe; per Accessibility above, the caption is not exposed through
  any accessibility label, so the accessible representation carries the
  same gap tooltip and accessibility value do.
  **Approved**: pending
- **Decision**: the label's horizontal content-compression-resistance and
  content-hugging priorities are both lowered to allow it to shrink
  (AppKit/UIKit source: both set to `.defaultLow`).
  **Rationale**: source comments state that "a path yields its width to the
  panel instead of widening the window to stay whole — the same bargain
  every truncating label here makes," so the label is deliberately let to
  shrink to the available width instead of forcing the settings panel wider.
  **Approved**: pending
- **Decision**: force a construction failure from both out-of-band
  initialization paths, leaving the path/caption initializer as the only
  usable way to construct the view (AppKit/UIKit source: `init(frame:)` and
  `init(coder:)` both trigger a fatal error).
  **Rationale**: the view has no meaningful default state — it cannot render
  anything without a path string — so both inherited initializers that
  could construct it without one are intentionally disabled rather than
  left to produce a blank row.
  **Approved**: pending
- **Decision**: The component performs no contrast check of its own: the label's secondary-text color (the theme layer enforces only a 3.0 minimum for it, below the 4.5:1 that small caption text calls for) resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
  **Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
  **Approved**: pending

