
**Decision**: Gate every candidate through
`OpenVSXExtensionDetail.installability(forHostVersion:)` — the same check
the installer applies — before treating a newer published version as an
update, rather than reporting any version increase as an update.
**Rationale**: The registry publishes versions that raise `engines.vscode`
past what this host declares, and versions built for one native platform;
offering either as an update produces a button whose only outcome is a
refusal on install, so a version that fails installability is treated as
the end of that extension's updates for now rather than a broken offer
(source doc comment on `ExtensionUpdateCheck`, annotated
`*(principle-of-least-astonishment)*`; tests `newerButIncompatibleIsNotOffered`,
`newerPlatformSpecificIsNotOffered`).
**Approved**: pending

**Decision**: Address the registry by the manifest's `publisher` and `name`
fields directly, never by splitting `installed.identifier` (the case-folded
`"publisher.name"` string) back apart on its dot.
**Rationale**: A publisher name that itself contains a `.` — the source's
own example is `"my.company"` — would split at the wrong place under naive
re-splitting, and the identifier's case-folding is this host's own
convention for matching, not the registry's addressing scheme (inline
comment; test `lookupUsesThePublisherVerbatim`).
**Approved**: pending

**Decision**: Treat an unparseable version string on either side as a
thrown `versionNotComparable` error, never as "not an update" decided by
raw string inequality.
**Rationale**: Comparing version strings lexically would happily present a
downgrade as an update whenever string ordering and semantic ordering
disagree; refusing to decide is safer than deciding wrong, so the source
raises a distinct, typed error instead of silently falling through to "no
update" (inline comment; test `incomparableVersionsThrow`).
**Approved**: pending

**Decision**: (Swift implementation) Run every extension's registry lookup
concurrently via `withTaskGroup`, and restore a deterministic order
afterward by explicitly sorting both result arrays by identifier, rather
than relying on any ordering the task group provides or checking
sequentially.
**Rationale**: The check is entirely network latency, and a user with
twenty extensions installed should not wait twenty sequential round trips;
running them together is strictly faster with no added risk, but task
completion order alone would reshuffle a panel's rows between two runs that
found the same answers, so the explicit `sorted` calls are what make the
result reproducible rather than the concurrency itself (doc comment; test `resultsAreSorted`).
**Approved**: pending

**Decision**: Report a lookup that could not be answered (`notCheckable`)
beside the updates rather than treating "found nothing" and "could not ask"
as the same outcome, and further split the reason a 404 gives from every
other kind of failure.
**Rationale**: An extension installed by hand and never published 404s
every single time; folding that into "up to date" would silently hide a
genuinely unknown extension, and folding it into every other failure mode
would tell a user whose network is down that most of their extensions do
not exist. The two questions a reader can act on differently —
"this was never published" versus "the registry did not answer" — are kept
apart for that reason (doc comments; tests
`oneUnknownExtensionDoesNotFailTheCheck` and
`aFailingRegistryIsUnreachableRatherThanUnknown`).
**Approved**: pending

