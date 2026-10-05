
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | failed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | failed | Best Practices |

Notes: graceful-degradation passes because every failure path resolves to
`nil` (or, for `fetchModelInfo`, a `nil` field) rather than a thrown error or
a crash, and callers are documented to keep showing cached data.
fault-tolerance fails because, unlike the sibling `LocalModelCatalog`'s
TTL-based backoff, this file applies no cadence at all — per its own doc
comment, "every rebuild re-fetches," so a persistently down or slow server
is hit on every single caller-triggered call with no throttling; this is a
deliberate freshness-over-load-shedding tradeoff, not an oversight, but it
does not meet the reliability bar as written. idempotent-operations is
partial for the same reason as `LocalModelCatalog`: repeated successful
calls converge on the same result, but concurrent calls for the same key are
not deduplicated (`no-request-coalescing`; see
concurrent-fetch-deduplication and its Design Decision). explicit-error-handling fails because every fetch,
HTTP-status, and parse failure is discarded with zero diagnostic signal
(`fetch-error-is-fully-swallowed`).

`separation-of-concerns` passes because `LocalProviderModelStore` only fetches and caches model lists, sizes and metadata for a local provider through the shared settings store, leaving URL and size parsing to `LocalModelServer` and gating decisions to the inference guard. `unit-test-coverage` fails because no test file or test mentions `LocalProviderModelStore` under the Apple test targets, so the fetch, cache and failure paths are untested.

