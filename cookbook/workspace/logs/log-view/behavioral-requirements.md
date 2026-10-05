
- **embeds-table-in-full-bleed-scroll-view**: The component MUST embed its
  table view inside a scroll view pinned to the component's top, leading,
  trailing, and bottom edges, filling the component's bounds.
- **vertical-only-scrolling**: The scroll view MUST show a vertical
  scroller, MUST NOT show a horizontal scroller, and MUST auto-hide its
  scrollers.
- **columns-built-once-from-provider**: The component MUST create exactly
  one table column per entry in the provider's columns, in that order, at
  initialization, using each column's `id` as the table column's identifier
  and each column's `title`, `defaultWidth`, `minWidth`, and `maxWidth` to
  configure it.
- **column-layout-fixed-after-init**: The component MUST NOT rebuild, add,
  or remove table columns after initialization, even if the provider's
  columns were to differ later; the layout captured at construction is
  permanent for the life of the instance.
- **columns-user-resizable-uniform**: Table columns MUST be resizable by the
  user, and MUST resize uniformly across all columns when the table view's
  own width changes.
- **horizontal-grid-lines-only**: The table MUST draw a horizontal rule
  between rows and MUST NOT draw vertical rules between columns.
- **row-count-matches-provider**: The number of rows the table reports MUST
  always equal the provider's line count.
- **renders-initial-lines-at-init**: The component MUST reload and display
  whatever lines the provider already holds at the moment construction
  runs, before any subsequent change notification arrives.
- **plain-cell-value-rendering**: A cell whose line value for that column is
  a plain string MUST display that string as the cell's text.
- **attributed-cell-value-rendering**: A cell whose value is a styled
  (attributed) text value MUST display that value as the cell's text,
  preserving whatever font and color attributes the caller supplied on it.
- **missing-cell-value-renders-empty**: A cell with no entry for its column
  in the line's values MUST render as an empty string.
- **cell-alignment-follows-column**: A cell's text alignment MUST equal the
  `alignment` configured on that cell's column.
- **cell-text-truncates-tail**: Cell text that overflows the column's width
  MUST truncate with a trailing ellipsis.
- **cell-tooltip-mirrors-display-text**: Every cell MUST carry a tooltip
  equal to the text currently displayed in that cell.
- **cell-request-uses-column-reuse-identifier**: Every cell view MUST be
  requested via the table view's own view-recycling mechanism, using a
  reuse identifier scoped to that cell's column id, rather than always
  constructing a new view directly (see Design Decisions).
- **cell-text-not-selectable**: Cell text MUST NOT be user-selectable; the
  table's row-level selection is the only selection surface this component
  provides.
- **selected-row-uses-theme-selection-color**: A selected row MUST be
  highlighted by filling a rounded rectangle — 4pt corner radius, inset 2pt
  horizontally and 1pt vertically from the row's bounds — with the active
  theme's `selection` role color.
- **selection-fill-reflects-current-theme**: A row's selection-fill color
  MUST reflect the active theme's `selection` role at the time the row is
  drawn, including for a row that was already on screen when the theme
  changed (see Design Decisions).
- **single-click-dispatches-column-hook**: A single click on a cell whose
  row and column both resolve to a valid line and column MUST invoke that
  column's `onClick` closure with the clicked line.
- **double-click-dispatches-column-hook**: A double click meeting the same
  validity conditions MUST invoke that column's `onDoubleClick` closure
  with the clicked line.
- **click-outside-valid-cell-is-inert**: A click whose column index is
  negative, whose row index is negative, or whose row index is at or beyond
  the provider's line count MUST NOT invoke any click hook.
- **public-dispatch-applies-same-guards**: The public click-dispatch method
  MUST apply the same column/row validity guards as the mouse-driven click
  actions, so calling it directly with a given column index, row, and kind
  behaves identically to a real click or double-click at that same index
  (see Design Decisions for why it is exposed publicly).
- **reloads-on-every-provider-change**: Every provider change notification
  — appended, replaced, or cleared — MUST result in the table reloading its
  data before any auto-scroll decision for that change is applied.
- **append-follows-tail-only-if-already-at-bottom**: On an appended change,
  the component MUST scroll to the last row after reloading if and only if
  `followTail` is `true` and, measured before the reload at the moment the
  change arrived, the distance from the bottom of the scrollable content to
  the bottom of the visible viewport is 2 points or less — or the table had
  zero rows (see `empty-table-counts-as-at-bottom`).
- **empty-table-counts-as-at-bottom**: The component's scroll-position check
  MUST treat a table with zero rows as already at the bottom, so that the
  first append to a previously empty log follows the tail whenever
  `followTail` is `true`.
- **replace-follows-tail-unconditionally**: On a replaced change, the
  component MUST scroll to the last row after reloading whenever `followTail`
  is `true`, regardless of the scroll position before the change.
- **clear-never-follows-tail**: On a cleared change, the component MUST NOT
  scroll to the end, even when `followTail` is `true`.
- **follow-tail-is-mutable-and-effective**: `followTail` MUST default to
  `true`, and setting it to `false` MUST suppress the auto-scroll-to-end
  behavior on every subsequent appended or replaced change until it is set
  back to `true`.
- **scroll-to-end-no-ops-when-empty**: The component's scroll-to-end
  operation MUST scroll the last row into view when at least one row
  exists, and MUST be a no-op when the table has zero rows.
- **reload-is-public-and-unconditional**: The component's public reload
  operation MUST refresh the table's displayed data whenever invoked,
  independent of any provider change notification.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

