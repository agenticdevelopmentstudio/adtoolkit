
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | reliability |

**Separation of Concerns**: Fetching and board staleness sit in `useBoard`, the live transport in `useLiveSnapshot`, the snapshot staleness rule in `lib/snapshot-staleness.ts`, and the server-to-glyph mapping in `lib/overview.ts`; the hook only composes them, and text formatting stays with callers.

**Unit Test Coverage**: `use-portfolio-indicator.dom.test.tsx` covers a present board backing its verdict and a null board rendering unknown; `use-board.dom.test.tsx` covers the hook agreeing with `GlobalPanel` on a stale board. The offline, blind and stale-snapshot branches, the `"warn"` and `"down"` mappings and the `count` value are not asserted by the hook's own tests, though `snapshotFreshness` has its own test file.

**Graceful Degradation**: Any missing, failed, blind or stale input degrades the sign to `"unknown"` instead of a false green.

**Data Integrity**: The colour is the server's `board.indicator` mapped one-to-one; the hook never recomputes severity and never shows a retained verdict.

