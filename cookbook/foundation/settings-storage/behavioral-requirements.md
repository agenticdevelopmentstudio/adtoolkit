
### Setting keys

- **key-name**: Each setting key MUST supply a stable name (a string) that every backend uses as its storage key.
- **key-default-value**: Each setting key MUST supply a default value of its own value type, returned whenever no value has been stored, or a stored value cannot be decoded, for its name.
- **key-secure-routing**: Each setting key MUST supply an is-secure flag, and the settings store MUST route a key with is-secure == true to its secure backing provider and every other key to its plain provider.

### Storage provider contract

- **provider-get-fallback**: get MUST return the key's default value when the backend holds no value, or holds a value that cannot be decoded as the key's value type, for that key's name.
- **provider-set-persists**: set MUST make the new value readable by a subsequent get for the same key on the same provider instance once set returns.
- **provider-remove-restores-default**: remove MUST cause a subsequent get for that key to return the default value and contains to return false.
- **provider-contains**: contains MUST return true only when a value has been explicitly stored for that key's name and has not since been removed.
- **provider-change-notification-on-set**: set MUST publish the key's name on the change stream after the new value becomes readable through get.
- **provider-change-notification-on-remove**: remove MUST publish the key's name on the change stream.
- **provider-publisher-replay**: The default per-key live view MUST emit the provider's current value for that key immediately upon subscription, then emit an updated value each time the change stream names that key.
- **provider-publisher-ignores-other-keys**: The per-key live view MUST NOT emit when the change stream names a different key.
- **provider-values-stream**: The per-key value stream MUST expose the same replay-then-live sequence as the live view, through an asynchronous sequence, cancelling its underlying subscription when the stream terminates.
- **provider-plain-not-secure**: A storage provider MUST report is-secure == false unless it also identifies itself as a secure storage provider.
- **secure-provider-is-secure**: A secure storage provider MUST report is-secure == true.

### In-memory provider / in-memory secure provider

- **inmemory-concurrent-access**: The in-memory provider MUST serialize set/remove against every get/contains, so a concurrent read never observes a partially-written value.
- **inmemory-seeded-initial-values**: The in-memory provider's seed-values constructor MUST seed its backing storage directly from the untyped initial-values argument, without validating that a seeded value matches the value type of any key that will later read it.
- **inmemory-secure-delegates**: The in-memory secure provider MUST delegate every operation and its change stream to an internally-held, private in-memory provider, differing from it only in also identifying itself as a secure storage provider.

### Plain persistent provider

- **plain-provider-native-fast-path**: The plain persistent provider MUST store and read integer, floating-point, boolean, string, binary, URL, and date values through the backing store's native object storage rather than JSON encoding.
- **plain-provider-json-fallback**: For any value type outside that native set — arrays, dictionaries, and other structured values — the plain persistent provider MUST JSON-encode the value and store it as binary data.
- **plain-provider-corrupted-decode-fallback**: When previously-stored data for a key fails to decode as the key's value type, get MUST return the default value rather than throwing or crashing.
- **plain-provider-encode-failure**: When JSON encoding fails for a value with no native representation, the plain persistent provider's set MUST return without writing, without logging, and without publishing on the change stream, so the caller cannot learn the write did not happen.

### Secure persistent provider

- **secure-provider-string-fast-path**: For a string-valued key, get and set MUST read and write the raw string directly, without JSON quoting, so the secure store's entry holds the literal secret rather than a JSON string literal.
- **secure-provider-codable-path**: For any other structured, serializable value, set MUST JSON-encode the value to a UTF-8 string before writing, and get MUST JSON-decode the stored string back to the value type, returning the default value if decoding fails.
- **secure-provider-encode-failure-logged**: When encoding a non-string value fails, set MUST log an error and return without writing to the secure store or publishing on the change stream.
- **secure-provider-write-failure-invalidates-memo**: When the underlying secure-store write fails, set MUST remove any cached memo entry for that key and MUST NOT publish on the change stream.
- **secure-provider-remove-failure-invalidates-memo**: When the underlying secure-store delete fails, remove MUST remove any cached memo entry for that key and MUST NOT publish on the change stream.
- **secure-provider-read-memoization**: get MUST memoize the raw secure-store string for a key — including a confirmed absence — the first time it is read, and MUST answer every subsequent get for that key from the memo rather than re-querying the secure store, until set or remove updates the memo.
- **secure-provider-memo-per-instance**: The read memo MUST be private, per-instance state; a second secure persistent provider constructed for the same service MUST start with an empty memo.
- **secure-provider-contains-bypasses-memo**: contains MUST query the secure store directly, never through the read memo.
- **secure-provider-global-service-override**: Constructing a secure persistent provider with a non-nil service argument MUST assign it to the process-wide secure-store service identifier, and MUST unconditionally assign its access-group argument — including "none" — to the process-wide secure-store access group, so constructing an instance changes secure-store routing for every secure-store-backed caller in the process, not only for the new instance.

