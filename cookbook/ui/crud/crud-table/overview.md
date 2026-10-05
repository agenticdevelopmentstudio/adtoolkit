
`CrudTable` in `@agentic-toolkit/crud` is a **metadata-driven** row list for one
generic-CRUD table. Given a `CrudTableMeta` (generated from the backend OpenAPI
spec) plus the current `rows`, it renders a plain table whose columns are chosen
from the metadata: the primary-key column(s) first, then the remaining **scalar**
columns (object/array columns are form-only), capped at six. Each row carries
per-row **Edit** and **Delete** ghost buttons, and a header **New** action sits
above the table beside a row count. When the viewer may not write the table
(`canWrite` is false) New and Delete are dropped, Edit becomes **View**, and a
visible "Read-only" badge with an explanatory note replaces New.

It is a **placeholder-grade** list — no sorting, search, or pagination (the
backend caps lists at 500 rows) — used by the `/all-data` generic table browser
and any admin surface that needs a quick, uniform view of one table. It owns no
data-fetching or state: the caller supplies `rows`, `loading`, and `error` (from
`useCrudResource`) and handles the `onNew` / `onEdit` / `onDelete` intents.

