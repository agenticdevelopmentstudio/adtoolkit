
- **Role/trait**: Not observable beyond the platform's defaults — no
  explicit accessibility role override appears in source, on either the
  view itself or its label. The label is the platform's standard read-only
  text control, exposed to assistive technology as static text by default.
- **Label requirements**: The component sets no accessibility label of its
  own. The visible text puts the caption at the head
  (**prefixes-optional-caption**) so a sighted user reading a captioned row
  sees `"Folder: /Users/…"`, but the accessibility value exposes only the
  raw path (**exposes-raw-path-as-accessibility-value**), so a screen
  reader announces only `"/Users/…"` with nothing filling in what that
  path is.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  the path, caption, and label are all assigned once at construction; the
  component performs no reassignment afterward and defines no state to
  announce (see States).
- **Minimum tap target**: Not applicable — the component defines no click
  handler. The label's selectability enables standard text selection
  (click-drag, double-click-word-select) across the label's full displayed
  area, which is a text-selection affordance, not a discrete tap target
  subject to a minimum size.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The label comes from the shared value-label factory, which draws in the theme's secondary-text role at the caption text style; contrast is whatever the active theme resolves for that role against the background, and the theme layer enforces only a minimum contrast of 3.0 for it.

