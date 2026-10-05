
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `conn` | `LibsqlConnection \| undefined` | `undefined` | Passed to `createLibsqlStorage(db, conn)`; forwarded only to `createMaintenanceStore`. Omitting it degrades `runMaintenance`/`snapshotIfDue` to a logged no-op for their checkpoint/snapshot steps rather than failing construction. |
| `SESSION_TTL_MS` | `number` (module constant, `auth-store.ts`) | source-defined | Session lifetime passed to `createSession`'s default `ttlMs` parameter when a caller does not override it. |
| `UPSERT_CHUNK_PROJECTS` | `number` (module constant, `deploy-store.ts`) | `200` | Maximum deployments per upsert statement in `upsertDeployments`/`learnProjectIds`. |
| `DELETE_CHUNK_NAMES` | `number` (module constant, `config-store.ts`/`deploy-store.ts`) | `500` | Maximum names per chunked delete statement (`deleteProjectMeta`, ignored-project bulk deletes). |
| `PRUNE_CHUNK_ROWS` | `number` (module constant, `maintenance-store.ts`) | `25_000` | Maximum rows deleted per statement inside the retention prune. |
| `PRUNE_MAX_ROWS_PER_RUN` | `number` (module constant, `maintenance-store.ts`) | `100_000` | Total row-delete budget per `runMaintenance` call before the remaining backlog is deferred to the next run. |
| `opts.source` | `"webhook" \| undefined` | `undefined` | `upsertDeployments(deploys, opts)`'s discriminator between a webhook push (ordering-guarded) and a poll (treated as current truth). |
| `opts.complete` | `boolean \| undefined` | `undefined` (treated as `true`) | `errorsStore.save(items, opts)`'s discriminator for whether `items` is a whole answer (sweep runs) or a truncated page (sweep skipped). |
| `SnapshotOptions` fields | object | source-defined | Passed to `snapshotIfDue(opts)` to control snapshot cadence/destination; an omitted option set uses the store's built-in defaults. |
| `TOKEN_PREFIX` / `PREFIX_LEN` | `string` / `number` (module constants, `token-store.ts`) | `'sts_'` / source-defined | Display-only API-token prefix format; never affects the hashed value used for validation. |

