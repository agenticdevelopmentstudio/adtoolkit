
- **Role/trait**: Not explicitly set in source; the filter field and table
  use the platform's default control roles automatically.
- **Label requirements**: The filter field and table each carry an explicit
  accessibility identifier — `"breadcrumb.popover.filter"` and
  `"breadcrumb.popover.table"` respectively — for automation/testing, not for
  a screen reader, which does not speak identifiers. Neither control sets an
  explicit accessibility label: a screen reader has only the `"Filter"`
  placeholder for the filter field and no spoken name for the table. Each
  row's accessible content comes from its label's own displayed text (the
  entry's name, with matched characters bolded); source sets no separate
  accessibility-label override on the row or its text label.
- **Announce state changes**: Not implemented in source. When the filter is
  applied and reloads the table with a new, possibly much shorter, row
  count, source posts no accessibility notification informing assistive
  technology that the visible option set has changed; a screen-reader user
  hears nothing until navigating back into the table.
- **Minimum tap target**: The table's row height is 20pt, well under the
  44×44pt iOS minimum; this is expected for a pointer/keyboard-driven list
  (not a touch surface) and is not a tap-target defect on this platform. The
  44×44pt (iOS) / 48×48dp (Android) minimum applies to the touch-platform
  translations described in Platform Notes, not to this control.

