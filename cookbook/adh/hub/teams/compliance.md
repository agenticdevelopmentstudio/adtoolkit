
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [api-design-conventions](agenticdevelopercookbook://compliance/access-patterns#api-design-conventions) | partial | access-patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | failed | reliability |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | partial | reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | internationalization |
| [secure-transport](agenticdevelopercookbook://compliance/security#secure-transport) | passed | security |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | security |
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | security |

Every logic component in this cookbook is held to at least
`separation-of-concerns` and `unit-test-coverage`. **`separation-of-concerns`**
passes: `teams.ts` owns the `Team` route stem, `team-members.ts` owns the
membership route stem, and `wire.ts` is a type-only file the other two read
— no file reaches into another's internals. **`unit-test-coverage`** is
`partial`: `teams.test.ts` exercises `toTeam` and `validateTeamIdentifier`
directly (the vectors above traced to its three assertions), but no test
file exists for `team-members.ts` at all — every `teamMembersApi` behavior
in this recipe is traced to the source code and its doc comments, not to a
test assertion. **`api-design-conventions`** is `partial`: the domain does
not follow one uniform client shape end to end — `teamsApi` maps through a
`wire.ts` row and a `toX` mapper and translates a 409 to a friendly message
on write, while `teamMembersApi` declares its type directly with no mapper
and no friendly-message translation on a duplicate-member 409 (see Design
Decisions for why the divergence is deliberate; the asymmetry itself is
real, not invented). **`idempotent-operations`** is `failed`, honestly:
neither `teamsApi.create`/`update` nor `teamMembersApi.add`/`addPersona` is
idempotent — a retry of a write that already succeeded server-side (e.g.
after a dropped response) hits a 409 conflict rather than transparently
returning the existing row, unlike the idempotent-per-triple pattern the
sibling `hub-domain-projects` recipe documents for `artifacts.link`.
**`error-recovery`** is `partial`: `teamsApi.get`'s 404 recovers to a
documented `null`, but (a) that recovery is over-broad — see
team-get-swallows-any-error-as-not-found — and (b) no method on either
client retries or backs off a transient failure. **`no-hardcoded-strings`**
is `failed`: `validateTeamIdentifier`'s two messages and the
`rethrowConflict` friendly-conflict message are fixed English literals with
no i18n key anywhere in these files (see Localization). **`secure-transport`**
passes: every call goes through `authedJson`/`authedRequest`'s Bearer-token
client, and this domain attaches no credential or cookie of its own.
**`secure-log-output`** passes because there is no logging at all in this
domain (see Logging). **`server-side-authorization`** passes: this domain
never attempts its own authorization check — team owner/admin scope and
the persona `may_act` `'team'` grant are both enforced entirely by the
backend, and this client only surfaces the resulting 403/404 (file headers
of both `teams.ts` and `team-members.ts`).

