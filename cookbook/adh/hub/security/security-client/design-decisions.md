
**Decision**: `deleteGroup` and `upsertGrant` wrap their call in no `try`/`catch`, while
`createGroup`, `updateGroup`, and `addMember` each catch and pass the error through `rethrowConflict`.
**Rationale**: `rethrowConflict` rewrites an error only when its message matches `/already exists/i`
— a naming or uniqueness collision the caller caused by picking a value that collided with an
existing row. `deleteGroup`'s `409` (the seeded "everyone" group refusing deletion) and any `upsertGrant`
failure are not naming collisions, so wrapping either in `rethrowConflict` would be a no-op even if
added: the regex would never match, and the original error would pass through unchanged regardless.
**Approved**: pending

**Decision**: `tokens.ts`'s `revoke` percent-encodes its path segment with the global
`encodeURIComponent`, while every `bucket-access.ts` method uses the `enc` alias
(`client-helpers.ts`'s re-export of the identical function) for the same purpose.
**Rationale**: not explained in either source file; recorded here as an observed naming inconsistency
between two sibling files in the same domain folder, not a functional difference — both names resolve
to the same built-in function, so `hub-domain-security-021`'s behavior is identical either way. A port
to another platform should use one consistent name for this operation rather than carrying the
inconsistency forward.
**Approved**: pending

**Decision**: `wire.ts`'s types are declared as a package-local mirror of the OpenAPI-generated shapes
in `@agentic-toolkit/adh-api-types`, rather than importing them directly.
**Rationale**: per `wire.ts`'s own header comment, this keeps the toolkit decoupled from the hub's
generated types "without narrowing what a caller can rely on" — the mirrored interfaces carry full
backend-schema fidelity (every field the backend's OpenAPI schema declares), not only the subset
`tokens.ts`/`bucket-access.ts` happen to read or write today.
**Approved**: pending

