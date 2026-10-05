
**Decision**: The setting tracks *disabled* identifiers rather than *enabled* ones.
**Rationale**: disabled-rather-than-enabled means a freshly installed extension is on by default and needs no migration when a new extension is added. The inverse representation would require seeding every new extension's identifier into an "enabled" set at install time, and anyone who never relaunched after that seeding step would see the new extension as disabled.
**Approved**: pending

**Decision**: The storage key `"extensions.disabledIdentifiers"` is a literal string, declared once, never derived or namespaced further at this layer.
**Rationale**: the key is load-bearing — changing it orphans every user's existing choices and needs a migration — the same contract a stored theme-customization key carries elsewhere in this settings layer.
**Approved**: pending

**Decision**: (Swift/AppKit implementation) the setting is constructed with no secure-storage flag, so the identifiers persist through the ordinary settings store, not the Keychain.
**Rationale**: an extension identifier is a public, non-sensitive string with nothing to gain from Keychain's confidentiality or access-control guarantees; the call site simply omits the flag and takes the setting mechanism's `false` default.
**Approved**: pending

**Decision**: (Swift/AppKit implementation) the setting's observable current value updates synchronously, in the same call that writes the value, rather than on a redispatched queue turn.
**Rationale**: the setting mechanism's subscription to the store's change publisher applies no scheduling operator, unlike its observer helper's explicit main-queue redispatch. Recorded here so a port does not assume the observer's dispatched-callback delay also applies to the mirrored current value itself, which this setting exposes directly.
**Approved**: pending

