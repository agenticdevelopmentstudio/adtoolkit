
**Decision**: Columns are metadata-driven, not hand-authored: `displayColumns(meta)`
derives the column list (PK first, then scalars) from the table's `CrudTableMeta`
descriptor rather than per-table code.
**Rationale**: One list works for any generic-CRUD table; a new table needs no new UI.
**Approved**: pending

**Decision**: Columns are PK-first, scalar-only, and capped at six: primary keys lead
because they identify the row, object/array columns are excluded because they don't
render usefully in a cell (they're form-only), and the combined list is capped at six.
**Rationale**: Keeps the row scannable at a glance, with full detail available in the
record form.
**Approved**: pending

**Decision**: The table is placeholder-grade: no sorting, search, or pagination.
**Rationale**: The backend caps lists at 500 rows, so a plain table suffices; ship the
simplest thing that works and defer richer table behavior until a real need
(optimize-for-change).
**Approved**: pending

**Decision**: `CrudTable` owns no state or data-fetching: `rows`, `loading`, `error`,
and the action callbacks are all props.
**Rationale**: The same list can be driven by `useCrudResource` or by static demo data,
and stays trivial to test.
**Approved**: pending

**Decision**: `cellText` truncates for display only: an 80-character cap with a
trailing `…` keeps rows scannable without mutating the underlying data.
**Rationale**: Long JSON/text values don't blow out the layout, and the full value
survives for editing.
**Approved**: pending

**Decision**: The table performs no contrast check: header, cell and caption colors are the active theme's `apt-*` text tokens as resolved.
**Rationale**: The component only names tokens and never sees their values, so whether a theme's resolved pair meets 4.5:1 cannot be confirmed from the source. Closing the gap means a theme-level contrast audit of the `apt-*` text tokens against the backgrounds they sit on.
**Approved**: pending

**Decision**: `canWrite` is required and read-only is shown as visible text (a badge and a note) rather than a tooltip, with Edit relabelled View.
**Rationale**: A caller that has not decided write access must not silently get the permissive answer, because the backend refuses those writes and offering them is offering a 403; a `title` tooltip reaches neither a screen reader nor a touch device, so the reason is rendered in the page.
**Approved**: pending

