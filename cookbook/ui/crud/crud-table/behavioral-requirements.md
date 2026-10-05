
- **render-pk-then-scalar-columns**: The table MUST render the metadata's
  primary-key column(s) first, followed by the remaining scalar columns, and MUST
  omit `object` and `array` columns (they are form-only).
- **cap-columns**: The table MUST render at most six columns, taken from the
  combined PK-then-scalar list in metadata column order. Scalars survive the
  cap in the order they appear in `meta.columns`. The cap applies to the
  combined list, not to scalars alone: when there are more than six PK
  columns, only the first six (in metadata order) render and no scalar column
  appears at all — PK columns are not exempt from the cap.
- **header-columns-by-name**: Each column header MUST show the column's `name`
  exactly as served by the API.
- **label-row-actions-header**: The trailing per-row actions column header
  MUST carry `aria-label="Row actions"` and render no visible text.
- **format-null-cells**: A cell whose value is `null`/`undefined` MUST render
  as an em dash (`—`).
- **stringify-non-string-cells**: A non-string cell value MUST render as its
  JSON string form.
- **truncate-long-cells**: A rendered cell longer than 80 characters MUST be
  truncated with a trailing ellipsis (`…`).
- **show-loading-state**: While `loading` is true, the table body MUST show a
  spinner and the count MUST read "Loading…" instead of the row table.
- **show-error**: When `error` is non-null, the table MUST surface the error
  message.
- **show-empty-state**: When there are zero rows and no error (and not
  loading), the table MUST show a "No rows yet." placeholder instead of a table.
- **offer-new-action**: When `canWrite` is true, the header MUST render a New
  button that invokes `onNew` when activated.
- **offer-per-row-edit-delete**: When `canWrite` is true, every data row MUST
  render Edit and Delete actions that invoke `onEdit(row)` / `onDelete(row)`
  with that row.
  `CrudTable` MUST NOT confirm before calling `onDelete`: confirming (or not)
  is the caller's job inside its `onDelete` handler, so implementers don't
  add a second, bespoke confirmation dialog.
- **read-only-mode**: When `canWrite` is false, the header MUST NOT render New
  and MUST instead show a visible "Read-only" badge beside a text note giving
  the reason (`readOnlyNote`, defaulting to "Shared platform data — only an
  administrator can change it."); each data row MUST render a single **View**
  action that invokes `onEdit(row)` and MUST NOT render Delete. The reason MUST
  be visible text, not only a tooltip, so it reaches assistive technology and
  touch users.
- **require-write-decision**: `canWrite` MUST be a required input with no
  default, so a caller that has not decided the viewer's write access cannot
  silently receive the permissive behavior.
- **show-row-count**: When not loading, the header MUST show the row count,
  correctly singularized ("1 row" vs "N rows"), including "0 rows" while the
  empty-state placeholder is showing.
- **body-precedence**: When more than one state applies at once, the table
  body MUST resolve them in this order: the loading spinner (`loading` true,
  regardless of `error` or `rows`); otherwise the empty placeholder (`rows`
  is empty AND `error` is falsy); otherwise the row table. The error line
  renders independently above the body whenever `error` is truthy, so it MAY
  appear alongside the spinner or alongside a populated table.
- **composite-row-key**: Each rendered row's key MUST be `rowKey(meta, row)`:
  every `pkParams` value coerced to a string (`''` for `null`/`undefined`),
  percent-encoded, and joined with `/` in `pkParams` order. The row's array
  index is used only when that computed key is the empty string (for example,
  when `pkParams` is empty).
- **retain-rows-on-error**: When `error` is set but `rows` is non-empty (a
  failed background refresh after a prior successful load), the table MUST
  keep showing the existing rows; the empty placeholder MUST NOT replace them
  merely because `error` is set.

