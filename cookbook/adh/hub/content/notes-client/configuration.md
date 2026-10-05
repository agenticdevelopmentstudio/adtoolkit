
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `filters.q` | `string` | `undefined` | Free-text filter forwarded to `markdownApi.list`; trimmed, and omitted from the request when blank or absent. |
| `filters.category` | `string` | `undefined` | Exact category-name filter; trimmed, omitted when blank or absent. |
| `filters.tag` | `string` | `undefined` | Exact tag filter; trimmed, omitted when blank or absent. |
| `opts.workspace` | `string` | `undefined` | Owning workspace slug. When set, scopes `list`/`get`/`create`/`update`/`remove`/`categories`/`createCategory`/`tags`/`tagSet` to that workspace's principal instead of the caller's own. Not accepted by any `taxonomyApi` operation. |
| notes marker | `boolean` | `true` (fixed) | Always merged in by `create` (as `note: true`) and by `list` (as `noted: true`); not exposed as a caller-supplied option. |
| `doc` field | `boolean` | `undefined` | Caller-suppliable on `notesApi.create`'s body only; when set to `true`, double-files the new document in the docs bucket as well. Not added or read by `notesApi` itself. |
| page size | `number` | `200` (fixed, from `markdownApi`'s `PAGE_SIZE`) | Not exposed as a parameter; every `list` call requests exactly this many rows with no cursor. |

