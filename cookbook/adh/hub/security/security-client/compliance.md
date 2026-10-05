
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [token-lifecycle](agenticdevelopercookbook://compliance/security#token-lifecycle) | partial | Security |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |

`separation-of-concerns` passes: `tokens.ts`, `bucket-access.ts`, and `wire.ts` contain zero UI or
presentation code — both the module's own comments and `index.ts` describe it as the public surface
of a data domain, consumed by a separate presentation layer. `unit-test-coverage` fails: this checkout
has no `__tests__` directory, and no test file of any kind, under
`packages/web/packages/data/src/security/` — none of `tokensApi`'s four methods or
`bucketAccessApi`'s eight methods has a dedicated unit test, unlike the sibling `access.ts`, which has
at least one tested method. `explicit-error-handling` passes: nothing in either file swallows an
error — every failure either throws `AuthHttpError` (via the shared `authedFetch`) or, at the three
`rethrowConflict` sites, a plain translated `Error`; nothing is caught and discarded.
`server-side-authorization` passes: neither client performs a client-side permission check of any
kind, per `server-side-grant-and-ceiling-validation` and `server-side-seeded-group-protection` —
grant-target validity, the bucket ≥ type ≥ row ceiling, and the seeded group's delete protection are
all enforced entirely by the backend. `token-lifecycle` is `partial`: `mint`/`revoke` support an
optional expiry and on-demand revocation, but this client enforces no minimum or maximum token
lifetime and performs no rotation of its own — a deliberate difference from a short-lived session
access token (these are long-lived personal API tokens by design, per `ApiTokenRow`'s `expiresAt:
string | null` allowing "never expires"), but the check's stated bar ("short-lived (5-15 min) with
refresh token rotation") is not met by this token model, and this recipe records that gap rather than
mark the check inapplicable to a security-relevant credential-issuing surface. `error-response-handling`
is `partial`: `createGroup`, `updateGroup`, and `addMember` translate their one documented conflict
code into a friendly message, but `deleteGroup`, `upsertGrant`, `deleteGrant`, `mint`, and `revoke`
offer no per-status handling beyond the generic `AuthHttpError` propagation every non-2xx response
already gets. `idempotent-operations` is `partial`: `upsertGrant` is a true upsert via `PUT` and is
idempotent by construction; `createGroup` and `addMember` are not idempotent themselves but turn a
retried duplicate into a detectable `409` via the backend's uniqueness constraint; `mint` has neither
property — per `token-mint-retry-duplication`, a retried `mint` can silently issue a second, live
credential with no way for the caller to detect or reconcile it from this module alone.

