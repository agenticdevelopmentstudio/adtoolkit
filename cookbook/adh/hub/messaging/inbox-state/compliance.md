
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [secure-transport](agenticdevelopercookbook://compliance/security#secure-transport) | partial | Security |
| [reconnection-strategy](agenticdevelopercookbook://compliance/access-patterns#reconnection-strategy) | partial | Access Patterns |
| [pagination-support](agenticdevelopercookbook://compliance/access-patterns#pagination-support) | partial | Access Patterns |
| [offline-behavior](agenticdevelopercookbook://compliance/access-patterns#offline-behavior) | partial | Access Patterns |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | passed | Access Patterns |
| [retry-with-backoff](agenticdevelopercookbook://compliance/access-patterns#retry-with-backoff) | failed | Access Patterns |
| [timeout-configuration](agenticdevelopercookbook://compliance/access-patterns#timeout-configuration) | failed | Access Patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |

`separation-of-concerns` passes: both files contain zero JSX or DOM code — they export hooks and
plain functions consumed by a separate presentation layer. `unit-test-coverage` fails: this
checkout has no test file next to either `use-dms.ts` or `use-notifications.ts`, and the one
messaging-adjacent test found (`MessagingPane.test.tsx`, in a different package) exercises a
different component and neither imports nor mocks either file. `explicit-error-handling` is
`partial`: every plain HTTP failure either throws (`AuthHttpError`/`Error`) or lands in an exposed
`error` field, but several catches (`fetchPresenceMap`, the SSE malformed-frame handler, and both
poll-fallback refetches) discard the error with no signal at all beyond a silent fallback.
`server-side-authorization` passes: `startDm`'s `403`-to-`forbidden` mapping and every route's
participant-scoping are enforced entirely by the backend per the source's own "Backend contract"
comments; neither file performs a client-side permission check. `secure-transport` is `partial`:
neither file controls TLS itself (deployment-level, unverifiable from this checkout), and the
SSE-token-in-query-string design is a documented deviation from the header-based scheme the rest of
this recipe uses, per `sse-token-rides-the-query-string`. `reconnection-strategy` is `partial`:
`connectSse` defines explicit, self-healing reconnection (live retry plus interval-and-focus poll),
but with no exponential backoff or jitter — a fixed poll interval only. `pagination-support` is
`partial`: the DM conversation list and the notification inbox both support pagination
(`pageSize`/`page`, and the DM list's growing-window `loadMore`), but the DM thread exposes no
further-back paging for message history. `offline-behavior` is `partial`: the poll fallback
degrades gracefully across a connectivity blip, but neither file checks `navigator.onLine` or
queues a `send`/mutation issued while offline. `error-response-handling` passes: every documented
status this recipe's own backend-contract comments describe (`401`, `403`, `204` where relevant) is
handled explicitly, and every other non-2xx status surfaces as a typed `AuthHttpError`.
`retry-with-backoff` fails: no call in either file retries a failure with backoff of any kind
beyond the single inherited `401` refresh-and-retry. `timeout-configuration` fails: no call sets a
deadline or `AbortSignal`. `idempotent-operations` passes: `mergeMessage`'s id-based dedupe makes a
duplicate delivery (the SSE stream and a `send`'s own POST response both resolving the same row) a
no-op, and `send` generates a `clientMessageId` intended for server-side idempotency per the
source's own comment. `graceful-degradation` passes: a dead SSE stream downgrades to polling, a
failed presence fetch downgrades to "assume offline," and a failed list refresh keeps the last good
data — none of the three crashes the hook or blanks the UI.