### Embedded-database provider

- **sqlite-schema-creation**: Constructing the embedded-database provider with a path MUST open, creating if absent, a database at that path, and MUST create a `settings_kv` table (`key TEXT PRIMARY KEY, value BLOB NOT NULL`) if it does not already exist, throwing an open error or a schema error if either step fails.
- **sqlite-json-storage**: set MUST JSON-encode every value and store it as the row's value blob via an upsert statement, so a key never occupies more than one row.
- **sqlite-serialized-access**: Every get, set, remove, and contains MUST run serialized against the same database handle, so concurrent calls on one instance are never interleaved.
- **sqlite-transient-binding**: Bound text and binary parameters MUST be copied by the database engine rather than referenced from caller-owned memory that may be freed before the statement executes.
- **sqlite-close-on-deinit**: The instance MUST close its database handle when it is deallocated.
- **sqlite-encode-failure-logged**: When JSON encoding fails, set MUST log an error and return without writing a row or publishing on the change stream.
- **sqlite-write-failure-no-notification**: When the prepare, bind, or step of the upsert statement fails, set MUST NOT publish on the change stream; the failure is logged by the layer that detected it.

### Cloud-synced provider

- **cloudsync-provider-native-fast-path**: The cloud-synced provider MUST store and read integer, 64-bit integer, floating-point, boolean, and string/binary values through the backing cloud key-value store's native storage; URL and date values are not natively supported and MUST go through the JSON-encoded binary path.
- **cloudsync-provider-int-promotion**: For a plain-integer-valued key, set MUST store the value as a 64-bit integer (the backing store has no native plain-integer accessor), and get MUST bridge a stored 64-bit integer back to a plain integer.
- **cloudsync-provider-explicit-synchronize**: set and remove MUST call the backing store's synchronize operation after mutating it, in addition to publishing on the change stream.
- **cloudsync-provider-external-change-forwarding**: The provider MUST forward every key named in the backing store's external-change notification payload onto its own change stream, so a change made on another device is observable through the same stream as a local set.
- **cloudsync-provider-encode-failure**: When JSON encoding fails for a value with no native representation, the cloud-sync provider's set MUST return without writing, without logging, and without publishing on the change stream, so the caller cannot learn the write did not happen.

### Settings store / shared instance

- **store-routing**: The settings store's get/set/remove/contains MUST dispatch to its secure provider when the key's is-secure flag is true and to its plain provider otherwise.
- **store-merged-changes**: The settings store's change stream MUST be the merge of both backing providers' change streams, so a single subscription observes changes from either provider.
- **store-default-providers**: Constructing a settings store with no arguments MUST default to the plain persistent provider for the plain provider and the secure persistent provider for the secure provider.
- **usersettings-shared-singleton**: The shared settings store instance MUST be a single, mutable, process-wide instance that every setting key's value/remove/exists accessor and every observable setting reads and writes through by default.
- **usersettings-shared-replacement-timing**: A host app SHOULD replace the shared settings store instance only before constructing any observable setting; see Design Decisions for the rationale and usersettings-shared-reassignment in Edge Cases for what happens otherwise.

### Observable setting / setting observer / observed-setting wrapper / color setting

- **usersetting-construction-reads-through**: Constructing an observable setting MUST synchronously read the current value for its key from the shared settings store instance before returning, so its current value reflects any already-stored value rather than always starting at the default value.
- **usersetting-value-mirror**: An observable setting's current value MUST update whenever the shared settings store instance's change stream names this instance's key, re-reading the value from the shared instance at that point.
- **usersetting-write-through**: Writing a new value to an observable setting MUST write through the shared settings store instance's set, so a subsequent read from any caller observes the new value.
- **observer-deferred-callback**: A setting observer's change callback MUST fire on the main thread on the turn after the current value changes, not synchronously inside the write that caused the change, and MUST NOT fire for the value a setting observer was constructed with.
- **observedsetting-wraps-observer**: An observed-setting wrapper MUST forward its wrapped value get/set to an internally-held setting observer and expose the underlying observable setting as its projected value.
- **colorsetting-alias**: A color setting MUST be an observable setting whose value type is a color value.
- **secure-provider-service-override-timing**: A caller SHOULD construct at most one secure persistent provider per process with a non-default service/access-group, or construct every instance with the same override; see Design Decisions.

### Threading

- **confines-to-ui-thread**: The component MUST be usable only on the UI thread. This covers the settings store, every setting and observer, every storage provider (including the in-memory, plain persistent, secure persistent, embedded-database, and cloud-synced backends), and the settings-window models, appearance manager, launch-at-login manager, and command-palette types built on them; only the launch-at-login service abstraction (a thin wrapper over the operating system's registration service) and plain value types such as colors and choice descriptors are not confined.

