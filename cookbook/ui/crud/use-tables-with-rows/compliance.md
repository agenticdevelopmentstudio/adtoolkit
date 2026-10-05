
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`separation-of-concerns` passes because `useTablesWithRows.ts` only decides which tables hold rows: URL construction is delegated to `listUrl`, the network call to `authedJson`, session identity to `readTokenSubject` and `onSessionChange`, and presentation to the `CrudDataBrowser` rail that consumes the result. `unit-test-coverage` is `partial`: the exported `resetTablesWithRows` and `TABLES_WITH_ROWS_TTL_MS` exist for tests, and `packages/web/packages/crud/src/__tests__/CrudDataBrowser.workspace.test.tsx` pins the sweep end to end (Empty grouping, 403 and 404 handling, failed probes, remount caching, principal isolation, abort on unmount), but no test file targets the hook directly, so the concurrency bound and the nonexistent-array response are not asserted.

