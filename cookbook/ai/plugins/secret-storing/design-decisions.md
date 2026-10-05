
**Decision**: `deleteLegacy(forKey:)` retargets the process-wide `KeychainHelper.service` static for the duration of the call rather than taking an explicit service parameter, then restores the prior value via `defer`; neither this method nor `SecretStoring` performs any locking around the swap. (Apple platform implementation.)
**Rationale**: `KeychainHelper.service` is the single global every `KeychainSecretStore` call is already scoped to, so reaching the pre-pin fallback service means temporarily repointing that one global rather than threading a service parameter through every `SecretStoring` method just for this one narrowly-scoped, rarely-invoked migration path. The source's own doc comment places the serialization burden entirely on the caller ("Callers must serialize this with their other Keychain access... stenographer runs it only inside its one-time, lock-serialized legacy cleanup"), trading compiler-enforced safety for a smaller API surface on a path that runs at most once per install.
**Approved**: pending

**Decision**: `KeychainHelper.set`'s implementation issues a `delete(forKey:)` before every `SecItemAdd`, making `KeychainSecretStore.set` a non-atomic two-step overwrite rather than a single atomic update. (Apple platform implementation.)
**Rationale**: this is the mechanism both `set-overwrites` and the open `same-key-concurrent-mutation` question depend on — a reader of `SecretStoring.set`'s one-line signature would not expect an implicit delete-then-add pair, and that pair is exactly what makes concurrent same-key writes racy. Recorded here as observed technical debt affecting behavioral correctness, per Source Fidelity, rather than corrected, since changing it would mean changing `KeychainHelper.swift`, a file outside this component's own contract.
**Approved**: pending

**Decision**: callers SHOULD depend on the abstract secret-store interface rather than the concrete production implementation (interface-over-concrete-usage).
**Rationale**: per the interface's own documented contract, the entire point of the indirection is "so tests can substitute an in-memory store and never touch the real login keychain." The daemon's chat-completion operation's default injected argument and the test-only in-memory implementation both depend on this indirection; a caller that instead hardcodes the concrete production implementation loses the ability to substitute a fake, and its tests would touch the real secure store. No deviation from this SHOULD is observed in the given sources.
**Approved**: pending

**Decision**: delete's documented contract describes a caller-side convention — "when the host clears a credential field it pushes an empty value, and the daemon deletes the entry rather than keeping a stale key" — that is not itself implemented or enforced by the interface, its production implementation, or any call site in the given sources; the daemon's chat-completion path only ever calls get, never set or delete. (Apple platform implementation.)
**Rationale**: the documented contract describes intended behavior of a host outside this repository (elsewhere referred to as the daemon's settings/config layer), not a contract this component's own code implements. Recorded here rather than turned into a formal requirement on the secret-store interface itself, since an interface method cannot enforce how its callers choose between setting an empty value and deleting.
**Approved**: pending

**Decision**: Concurrent same-key set and delete calls have no ordering guarantee.
**Rationale**: The production write path is a delete followed by an add with no lock, so a losing writer can fail and a concurrent read can see a transient miss; closing the gap takes a documented ordering rule (for example last-writer-wins with retry, or a required external per-key lock), prompted by a production call site that mutates one key from several concurrency domains or by the maintainers stating the intended guarantee.
**Approved**: pending

