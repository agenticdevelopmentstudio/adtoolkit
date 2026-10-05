
The sweep is exercised through `CrudDataBrowser` in
`packages/web/packages/crud/src/__tests__/CrudDataBrowser.workspace.test.tsx`;
each vector names the test that pins it where one exists.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| use-tables-with-rows-001 | disable-on-null-filter | `filter = null`, any tables | No request is sent; the result is the pending answer (three sets `null`, `failed` false, `firstWithRows` `null`) |
| use-tables-with-rows-002 | probe-with-limit-one-list, populated-when-row-found, empty-when-no-rows | Two tables; the first probe answers one row, the second answers `[]` | Both probes are the table's list URL with `limit=1`; `populated` holds the first key, `empty` the second, `unknown` is empty and `failed` is false (`sets tables with no rows, and a schema left with none, apart in an Empty group`) |
| use-tables-with-rows-003 | forbidden-or-missing-in-no-set | A table's probe answers 403, another's answers 404 | Neither key is in any of the three sets; `failed` is false (`counts a 403 or a 404 as no rows`) |
| use-tables-with-rows-004 | unknown-on-other-failure | A table's probe answers 500 | The key is in `unknown` and `failed` is true (`lists every table it couldn’t check, marked so, not "No data yet."`) |
| use-tables-with-rows-005 | bounded-concurrency | 20 candidate tables whose probes stay pending | No more than 8 probes are outstanding at any moment |
| use-tables-with-rows-006 | probe-first-table-first, report-first-with-rows-early | `first` names the fifth table; its probe answers a row while the rest are pending | The fifth table is probed first; `firstWithRows` is its key while the three sets are still `null` (`opens the open table on its own probe, without waiting on the rest`) |
| use-tables-with-rows-007 | serve-fresh-answer-without-sweeping | A finished sweep, then a remount with the same principal, filter, scope and tables within 60 s | The remembered answer is returned on the first render and no probe is sent (`serves a fresh remembered answer on a remount without probing again`) |
| use-tables-with-rows-008 | revalidate-stale-answer | Same remount after more than 60 s | The remembered answer is returned at once and probes run behind it (`shows a stale remembered answer on a remount at once, then asks again quietly`) |
| use-tables-with-rows-009 | keep-answer-when-revalidation-fails, never-remember-failed-sweep | A stale remembered answer; the revalidating sweep has a 500 | The remembered answer stays on screen; after a failed first sweep, a later mount probes again (`keeps the remembered answer when asking again fails`, `asks again after a sweep that failed`) |
| use-tables-with-rows-010 | cache-by-principal-filter-scope-tables, clear-on-principal-change | One user's remembered answer; a different principal mounts, or the signed-in subject changes | The other user is never served it; after the change every remembered answer is gone (`never serves one user’s remembered answer to another`, `forgets every answer when someone else signs in`) |
| use-tables-with-rows-011 | abort-on-leave | Unmount mid-sweep with probes in flight and others queued | In-flight probes are aborted and none of the queued probes is sent (`aborts the probes in flight on unmount, and sends none of the queued ones`) |

