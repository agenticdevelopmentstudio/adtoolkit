
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | partial | Security |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |

`separation-of-concerns` passes: `integrations.ts`/`wire.ts` contain zero UI or presentation code — both
files are a plain request-builder layer consumed by a separate presentation layer, per the module's own
top-of-file comment. `unit-test-coverage` is `failed`: none of `integrationsApi`'s twenty methods, nor
`decodeOAuthStateClaims`/`isOAuthStateFresh`, has a test file adjacent to `integrations.ts`/`wire.ts`
anywhere in this checkout — the closest exercise of `decodeOAuthStateClaims`/`isOAuthStateFresh` is an
indirect one, through a consumer component's own test (`IntegrationsOAuthCallback.test.tsx`), which is
outside this component's given sources. `explicit-error-handling` passes: every failure either throws
`AuthHttpError` (via the shared `authedFetch`) or is the explicit `isNotFound`-gated `null` return in
`getProviderConfig`/`getProviderConfigById`; nothing in this file catches and discards an error.
`input-sanitization` is `partial`: `decodeOAuthStateClaims`'s grammar and field-type checks
(`decode-state-claims-grammar`, `decode-state-claims-field-validation`) are real input validation, and
`isOAuthStateFresh` adds a documented freshness check on top — but neither is authoritative
(`decode-state-claims-never-verifies-signature`), and every write method (`putProviderConfig`,
`createProviderConfig`, `connect`, and the rest) forwards its caller-supplied body with no client-side shape
or charset validation of its own, deferring entirely to the backend. `secure-storage` is `partial`: the OAuth
client secret and GitHub App private key are never returned in plaintext by this client (`secrets-are-write-only`),
and `integrationsApi` itself persists nothing (`no-client-side-cache`) — but the deliverability
webhook secret is passed through unredacted on every read that carries it
(**webhook-secret-visibility-after-mint**).
`idempotent-operations` is `partial`: `adoptInstallations` is explicitly documented safe to call more than
once (`adopt-installations-idempotent`), but `rotateWebhookSecret` is explicitly *not* idempotent by design
(each call mints a new secret), and `connect` sends every repeat call with no idempotency key
(**connect-repeat-call-ordering**). `error-response-handling` is `partial`: every call exposes a status and
optional code for the caller to branch on, and two specific codes are documented by name in this client's own
comments (`404` → `null` for the two get-by-id lookups, `503` → "no worker" for `sync`), but every other
method offers no per-code handling beyond the generic `AuthHttpError` propagation.

