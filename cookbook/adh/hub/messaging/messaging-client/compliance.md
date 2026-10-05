
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | failed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | failed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |

`separation-of-concerns` is `partial`: `MessagingDataSource` cleanly isolates every network call
behind a protocol `MessagingTopic` depends on but never implements, but `MessagingModels.swift`'s
`MessagingTemplate.placeholders` reaches back into `MessagingTopic.placeholders(in:)` — a model
type calling into its own controller type, the inverse of the usual dependency direction, even
though the source's own comment shows this was a deliberate choice to share one regex rather than
duplicate it. `unit-test-coverage` passes: `MessagingTopicTests.swift` exercises every operation
with a fake data source, including the subject-only-placeholder regression, both provider-status
banners, every send validation path, and the log list/detail/not-found paths. `explicit-error-
handling` passes: every throwing path other than `status(...)` routes through `HubError.wrap(_:)`
or a specific validation throw; the one place an error is swallowed (`status(...)`, via `try?`) is
a documented, signaled degradation (a fallback banner), not a silent loss. `no-hardcoded-strings`
fails outright — see Localization; there is no localization mechanism anywhere in either file.
`error-recovery` fails: neither file retries, backs off, or queues a failed call — every
`MessagingDataSource` invocation other than `status(...)` is a single `try await`/`try` that
throws straight through to the caller on any failure. `idempotent-operations` fails: nothing in
`send-invokes-data-source` attaches an idempotency key or otherwise guards against the same
`MessagingSend` being submitted twice by a retried or double-triggered save. `data-integrity` is
`partial`: the send path validates its own shape thoroughly before submitting (required fields,
placeholder coverage, JSON shape), but see **log-pagination** — `total` is
decoded from every log page and never checked, so a log with more entries than `logPageSize` gives
no signal that its display is incomplete.

