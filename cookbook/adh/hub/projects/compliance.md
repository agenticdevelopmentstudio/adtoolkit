
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [api-design-conventions](agenticdevelopercookbook://compliance/access-patterns#api-design-conventions) | passed | access-patterns |
| [pagination-support](agenticdevelopercookbook://compliance/access-patterns#pagination-support) | passed | access-patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | partial | reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | internationalization |
| [secure-transport](agenticdevelopercookbook://compliance/security#secure-transport) | passed | security |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | security |

Every logic component in this cookbook is held to at least
`separation-of-concerns` and `unit-test-coverage`, and both pass here on
their own terms. **`separation-of-concerns`** passes because each of the
fourteen files owns exactly one route stem/entity family with no
cross-file reach-in beyond the small, explicit `import { toX } from
"./y"` re-mapping calls that `programs.ts`/`triage.ts`/`templates.ts`
deliberately make (e.g. `toProject` reused by `programs.projects()`).
**`unit-test-coverage`** passes because four real `*.test.ts` files
(`projects.test.ts`, `search.test.ts`, `live.test.ts`,
`programs-milestones-health.test.ts`) exercise the wire contract, the
mappers, `compareRank`, `threadOf`, `milestoneProgress`, and the live-wake
refcounting/coalescing/poll-fallback/unsubscribe-race behavior directly —
the Conformance Test Vectors above are drawn from those real assertions,
not invented. **`api-design-conventions`** passes: every client follows one
`toX`/`BASE`/CRUD-object shape, and PATCH bodies uniformly use `compact` for
undefined-vs-null semantics. **`pagination-support`** passes: three
distinct, well-documented pagination strategies coexist correctly for their
different needs (activity's newest-first opaque composite keyset, triage/
search's clamped-limit-with-`hasMore` pages, and iteration/program/board
lists' unpaginated-but-reach-filtered full lists). **`idempotent-operations`**
passes: `artifacts.link` (per `(direction,kind,id)`) and `triage.accept`
(stamp preserved) are both explicitly, deliberately idempotent, each with a
doc comment and a dedicated behavior. **`error-recovery`** is `partial`: a
404 on `get()` recovers to a documented `null` and a search/triage/artifacts
list recovers to an empty result shape, but there is no retry or backoff
anywhere in this domain — a single network failure on any write (a `create`,
a `move`, an `accept`) surfaces immediately as a thrown error with no
built-in retry, which is a fact about the current source (see Edge Cases:
Error states), not a marker-worthy gap, since no doc comment or type
signature in this domain promises retry behavior it fails to deliver.
**`no-hardcoded-strings`** is `failed`, honestly: `validateKeyPrefix`'s two
messages and the two default item nouns are fixed English literals with no
i18n key anywhere in these fourteen files (see Localization) — a real,
reported gap in this vocabulary, not a marker, because it is a plain,
observable fact about the source rather than an unresolvable contract
question. **`secure-transport`** passes: every call goes through
`authedJson`/`authedRequest`'s Bearer-token client, and this domain attaches
no credential or cookie of its own. **`secure-log-output`** passes because
there is no logging at all in this domain (see Logging) — nothing here can
leak a secret into a log it never writes to.

