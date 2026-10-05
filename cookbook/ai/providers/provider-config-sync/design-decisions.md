
**Decision**: The sync envelope carries the entire provider registry (every resolved-configuration record plus the current selection) in one payload, rather than an incremental add/remove/update delta.
**Rationale**: per this component's own documented contract, this is a deliberate replacement for "the old flattened push," chosen so "the daemon mirrors the full registry ... rather than a single plugin-keyed slot" — a full-snapshot payload cannot drift from partial updates arriving out of order, at the cost of resending every configuration's `values`/`secrets` on every sync, even for configurations that did not change.
**Approved**: pending

**Decision**: The resolved-configuration record splits a configuration's resolved values into two parallel text-to-text maps (`values`, `secrets`) rather than one map of a richer value type that carries its own secret/non-secret flag.
**Rationale**: this mirrors the split the provider-configuration-keys component and the daemon's chat-completion path already make between plain settings storage and secure-store-backed secret storage — a receiver can route each map to its corresponding store directly, without inspecting per-field metadata to decide where a value belongs. (Apple platform implementation.)
**Approved**: pending

**Decision**: every stored field of the sync envelope and resolved-configuration record is declared mutable, not fixed at construction — unlike the sibling chat-context types, whose stored fields are all immutable.
**Rationale**: not explained in source; recorded here as an observed divergence from the sibling immutability convention rather than corrected, since neither the concurrent-share-safety nor the structural-equality requirement demands immutability and the source gives no indication of an in-place-mutation call site that would justify it. (Apple platform implementation.)
**Approved**: pending

**Decision**: The sync envelope is only a wire shape: no sender or receiver for it exists in this repository.
**Rationale**: The daemon host that receives the payload and the app-side sender are not part of this repository, so nothing here builds the envelope from the provider-configuration store or persists a decoded one under the configuration key namespace (honoring empty-secret-clears-credential). Closing the gap takes that sender and receiver being added, or confirmation that they live in the hosting product.
**Approved**: pending

**Decision**: The envelope's configs list does not enforce unique configuration identifiers.
**Rationale**: A keyed mirror cannot hold two values under one key, but this component only declares fields, and the source performs no validation at construction or decode. Closing it requires a defined outcome for duplicates (reject at construction, reject at decode, or a documented last-one-wins rule), most naturally in the receiver that persists the payload.
**Approved**: pending

