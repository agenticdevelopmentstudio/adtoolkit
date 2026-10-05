
- **renders-path-non-wrapping-single-line**: The label MUST render its text
  as non-wrapping and limited to one line, honoring its truncation mode
  during layout instead of that mode being ignored, the way some
  single-line text rendering modes ignore it.
- **truncates-middle**: The label MUST truncate its displayed text in the
  middle when the text does not fit the available width.
- **retains-untruncated-path**: The view MUST retain the full, untruncated
  path string in its public `path` property, independent of the view's
  width or the label's truncated display.
- **prefixes-optional-caption**: The view MUST prefix the displayed text
  with `"<caption>: "` when a caption is supplied at construction.
- **omits-caption-when-absent**: The view MUST display only the path, with
  no prefix, when no caption is supplied (the default).
- **exposes-raw-path-as-tooltip**: The label's tooltip MUST be set to the
  raw path string, never the caption-prefixed string, even when a caption
  is supplied.
- **exposes-raw-path-as-accessibility-value**: The label's accessibility
  value MUST be set to the raw path string, never the caption-prefixed
  string, even when a caption is supplied.
- **supports-text-selection**: The label MUST be selectable, so a caller
  can select and copy the label's full backing string.
- **yields-width-to-container**: The label MUST be permitted to shrink
  below its natural width rather than forcing its container wider.
- **fills-container-bounds**: The view MUST pin the label's top, leading,
  trailing, and bottom edges directly to its own corresponding edges, with
  no additional inset or margin.
- **exposes-label-property**: The view MUST expose its label as a public,
  directly accessible property.
- **exposes-path-property**: The view MUST expose the path it was
  constructed with as a public, directly accessible, immutable property.
- **styles-as-secondary-caption**: The label MUST be styled with the
  theme's `.secondaryText` color role and `.caption` text role.
- **conforms-to-settings-view-protocol**: The view MUST conform to the
  settings row interface.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

