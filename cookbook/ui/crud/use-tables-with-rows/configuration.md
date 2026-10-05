
| Option | Type | Default | Description |
|---|---|---|---|
| `tables` | `CrudTableMeta[]` | none — required | Candidate tables to probe; identified by their `key`, in order. |
| `filter` | `Record<string, string> \| null` | none — required | Filter every probe sends; `null` disables the sweep. |
| `scopeEcosystemId` | `string` | omitted | The open view's ecosystem scope, so each probe is the list the view would send. |
| `first` | `string \| null` | `null` | Key of the open table; probed ahead of the rest and reported early. |
| `principal` | `string \| null` | the token's subject | Who is asking; part of the cache key. |
| `TABLES_WITH_ROWS_TTL_MS` | exported constant | 60 000 | How long a remembered answer counts as fresh. |
| `PROBE_CONCURRENCY` | internal constant | 8 | Maximum probes in flight. |

Callers derive `tables` and `filter` anew each render; the operation compares
content signatures (the joined table keys and the serialized filter), not
identities.

