
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | passed | Access Patterns |
| [retry-with-backoff](agenticdevelopercookbook://compliance/access-patterns#retry-with-backoff) | failed | Access Patterns |
| [offline-behavior](agenticdevelopercookbook://compliance/access-patterns#offline-behavior) | failed | Access Patterns |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | partial | Reliability |

`separation-of-concerns` **passed**: `EcosystemsDataSource` is a pure I/O
boundary the module never bypasses; topics compose via the
`EcosystemTopicProvider` protocol rather than subclassing or reaching into
each other's state, and the web client keeps wire shapes (`wire.ts`)
separate from the UI-facing `Ecosystem` type. `explicit-error-handling`
**passed**: every catch on both platforms either re-maps a specific error
(`HubError.notFound`→`.empty`, `HubError.conflict`→`.validation`,
`isNotFound`→`null`, a 409→`rethrowConflict`) or wraps/rethrows
unconditionally (`HubError.wrap`) — no path silently swallows a failure.
`unit-test-coverage` **passed**: `EcosystemsModuleTests.swift` exercises
every public path this recipe documents (root listing, manageability
gate, topic dispatch, settings save/delete, child-ecosystem recursion,
create-form validation and prefix resolution), and `ecosystems.test.ts`
does the same for the web client's mapper, create/update body shapes, and
`ecosystemIdForSlug`'s ownership-first resolution; `ecosystem-features.test.tsx`
pins `remove`'s 404-as-success and rethrow paths and `useApplyFeatureChange`'s
all-settled removal and failed-key message (the catalog, list and provision
calls and their hooks' cache writes have no direct test). `error-response-handling`
**passed**: `isNotFound`/`isConflict` and `HubError.notFound`/`.conflict`
consistently distinguish "missing" from "already exists" from every other
failure on both platforms, and `ecosystemIdForSlug` explicitly rethrows a
non-404 rather than treating it as license to fall back
(hub-domain-ecosystems-035). `retry-with-backoff` **failed**: no file in
either implementation retries a failed ecosystems/identifiers request —
the underlying `authedJson`'s 401-refresh-and-retry-once is a different,
cross-cutting auth concern (see `auth-client`), not a retry of this
domain's own operations. `offline-behavior` **failed**: neither
implementation defines an offline-cache-first read path or a
queued-write-when-offline behavior; every operation is a live round-trip
that fails outright when the network is unavailable.
`idempotent-operations` **partial**: the feature client is idempotent on
both mutating paths — `remove` treats an already-gone row (404) as success,
and `provision` of an already-active key is a backend no-op — and
`ecosystemsApi.update`'s PUT is
documented as idempotent by the backend's own locked-value diff (sending
an unchanged `slug` is a no-op, per the source's `addressPatchMoves`
comment), but `create` has no idempotency key on either platform — a
client-level retry of a create (were one ever added) could not safely be
distinguished from a genuine duplicate request without one.
`input-sanitization` **partial**: `Slug.pattern`/`FormValidator` (Apple)
validate the slug's character set client-side, and `addressLeaf` is a
pure slice with no validation of its own by design (see Edge Cases); the
server's unique-address constraint and `id`-vs-leaf assertion are the
real authority on both platforms, which this component deliberately
relies on rather than duplicating. `data-minimization` **passed**: every
field this component reads or writes is ecosystem/product metadata, never
end-user personal data. `no-hardcoded-strings` **failed**: every
user-facing string this recipe documents (labels, warnings, validation
messages) is fixed English with no lookup table or locale parameter on
either platform (see Localization) — a plain, honestly-reported gap, not
a hidden one. `fault-tolerance` **partial**: `useApplyFeatureChange`
keeps going past a failed removal and reports it by name rather than
aborting, and `FeatureSubscriptionTier` is an open string so an unknown
tier cannot break parsing; but the feature mutation hooks accept a
nullable `ecosystemId` and send it unguarded (see the features-mutation-null-id-unguarded requirement).

