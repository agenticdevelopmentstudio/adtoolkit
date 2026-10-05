
**Decision**: `PrivacyTargetTable` is typed as a plain `string` rather than a closed union of known
target tables.
**Rationale**: `wire.ts`'s own comment states that a client that hard-coded the members would
refuse a target table the backend later adds; `data-profile-wire.test-d.ts` pins this as a
permanent, deliberate asymmetry against the generated backend type, not a placeholder meant to be
narrowed later.
Platform scope: Web
**Approved**: pending

**Decision**: `SOCIAL_LINKS_KEY`, `ADDRESSES_KEY`, and `USAGE_SUMMARY_KEY` are not exported; only
their namespaced accessor functions are.
**Rationale**: `profile.ts`'s own comment explains that using a bare root as a cache key would alias
one owner's list onto another's under prefix-based cache invalidation. Exporting only the accessor
keeps every consumer going through the one function that produces the owner-namespaced shape,
rather than risking a second, independently-derived key that silently desyncs from it.
Platform scope: Web
**Approved**: pending

**Decision**: none of `listSocialLinks`, `listAddresses`, `getPrivacyGrants`, or `getUsageSummary`
runtime-validates its response shape, unlike this cookbook's sibling `hub-domain-access` recipe's
`listFeatures`.
**Rationale**: recorded as observed source behavior, not smoothed over — no comment in `profile.ts`
or `usage.ts` documents an equivalent guard or a reason one was omitted. A port MUST preserve this
same trust-the-cast behavior rather than adding validation these two files don't have, since nothing
in the given sources establishes that the omission was a deliberate choice versus simply not yet
needed.
**Approved**: pending

**Decision**: `OwnerScopedRow.customerId` is documented as the denormalized creator of a row, not
its owner.
**Rationale**: `wire.ts`'s own comment warns "do not read it as 'whose row this is'" — a directly
relevant trap for a port that might otherwise assume `customerId` identifies the row's owning
principal, when the `ownerKind`/`ownerId` pair is the actual owner.
**Approved**: pending

