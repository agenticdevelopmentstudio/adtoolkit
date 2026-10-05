
| Option | Type | Default | Description |
|---|---|---|---|
| `meta` | `CrudTableMeta` | — | The generated table descriptor; drives which columns render. |
| `rows` | `CrudRow[]` | — | The current rows to display (already fetched by the caller). |
| `loading` | `boolean` | — | Show the spinner + "Loading…" count. |
| `error` | `string \| null` | — | Error message to surface (null = none). |
| `canWrite` | `boolean` | — (required) | Whether the viewer may write the table; false drops New and Delete and turns Edit into View. |
| `onNew` | `() => void` | — | Invoked by the header New button. |
| `onEdit` | `(row: CrudRow) => void` | — | Invoked by a row's Edit button, or View when read-only. |
| `onDelete` | `(row: CrudRow) => void` | — | Invoked by a row's Delete button. |
| `readOnlyNote` | `string` | "Shared platform data — only an administrator can change it." | Why a read-only table is read-only, shown beside the "Read-only" badge. |

Two pure helpers are also exported for reuse/testing: `displayColumns(meta)` (the
PK-first, scalar-only, capped column list) and `cellText(row, column)` (the em
dash / JSON-stringify / 80-char-truncate cell formatter).

