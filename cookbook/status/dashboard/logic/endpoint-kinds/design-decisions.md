
**Decision**: Declare the vocabulary once as an `as const` tuple and derive both the type and the guard from it.
**Rationale**: The authoring comment names three consumers (the editor dropdown, server-side validation, and the needs-wiring logic). Deriving `EndpointKind` by indexed access means one edit changes the runtime list, the type and the guard together.
**Approved**: pending

**Decision**: Re-export `NON_DEPLOY_KINDS` from the deploy engine instead of declaring it here.
**Rationale**: The authoring comment says the set "used to be three separate literal Sets, here, on the Hono server, and in the engine", and they disagreed about `dns`. The engine's `endpointNeedsWiring` acts on the set, so the engine owns it and every consumer re-exports the same object.
**Approved**: pending

**Decision**: The status server keeps its own copy of `ENDPOINT_KINDS` and `isEndpointKind` rather than importing this file.
**Rationale**: The server copy's comment says it is "kept in step with the status site's src/lib/endpoint-kinds.ts so the backend and frontend agree". The two packages do not share this module, so the list is restated and synchronised by hand, with no parity test. This contradicts this file's claim to be the "ONE source" for server-side validation; in practice the server validates with its twin.
**Approved**: pending

**Decision**: The guard compares exactly, with no normalization.
**Rationale**: `isEndpointKind` is a plain `includes` check. Kind strings are machine identifiers written by the editor's dropdown, so a case or whitespace variant is not a valid kind.
**Approved**: pending

