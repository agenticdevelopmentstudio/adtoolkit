
**Decision**: `ACCESS_FEATURES` is exported as a plain constant but never consulted from
inside `listFeatures` itself.
**Rationale**: the source's own comment frames it as a degraded path for "a backend that
predates `/access/features`," and the authoritative registry is per-deployment and
server-refined — so `listFeatures` staying strict (throw on anything it can't validate) and
leaving the fallback decision to the caller keeps this module from silently masking a real
backend/response mismatch as an old-backend case.
Platform scope: React/Web.
**Approved**: pending

**Decision**: `restrictItem`/`restoreItem` call `authedJson` rather than `authedRequest`,
even though both are declared `Promise<void>`.
**Rationale**: this is recorded as observed source behavior, not smoothed into the declared
type — a 204 response from either endpoint throws today, per `item-restrict-restore-parse-body`;
a port MUST preserve this exact behavior rather than "fixing" it to `authedRequest`'s
discard-the-body semantics, since the current backend's actual response shape for these two
routes is not available in this checkout to confirm which is correct.
Platform scope: React/Web.
**Approved**: pending

**Decision**: only `listFeatures` validates its response shape at runtime; `listRoles`,
`listAssignments`, and `effective` trust the generic `authedJson<T>` cast.
**Rationale**: the source's own `isAccessFeatureRow` comment explains this guard was added
after a bare cast on `/access/features` let a malformed response reach every consumer
looking like real data; no equivalent comment or fix exists for the other reads, so this
recipe records the current asymmetry as a fact of the source rather than projecting the same
guard onto endpoints that don't have it.
Platform scope: React/Web.
**Approved**: pending

**Decision**: the assignment-upsert operation does not validate that `feature` and `itemId` are supplied together or omitted together; a partial combination is sent to the backend as given.

**Rationale**: the field's doc comment states the pairing rule but the client leaves enforcement to the backend, whose handling of a `feature`-without-`itemId` write is not present in this checkout; closing the gap would take either a client-side guard rejecting partial scopes or a discriminated input type that makes the partial combination unrepresentable.

**Approved**: pending

