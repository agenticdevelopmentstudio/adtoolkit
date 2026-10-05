
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | access-patterns |
| [timeout-configuration](agenticdevelopercookbook://compliance/access-patterns#timeout-configuration) | failed | access-patterns |
| [retry-with-backoff](agenticdevelopercookbook://compliance/access-patterns#retry-with-backoff) | failed | access-patterns |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | partial | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |

Separation of concerns passes: each adapter knows only its endpoints and the
DTO contract, and neither touches storage or UI. Unit-test coverage fails
because no test exercises `liveSource` or `tursoSource`. Error handling is
partial: non-`ok` statuses become explicit `Error`s carrying the status, but the
body's error detail is discarded, and `tursoSource` reports only the `/errors`
status when both fail. Timeouts are absent and retries are delegated to
`useTelemetry` (one retry, React Query's default delay), so the sources
themselves fail both checks. Graceful degradation is partial: the sources reject
rather than return partial data, which lets the hook fall back to its cached
snapshot, but they offer no fallback themselves. Data integrity is partial
because response bodies are cast, not validated, so a malformed 2xx body passes
through unchecked.

