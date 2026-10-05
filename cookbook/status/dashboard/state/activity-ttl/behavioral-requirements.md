
- **initialization**: This logic MUST initialize to a default of 60 minutes on first render, before hydration completes.
- **supported-values**: The selectable values are 1, 15, 30, or 60 minutes, plus no value at all (indefinite retention). Only hydration enforces this set; `setTtl` stores and persists whatever number it is given, so callers MUST pass one of these values.
- **persistence-key**: This logic MUST persist the user's choice to durable browser storage under the key `"adh-healthy-ttl"` as a JSON-serialized value.
- **hydration**: This logic MUST hydrate the stored value from durable browser storage once, after the initial render, and not again.
- **null-as-stored-value**: This logic MUST correctly deserialize a stored `null` (indefinite retention) as a real, present choice, not treat it as "no stored value".
- **invalid-value-rejection**: If the stored value is not `null` and not one of the selectable minute values, this logic MUST ignore it and retain the default.
- **parse-error-handling**: If parsing the stored JSON fails, this logic MUST silently catch the failure and retain the current state.
- **persistence-error-handling**: If writing to durable browser storage fails, this logic MUST silently catch the failure and leave the in-memory value intact.
- **return-shape**: This logic MUST return an object with exactly three fields: `ttlMin` (the stored value in minutes, or `null`), `ttlMs` (the value in milliseconds, or `null` if `ttlMin` is `null`), and `setTtl` (a callback).
- **setTtl-signature**: The `setTtl` callback MUST accept a number from the selectable set or `null`, update in-memory state immediately, and attempt to persist to durable browser storage.
- **ttlMs-calculation**: This logic MUST convert `ttlMin` to `ttlMs` by multiplying by 60,000 (milliseconds per minute), or return `null` if `ttlMin` is `null`.
- **ssr-hydration-match**: This logic MUST ensure the initial render (before hydration runs) shows the default, preventing mismatches between a server-rendered first paint and the client (see Platform Notes).
- **client-only**: Activity TTL MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

