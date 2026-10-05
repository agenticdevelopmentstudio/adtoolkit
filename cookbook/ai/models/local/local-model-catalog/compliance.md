
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | failed | Best Practices |

Notes: graceful-degradation passes because a fetch failure never surfaces as
a thrown error or a crash — it resolves to `nil` (never known) or to stale,
previously-known sizes (`stale-while-error`), and `LocalInferenceGuard` fails
open on `nil` rather than blocking a request it cannot evaluate.
fault-tolerance passes because a persistently down or non-ollama server is
retried on the slower `failureTTL` cadence instead of being hit on every
lookup. idempotent-operations is partial because concurrent calls for the
same uncached or expired `baseURL` are not deduplicated — see the
concurrent-fetch-deduplication in Behavioral
Requirements — so repeated concurrent invocations can each trigger their own
network side effect instead of converging on one. explicit-error-handling
fails because every fetch, HTTP-status, and parse failure is discarded via
`try?` with zero diagnostic signal (`fetch-error-is-fully-swallowed`) — there
is no log, no thrown error, and no way for a caller or maintainer to
distinguish the failure modes from one another.

`separation-of-concerns` passes because `LocalModelCatalog` only caches and refreshes per-server model sizes, delegating URL derivation and size parsing to the model server helper and consuming decisions to `LocalInferenceGuard`. `unit-test-coverage` is partial: `LocalModelCatalogTests.swift` covers a single fetch served from cache, a failed fetch not retried within the failure TTL, an unlisted model having no size, and a failed refetch keeping the last known-good sizes, but nothing covers concurrent lookups, a non-loopback base URL or the swallowed error.

