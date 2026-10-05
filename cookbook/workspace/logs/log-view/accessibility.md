
- Role/trait: The component adds no custom accessibility conformance or
  role override; assistive technology sees the platform's built-in table
  accessibility hierarchy (table, then row, then cell) unmodified.
- Label requirements: Each cell's accessible value is its own displayed
  text, exposed automatically as the text field's accessibility value by
  the platform; column headers get their accessible name from the
  caller-supplied, required column title. No cell or column is left
  without a label.
- Minimum tap target: Not applicable. This is a pointer-driven control, not
  a touch surface; row height is left to the platform's system default row
  style, and no explicit width or height is set on the table, its columns,
  or its cells.
- Contrast: Not applicable at this component's level. The component fixes
  no numeric color value itself — it selects semantic theme roles
  (`.windowBackground`, `.divider`, `.selection`, and the themed label's
  default `.primaryText`) whose concrete colors, and therefore their
  contrast ratios, are resolved by the active theme palette at runtime.
  Meeting a contrast standard is that palette's responsibility, not
  something decidable from this file.
- Keyboard operability: The per-column `onClick`/`onDoubleClick` hooks are
  wired only to the table's mouse click and double-click actions, driven by
  the table view's own click/double-click action mechanism; no key-event
  handler invokes the click-dispatch method, so a keyboard-only or
  switch-control user who selects a row with the keyboard has no way to
  trigger that row's column click hook.

