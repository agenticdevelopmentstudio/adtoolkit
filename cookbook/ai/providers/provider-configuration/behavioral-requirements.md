
- **identifier-assignment**: Constructing a configuration MUST assign `id` from an optional argument, generating a fresh random identifier when the caller omits it.
- **identifier-immutability**: `id` MUST NOT change after construction.
- **stable-identity**: The configuration MUST expose `id` directly as its primary identity, with no separate computed value or indirection, so it can be used as the key when rendering a list of configurations.
- **display-name-mutability**: `name` MUST be assignable after construction, so a caller MAY rename a configuration in place without constructing a new value and without changing `id`, `pluginIdentifier`, or `templateId`.
- **plugin-and-template-identity-immutability**: `pluginIdentifier` and `templateId` MUST NOT change after construction.
- **no-content-validation**: Construction MUST accept any string value, including an empty string, for `name`, `pluginIdentifier`, and `templateId`; no format, length, or non-empty check is performed on any of the three.
- **json-round-trip**: A configuration, or an array of configurations, MUST encode to and decode from JSON using its four fields (`id`, `name`, `pluginIdentifier`, `templateId`) directly, with no custom coding logic.
- **concurrency-safe**: A configuration value MUST be safe to share across threads or concurrent tasks with no additional guard; every field it stores is itself safe to share this way, and the configuration performs no synchronization of its own.
- **value-equality**: Two configurations MUST compare equal only when `id`, `name`, `pluginIdentifier`, and `templateId` all match; two otherwise-identical configurations that differ only in `id` MUST compare unequal.
- **value-hashing**: Two configurations that compare equal (per value-equality) MUST hash identically, so configurations MAY be used as set elements or map keys.
- **value-semantics**: A configuration MUST behave as a copied value, not a shared reference: assigning or passing one MUST copy it, and mutating one copy's `name` MUST NOT affect any other copy or any previously encoded representation.
- **no-persistence**: A configuration MUST NOT read from or write to any settings store, secure storage, a file, or a network endpoint itself; a configuration's field values, selected model, and secrets are persisted elsewhere, keyed by `id`.
- **no-registry-validation**: Construction, decoding, and comparison MUST NOT verify that `pluginIdentifier` or `templateId` refers to a currently installed, resolvable plugin or template; the configuration consults no plugin registry (see Design Decisions).
- **unique-name-unchanged-when-free**: Deriving a unique name from a candidate MUST return the candidate unchanged when the taken set does not contain it.
- **unique-name-suffix-on-collision**: Deriving a unique name MUST return `"<candidate> 2"` when the taken set contains the candidate but not `"<candidate> 2"`.
- **unique-name-suffix-increments**: When the taken set also contains `"<candidate> 2"`, deriving a unique name MUST try successive suffixes 3, 4, … in order, returning the first candidate `"<candidate> <suffix>"` that the taken set does not contain.
- **unique-name-static-purity**: Deriving a unique name MUST have no side effect; it MUST derive its result solely from the candidate name and the taken set, returning the identical result for the identical arguments on every call, with no dependency on any configuration instance or external store.

