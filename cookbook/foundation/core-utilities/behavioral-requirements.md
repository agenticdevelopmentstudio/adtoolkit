
### Encoding-skip wrapper

- **encoding-skip-shape**: The wrapper MUST be a generic value type holding
  a single mutable optional wrapped value, and MUST provide a way to
  construct it directly from that optional value.
- **encoding-skip-decode-yields-nothing**: The wrapper's decoding behavior
  MUST initialize the wrapped value to nothing unconditionally, regardless
  of whether the corresponding key is present or absent in the decoded
  input.
- **encoding-skip-encode-noop**: The wrapper's encoding behavior MUST be a
  no-op — it MUST NOT write anything to the target encoding.
- **decode-integration-skips-key**: the decoding-side integration
  specialized for the wrapper MUST return a wrapper holding nothing,
  without attempting to read the source at that key at all.
- **encode-integration-skips-key**: the encoding-side integration
  specialized for the wrapper MUST return without writing a null, a value,
  or anything else — the key MUST NOT appear in the encoded output at all.
- **encoding-skip-round-trip-loses-value**: encoding a model whose wrapped
  field holds a non-nothing value and then decoding the result back MUST
  yield a nothing wrapped value on the decoded copy — the original value
  MUST NOT survive an encode/decode round trip.
- **encoding-skip-concurrency**: The wrapper MUST NOT claim to be safe to
  share across concurrent contexts; its wrapped value is mutable, so a
  caller sharing one instance across concurrency domains MUST supply its
  own synchronization.

### Secret storage

- **keychain-service-default**: the store's `service` identifier MUST
  default to the app's bundle identifier, or `"com.agentictoolkit"` when
  none is available, and MUST be reassignable by a caller at any time.
- **keychain-access-group-default**: the store's `accessGroup` MUST default
  to nothing.
- **keychain-legacy-services-default**: the store's `legacyServices` MUST
  default to an empty list, ordered newest-retired-first.
- **keychain-query-shape**: building a query for an account MUST identify
  the item as a generic password (`kSecClass` = `kSecClassGenericPassword`),
  scoped to the store's current `service` (`kSecAttrService`) and the given
  account (`kSecAttrAccount`).
- **keychain-query-access-group-forces-data-protection**: when a query is
  built with a non-nothing access group, it MUST additionally scope to that
  group (`kSecAttrAccessGroup`) and require data-protection-keychain
  semantics (`kSecUseDataProtectionKeychain` = true); when the access group
  is nothing, both keys MUST be absent.
- **keychain-set-overwrites**: setting a value that hits a duplicate-item
  status on its first attempt MUST fall back to an update for the same
  query, so a second `set` call for the same key MUST overwrite the first
  value rather than fail.
- **keychain-set-access-group-accessibility**: when the store's access
  group is non-nothing at the time `set` runs, the item's accessibility
  attribute (`kSecAttrAccessible`) MUST be set to after-first-unlock,
  this-device-only.
- **keychain-set-returns-status**: `set` MUST return true only when the
  underlying add/update call reports success, and MUST return false for
  any other status.
- **keychain-get-primary-lookup**: `get` MUST first query under the current
  `service`/`accessGroup` scope and MUST return the stored string directly
  when that query succeeds.
- **keychain-get-access-group-migration**: when the primary lookup fails
  and the store's access group is non-nothing, `get` MUST retry the query
  with no access group; on success it MUST re-store the recovered value
  under the current `service`/`accessGroup` scope via `set` before
  returning it.
- **keychain-get-legacy-service-migration**: when the access-group retry
  also fails (or does not apply), `get` MUST iterate `legacyServices` in
  order and, for the first retired service under which the key is found,
  MUST re-store the recovered value under the current `service` before
  returning it.
- **keychain-get-exhausted-returns-nothing**: when the primary lookup, the
  access-group retry, and every entry in `legacyServices` all fail to
  locate the key, `get` MUST return nothing.
- **keychain-legacy-item-not-deleted**: when `get` recovers a value from a
  legacy access-group scope or a retired service, it MUST NOT delete the
  original item under that legacy scope — only a new copy is written under
  the current scope.
- **keychain-copy-value-single-match**: the lookup helper MUST limit the
  match to a single item (`kSecMatchLimit` = `kSecMatchLimitOne`) and
  request the data back (`kSecReturnData` = true), and MUST decode the
  returned data as UTF-8 text.
- **keychain-copy-value-logs-unexpected-errors-only**: the lookup helper
  MUST log an error when the underlying lookup call returns a status other
  than success and other than item-not-found; it MUST NOT log anything when
  the status is item-not-found.
- **keychain-delete-idempotent**: `delete` MUST return true when the
  underlying delete call reports success or item-not-found, and MUST
  return false for any other status — deleting an already-absent key is
  therefore never an error.
- **keychain-exists-checks-current-scope**: `exists` MUST return true when
  a query under the current `service`/`accessGroup` scope locates the key.
- **keychain-exists-checks-legacy-scopes**: when the current-scope check
  fails, `exists` MUST check `legacyServices` in order and MUST return true
  if any retired service holds the key.
