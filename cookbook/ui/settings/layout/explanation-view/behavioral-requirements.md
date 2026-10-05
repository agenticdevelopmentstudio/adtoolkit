
- **renders-caller-text**: The label MUST display the exact `text` string
  it is constructed with.
- **wraps-across-lines**: The label MUST wrap by word, with multi-line mode
  enabled and no maximum line count, overriding the platform's single-line,
  clipped caption default (see Platform Notes for the source's
  mechanics).
- **compresses-and-hugs-loosely-horizontally**: The label MUST be free to
  shrink and wrap to whatever width its container gives it rather than
  resist being narrower than its full-text width or ask to hug tightly to
  that width, so it never forces its container wider than necessary (see
  Platform Notes for the source's layout-priority values).
- **resists-vertical-compression**: The label MUST never be compressed
  shorter than the height its line count requires, so a wrapped, multi-line
  label always gets the vertical space it needs.
- **fills-view-edge-to-edge**: The view MUST make the label fill its own
  top, leading, trailing, and bottom edges directly, with no additional
  inset or margin.
- **exposes-label-property**: The view MUST expose its label as a public,
  directly accessible property, so a caller can update the displayed text
  after construction.
- **styles-as-secondary-caption**: The label MUST be styled with the
  theme's `.secondaryText` color role and `.caption` text role.
- **requires-text-at-construction**: The view MUST require a `text` value
  to construct a usable instance; no construction path may produce a usable
  instance without one (see Platform Notes for how the source
  enforces this on this platform).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

