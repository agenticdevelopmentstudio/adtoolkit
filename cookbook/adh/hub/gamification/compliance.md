
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |

`separation-of-concerns` passes: `gamification.ts`/`wire.ts` contain no
UI-rendering import and no business logic beyond building a path,
choosing an HTTP verb, and shaping a body — a clean, single-purpose
data-access layer consumed by a separate features package.
`unit-test-coverage` fails: no test file exists anywhere in the
repository adjacent to `gamification.ts` or `wire.ts` (confirmed by
search), unlike this package's sibling `hub-domain-ecosystem-config`
client, whose Apple counterpart has a dedicated test file even though its
web clients are likewise untested. `explicit-error-handling` passes:
every method lets `authedJson`'s rejection propagate untouched — there is
no `catch` anywhere in either file to silently swallow, so nothing is
ever discarded. `input-sanitization` is partial: `enc()`
(`encodeURIComponent`) sanitizes every dynamic URL segment against path
injection, but no field-level validation (comparator/tier enum
membership, `lengthDays` 1..366, event-type field length ≤64 chars, or
the level ladder's "start at 0, strictly increasing" shape) happens in
this module — every one of those documented constraints is enforced
only by the TypeScript compiler at the call site or by the backend's 400
response, per `levels-ladder-shape-enforced-serverside` and
`event-type-input-length-precondition`. `error-response-handling` is
partial: every operation's documented status codes (400/404/409) are
recorded in this file's own comments, but the client does not translate
any of them into a caller-facing message of its own — see the
`error-propagation-unmodified` Design Decision above; a caller must read
the raw `AuthHttpError` itself to act on a specific status.

