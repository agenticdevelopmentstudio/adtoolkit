
**Decision**: `canonicalOnly` sets only `alternates.canonical` and never
`openGraph.url`, even for a caller that already knows the path.
**Rationale**: a page-level `openGraph` block replaces the layout's rather than merging
into it, so setting `url` here would silently drop the inherited `siteName`, `locale`
and `images`; a caller that wants a complete Open Graph block calls
`siteMetadata(id, { …, path })` instead.
**Approved**: pending

**Decision**: `seo.path`/`route.path` are documented as paths, never absolute URLs,
and neither `siteMetadata` nor `siteSitemap` validates a leading slash or otherwise
normalizes the value.
**Rationale**: every current call site passes a literal path constant; runtime
validation was judged unnecessary until a caller actually violates the documented
contract.
**Approved**: pending

**Decision**: `NOINDEX_BUILD`'s allowlist names the three non-production environments
explicitly (`local`/`testing`/`staging`) instead of testing `=== 'production'`.
**Rationale**: an unset or misspelled `NEXT_PUBLIC_DEPLOYMENT_ENV` then fails toward
indexable — the recoverable direction — rather than silently shipping `noindex` to
production; `siteRobots`'s host check is a second, independent layer that still blocks
non-production hosts even when this env var is wrong.
**Approved**: pending

**Decision**: `siteRobots` decides allow-vs-disallow from the request's hostname rather
than from `NEXT_PUBLIC_DEPLOYMENT_ENV`/`NOINDEX_BUILD`.
**Rationale**: host-based detection needs no per-project env configuration and cannot be
defeated by a missing or misconfigured variable; an unrecognized host fails closed
(disallow), the opposite failure direction from `NOINDEX_BUILD`, so the two layers cover
each other's blind spot.
**Approved**: pending

**Decision**: `siteSitemap`'s default `lastModified` is the moment the function runs
(`new Date()`), not a hand-maintained literal date, and that one `Date` is shared by
every route in the call that omits its own.
**Rationale**: a static marketing page is compiled from source, so a fresh deploy IS
the modification event; a hardcoded date rots the first time someone edits the copy
without remembering this file exists.
**Approved**: pending

