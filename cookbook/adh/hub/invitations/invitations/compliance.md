
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | security |
| [token-lifecycle](agenticdevelopercookbook://compliance/security#token-lifecycle) | partial | security |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | privacy-and-data |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | privacy-and-data |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | access-patterns |

Each of the five Apple files has one clear responsibility (data shapes,
shared notes sub-rail, and three thin per-collection topic providers that
each only render/dispatch and delegate persistence to the injected
`InvitationsDataSource`), and the web side splits wire types from the
request-shaping client the same way — **separation-of-concerns** passes.
**unit-test-coverage** is partial: `InvitationsTopicsTests.swift` exercises
all three Apple topics and the shared notes rail with twelve test methods,
but no test file exists anywhere in this repo for `invitations.ts`/`wire.ts`,
and grepping the repo turns up no consumer of `invitationsApi` either — its
own consumer, and any tests for it, live outside this repo.
**explicit-error-handling** is partial: the Apple side wraps every error
uniformly through `HubError.wrap`, and three of the web side's four methods
handle their own failure path explicitly, but `preview`'s bare `fetch` call
is not guarded against a network-level failure despite the source's own
"Never throws" doc comment — the
**preview-network-failure-rejects** requirement. **secure-storage** passes: neither
`invitations.ts` nor `wire.ts` stores the `password`, `token`, or
`refreshToken` values they handle — they are forwarded and returned only,
per **token-and-password-handling** — so this component itself never needs,
and never uses, platform secure storage. **token-lifecycle** is partial: the
web client receives a `token`/`refreshToken` pair from `accept` and
`registerWithInvite`, but neither issues, refreshes, nor rotates them
itself, and lifetime/rotation policy is not defined anywhere in these two
given files — that responsibility belongs to the caller's own token store.
**no-pii-in-logs** passes trivially: none of the seven given sources
contains a single logging call, so no PII can leak through logging here.
**data-minimization** passes: every DTO and form on both platforms carries
only the fields its own screen or endpoint needs (contact fields, note
content, or the four `registerWithInvite` fields), with no superfluous data
collected. **error-response-handling** is partial: the Apple side handles
every `InvitationsDataSource` failure identically via `HubError`, but the
three divergent web strategies documented under **Error states** mean a
caller of `invitations.ts` cannot assume one uniform error shape across its
four methods.