- **keychain-exists-does-not-migrate**: unlike `get`, `exists` MUST NOT call
  `set` when it locates a key under a legacy scope — it only reports
  presence, it never re-stores.
- **keychain-global-state-not-isolated**: `service`, `accessGroup`, and
  `legacyServices` are shared mutable global state with no concurrency
  confinement of their own; the store performs no locking around reads or
  writes of these three values, so a caller that mutates one of them from
  more than one concurrent context without external synchronization MUST
  accept the resulting data race as the type's documented behavior, not a
  defect to report.
- **keychain-get-error-ambiguity**: `get`'s optional-string return cannot
  distinguish "no secret was ever stored for this key" from "a lookup
  failed for a reason other than not-found" (for example, an
  interaction-not-allowed status while the device is locked, or a missing
  entitlement); the lookup helper logs the status in that second case, but
  `get` still returns nothing either way, so no caller can tell the two
  outcomes apart from the return value alone.

### Security

- **keychain-secret-storage-mechanism**: every value `set` writes MUST go
  into the system credential store as a generic-password item — the store
  MUST NOT write a secret to a plain settings store, a file, or any other
  unencrypted store.
- **keychain-secret-value-not-logged**: every log call inside the
  secret-storage component MUST interpolate only the account key and a
  status/error value — none MUST interpolate the secret string passed to
  `set` or returned by `get`.
- **keychain-secret-no-transmission**: the store MUST perform no networking
  of any kind — it MUST NOT transmit a stored or retrieved secret
  off-device.
- **keychain-secret-lifetime-caller-controlled**: the store MUST define no
  TTL, expiry timer, or automatic-eviction policy for a stored item — a
  secret MUST persist until a caller calls `delete` or the OS/user removes
  it independently.

### Logger factory contract

- **loggable-requirement**: the contract's sole requirement MUST be a
  type-level `logger` value, obtainable without regard to any particular
  concurrency context.
- **loggable-default-subsystem**: the default `subsystem` MUST equal the
  app's bundle identifier, or the literal string `"nil"` when none is
  available.
- **loggable-default-category**: the default `category` MUST equal the
  conforming type's own name, with any trailing type-metadata suffix
  removed.
- **loggable-instance-forwarding**: the default instance-level `logger`
  MUST forward to the type-level `logger` — an instance and its type MUST
  expose the identical logger value.
- **loggable-factory**: the factory MUST return a structured logger
  constructed from `subsystem` and `category`.
- **loggable-default-members-isolation**: only the contract's `logger`
  requirement carries an explicit concurrency-context annotation; the
  default `subsystem`, `category`, instance `logger`, and factory members
  carry no isolation annotation of their own and so inherit whatever
  isolation, if any, applies at each call site.

### Float clamping

- **float-clamped-shape**: clamping a floating-point value to a closed
  range MUST return the value unchanged when it already lies within the
  range, MUST return the range's lower bound when it is below it, and MUST
  return the range's upper bound when it is above it.
- **float-clamped-degenerate-range**: when the range's lower and upper
  bounds are equal, clamping MUST return that single value for every
  possible input.
- **float-clamped-pure**: clamping MUST have no side effects and MUST
  depend only on the input value and the range — it MUST NOT read or
  mutate any external state.

### Semantic version parsing

- **semver-shape**: a semantic version MUST be a value type holding
  `major`, `minor`, and `patch` integer components, and MUST support
  equality, hashing, ordering comparison, and a human-readable description.
- **semver-parse-forms**: parsing MUST accept a string of one, two, or
  three dot-separated numeric components (`"1"`, `"1.74"`, `"1.74.0"`),
  MUST accept an optional leading `"v"`, and MUST default any component
  missing from a short form to `0`.
- **semver-parse-rejects-invalid**: parsing MUST return nothing for a
  string carrying a prerelease suffix (`"1.74.0-rc.1"`), build metadata
  (`"1.74.0+build"`), non-numeric text (`"abc"`), the empty string, or a
  non-numeric component (`"1.x.0"`).
- **semver-component-bound**: parsing MUST return nothing when any parsed
  component exceeds 2,147,483,647 (the largest 32-bit signed integer), and
  MUST accept a component exactly equal to that ceiling.
- **semver-ordering**: ordering comparison MUST order strictly by `major`,
  then `minor`, then `patch`, as numeric integer comparisons — it MUST NOT
  compare components as strings (`"9"` MUST sort before `"10"`).
- **semver-description-round-trip**: the description MUST render as
  `"major.minor.patch"`, and parsing that description MUST equal the
  original value for every value the type can represent.

### Text folding

- **text-folding-normalization**: folding a string MUST fold both case and
  diacritics, so that two strings differing only in letter case or in
  diacritical marks MUST fold to the same result (`folded("CAFÉ") ==
  folded("cafe")`).
- **text-folding-locale-independence**: folding MUST be locale-independent
  rather than using the current locale, so its result MUST NOT vary with
  the current locale (for example, it MUST fold identically whether the
  current locale is Turkish or U.S. English).
- **text-folding-empty-input**: folding `""` MUST return `""`.
- **text-folding-pure**: folding MUST have no side effects and MUST depend
  only on its input string.

