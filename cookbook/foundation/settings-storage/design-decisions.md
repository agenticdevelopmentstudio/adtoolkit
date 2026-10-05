
**Decision**: Replace `UserSettings.shared` — if a host app needs a different provider configuration at all — only before constructing any `UserSetting`. (Apple/Swift implementation.)
**Rationale**: `UserSetting.init` captures `UserSettings.shared` once, to read the initial value and subscribe to its `changes`; replacing `shared` afterward leaves that instance's subscription pinned to the old store while its `value` accessor and the subscription's own re-read both target whichever instance is current — an inconsistency the source leaves to the caller's setup order (see `usersettings-shared-reassignment` in Edge Cases).
**Approved**: pending

**Decision**: Construct at most one `KeychainSecureSettingsStorageProvider` per process with a non-default `service`/`accessGroup`, or construct every instance with the same override. (Apple platform — Keychain-backed secure provider.)
**Rationale**: `init` assigns its `service` and `accessGroup` arguments to the process-wide statics `KeychainHelper.service`/`KeychainHelper.accessGroup`, including assigning `nil` unconditionally, so a later default-argument instance silently clears an override an earlier instance made intentionally; this is documented inline in `init`'s own comment, and a second, differently-configured instance changes keychain routing for every existing instance too, not only the new one.
**Approved**: pending

**Decision**: `KeychainSecureSettingsStorageProvider` memoizes every read — a hit or a confirmed miss — for the life of the instance rather than reading through on every `get`. (Apple platform — Keychain-backed secure provider.)
**Rationale**: the type's own documentation traces this to a measured cost — a keychain miss walks the access-group query, the legacy no-group query, and every retired service before returning, and bulk-resolving many AI-provider settings on the main thread pinned the app above 100% CPU inside the keychain query call. The provider owns every write to the keys it serves, so the memo can be exact rather than time-based.
**Approved**: pending

**Decision**: `UserSettingObserver` defers `onChange` to the next `DispatchQueue.main` turn rather than calling it synchronously or scheduling through `RunLoop.main`. (AppKit / Apple platform.)
**Rationale**: `@Published` publishes before the new value is assigned, so a synchronous observer would see the property's old value; and `RunLoop.main` schedules in the default run-loop mode only, which AppKit does not service while a mouse-down or a slider drag runs the run loop in its event-tracking mode. The main dispatch queue is drained in every run-loop mode, so this is the scheduling choice that keeps a live-dragging preview working, documented in source as the same fix an earlier observer needed for an identical failure.
**Approved**: pending

**Decision**: Treat `StoredSetting` and its `Observer`, in `StoredSettingPropertyWrapper.swift`, as excluded from this recipe's contract. (Swift implementation.)
**Rationale**: the entire file is wrapped in a disabled compile-time condition and does not build into the product; the live property-observation surface for a `UserSetting` is `UserSettingObserver`/`ObservedSetting` in `UserSetting.swift`.
**Approved**: pending

**Decision**: Both the plain persistent provider and the cloud-sync provider drop a value whose JSON encoding fails, silently: nothing is written, logged, or published.
**Rationale**: It stands today because `set` has no failure channel and every stored type is expected to encode; closing the gap would mean a logged error or a throwing `set` across every provider, which is an interface change. See `plain-provider-encode-failure` and `cloudsync-provider-encode-failure`.
**Approved**: pending

