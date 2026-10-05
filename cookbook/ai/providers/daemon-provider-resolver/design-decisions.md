
**Decision**: `configurations(_:)` and `selectedConfiguration(_:)` treat every failure mode — an absent key, an empty string, malformed JSON, a JSON value of the wrong shape, or a non-UUID selected-id string — identically: return `[]` or `nil` with no distinction and no thrown error.
**Rationale**: `ProviderSettingsReader`'s signature (`String?`, non-throwing) cannot carry an error, and the type's own doc comment states it "Returns nil / "" when the id isn't known" — the resolver fails closed rather than propagate a decode failure the daemon has no user-facing surface to report. `DaemonAIChat.complete` relies on exactly this fail-closed `nil` to fall through to its zero-config CLI path instead of erroring when the registry is empty or corrupt.
**Approved**: pending

**Decision**: `selectedConfiguration(_:)` reads `selectedConfigIdKey` and `configurationsKey` as two separate, unsynchronized calls to `settings`, rather than one combined read.
**Rationale**: `ProviderSettingsReader` exposes only single-key reads, so any transactional read across two keys would have to be implemented by the caller's backing store, not by this type; the resolver accepts the resulting non-atomicity (see Edge Cases) because a transient mismatch resolves to the same safe `nil` outcome as "no configuration selected."
**Approved**: pending

**Decision**: `selectedConfiguration(_:)` returns the first array element matching the selected id and enforces no uniqueness invariant of its own over the decoded registry.
**Rationale**: configuration-id uniqueness is established when a configuration is created (`AIProviderConfiguration.init(id: UUID = UUID(), …)` and the app-side store's add/rename flow), not re-verified by the daemon-side reader. `DaemonProviderResolver` trusts the registry it is handed, per its role as the mirror of the app's resolver, and duplicating that validation here would be redundant work with no daemon-observable benefit.
**Approved**: pending

**Decision**: A corrupt-but-present provider registry produces no diagnostic signal in the daemon; it reads as an empty registry.
**Rationale**: The settings-reader shape cannot carry an error and the resolver has no logging surface, so the daemon treats an undecodable registry the same as an absent one (callers then fall through to the zero-config path). Closing the gap would take either a logging/telemetry hook injected into the resolver or a result type distinguishing absent from corrupt, plus a decision on whether operators need that signal.
**Approved**: pending

