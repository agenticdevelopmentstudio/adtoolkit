
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | partial | Access Patterns |
| [retry-with-backoff](agenticdevelopercookbook://compliance/access-patterns#retry-with-backoff) | failed | Access Patterns |
| [offline-behavior](agenticdevelopercookbook://compliance/access-patterns#offline-behavior) | failed | Access Patterns |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | failed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

`separation-of-concerns` **passed**: the wire types (`GameWire`,
`GameDefinitionWire`) are kept distinct from the client-facing `Game`/
`GameDefinition` types, and both column crossings are held in one set of
functions (`gameFromWire`/`gameToWire`/`definitionFromWire`/
`definitionToWire`) rather than repeated at each call site; the generic
`childApi` factory keeps transport shape separate from the three row
types it serves. `explicit-error-handling` **passed**: no path in this
module silently drops a failure — every error either matches a specific
remap (`rethrowConflict`'s message test, `textToJson`'s `clientRefusal`)
or propagates unchanged; nothing is caught and discarded.
`unit-test-coverage` **partial**: `games.test.ts` exercises `gamesApi`'s
full surface (list scoping, `forEcosystem`, create/update body-vs-query
scoping, conflict mapping, delete's id-encoding) and both column crossings
exhaustively, but never exercises `childApi`'s `update` or `delete` for
any of the three child collections, and never exercises
`child-create-update-no-conflict-mapping`'s no-remap behavior directly.
`error-response-handling` **partial**: the module distinguishes a
"duplicate slug" conflict from every other error by message content in
exactly two functions (`gamesApi.create`/`update`); it never distinguishes
a `404` from any other status anywhere (there is no `isNotFound`-style
branch in this file, unlike `hub-domain-ecosystems`'s `ecosystemsApi.get`),
and the three `childApi` clients distinguish nothing at all.
`retry-with-backoff` **failed**: no file in this module retries a failed
request; the underlying `authedFetch`'s one-refresh-then-retry is a
401-specific auth waterfall (see `auth-client`), not a retry of this
domain's own operations. `offline-behavior` **failed**: this module
defines no offline-cache-first read path and no queued-write-when-offline
behavior; every call is a live round trip that fails outright when the
network is unavailable. `timeout-handling` **failed**: no call in this
module sets a timeout or passes an `AbortSignal`; a hung request hangs
until the underlying `fetch` itself resolves or rejects.
`idempotent-operations` **partial**: every `update`/PUT in this module
sends the full replacement state, which is naturally idempotent to repeat;
no `create`/POST carries an idempotency key, so a client-level retry of a
create (were one ever added) could not distinguish a genuine duplicate
request from a second, different create — the module currently avoids the
question entirely by never retrying. `input-sanitization` **partial**:
`textToJson` enforces JSON-parseability before a `jsonb` write and
`emptyToNull` trims text before the null crossing, but every closed-set
field this module sends (`characterNames`, `status`, `eventLog`,
`trigger`, `operation`) is passed through with no client-side check
against its own closed set, relying entirely on the backend's database
`check` constraints. `data-minimization` **passed**: every field this
module reads or writes is game/definition/effect/mapping catalog
metadata; its own header comment states the deliberate exclusion of the
schema's player-state tables. `no-hardcoded-strings` **failed**: every
user-facing string this module produces (the conflict message, the two
JSON-refusal messages) is fixed English with no lookup table or locale
parameter (see Localization) — a plain, honestly-reported gap, not a
hidden one.

