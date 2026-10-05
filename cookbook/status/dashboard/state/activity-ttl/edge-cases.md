
- **Empty stored key**: If reading the stored value for `"adh-healthy-ttl"` returns nothing, this logic MUST keep the default and not attempt to parse it.
- **Malformed JSON in storage**: If the stored value is valid JSON but not a recognized structure (e.g., `"adh-healthy-ttl": "string"` or `"adh-healthy-ttl": {}`), this logic MUST reject it and keep the default.
- **Out-of-range number**: If a number outside the selectable set is stored (e.g., `50` or `120`), this logic MUST reject it and keep the default.
- **Type narrowing after parse**: After parsing, the value's type is not yet known; this logic MUST check both its type and its membership in the valid set before accepting it.
- **Durable storage unavailable**: If the runtime's durable storage is unavailable (e.g., private browsing, blocked), both read and write operations MUST catch and ignore the failure.
- **Quota exceeded on write**: If the durable-storage write fails due to quota, the state change MUST proceed in-memory and this logic MUST not propagate the error.
- **Rapid setTtl calls**: Multiple `setTtl` calls in quick succession MUST each attempt to persist; if some writes fail, others MAY succeed independently.
- **Teardown before hydration**: If the hook instance is torn down before hydration runs, no state update attempt MUST occur (the runtime's cleanup handles this).

