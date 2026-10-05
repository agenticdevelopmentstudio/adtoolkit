
- **disable-on-null-filter**: When `filter` is `null`, the operation MUST NOT
  send any probe and MUST return the pending answer: `populated`, `empty` and
  `unknown` all `null`, `failed` false and `firstWithRows` `null`.
- **probe-with-limit-one-list**: For each candidate table the operation MUST
  send that table's own list request, built by `listUrl` from the table, the
  filter and `scopeEcosystemId`, with `limit=1` appended (as `&limit=1` when
  the URL already carries a query string, otherwise `?limit=1`).
- **populated-when-row-found**: A probe that answers with a non-empty array
  MUST put the table's `key` in `populated`.
- **empty-when-no-rows**: A probe that answers with an empty array, or with a
  value that is not an array, MUST put the table's `key` in `empty`.
- **forbidden-or-missing-in-no-set**: A probe refused with HTTP 403 or 404
  MUST leave the table's `key` in none of the three sets, because a table this
  viewer cannot list has nothing to offer them.
- **unknown-on-other-failure**: A probe that fails for any other reason (a 5xx,
  a 429, a dropped connection) MUST put the table's `key` in `unknown` and MUST
  make the completed answer's `failed` true; such a failure is "could not
  check", never "empty".
- **bounded-concurrency**: The operation MUST keep at most 8 probes in flight
  at once (`PROBE_CONCURRENCY`).
- **probe-first-table-first**: When `first` names a candidate, the operation
  MUST move that table to the head of the probe queue.
- **report-first-with-rows-early**: While no answer is on screen and the sweep
  is still running, the operation MUST report `firstWithRows` as the `first`
  table's key as soon as its probe finds a row, with the three sets still
  `null`, so the open table can mount before the sweep finishes. `firstWithRows`
  MUST be `null` in every finished answer, and MUST NOT be reported over a
  remembered answer.
- **cache-by-principal-filter-scope-tables**: The operation MUST remember each
  successful, complete answer under a key made of the asking principal (the
  `principal` option, falling back to the signed-in token's subject), the
  filter, `scopeEcosystemId`, and the candidate table keys joined in order. The
  remembered answers MUST be held at module scope so they survive a remount.
- **serve-fresh-answer-without-sweeping**: A remembered answer younger than
  `TABLES_WITH_ROWS_TTL_MS` (60 000 ms) MUST be returned from the first render
  and MUST NOT trigger a sweep.
- **revalidate-stale-answer**: A remembered answer older than that window MUST
  be returned at once and a sweep MUST run behind it, replacing it when the
  sweep finishes.
- **keep-answer-when-revalidation-fails**: When a revalidating sweep ends with
  any `unknown` table, the operation MUST keep the remembered answer on screen
  rather than replace it with the partial one.
- **never-remember-failed-sweep**: A sweep whose answer has `failed` true
  MUST NOT be stored, so the next mount asks again.
- **clear-on-principal-change**: The operation MUST drop every remembered
  answer when the signed-in principal changes (observed through the session
  change notification and the cross-tab storage event) and MUST NOT let a sweep
  that began before the change store its answer.
- **abort-on-leave**: When the operation's inputs change or its owner goes
  away mid-sweep, it MUST abort the probes in flight and drop the queued ones.
- **reset-for-tests**: `resetTablesWithRows()` MUST empty every remembered
  answer and invalidate any sweep already running.

Returned shape (`TablesWithRows`): `populated` and `empty` and `unknown` are
sets of table keys, or all `null` together while the answer is still coming;
`failed` is true when some probe was `unknown`; `firstWithRows` is a table key
or `null`.

