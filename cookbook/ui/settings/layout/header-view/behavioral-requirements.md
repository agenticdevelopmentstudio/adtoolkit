
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **exposes-title-label**: The component MUST expose its label as a public,
  immutable property, so a caller can read or observe its title.
- **creates-title-label-with-secondary-caption-style**: The component MUST
  style its label with the theme's `.secondaryText` color role and
  `.caption` text role.
- **sets-title-label-initial-text**: The component MUST initialize its
  label's displayed text to the caller-supplied `title` string,
  unmodified.
- **pins-title-label-to-all-four-edges**: The component MUST make its label
  fill its own bounds exactly, pinned to its top, leading, trailing, and
  bottom edges with no additional inset, so the component's bounds and the
  label's bounds coincide (see Platform Notes for the mechanics the source
  uses).
- **requires-title-at-construction**: The component MUST require a `title`
  value to construct a usable instance; no construction path may produce a
  usable instance without one (see Platform Notes for how the
  source enforces this on this platform).

