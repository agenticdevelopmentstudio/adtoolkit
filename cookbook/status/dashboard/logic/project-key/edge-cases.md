
- **Empty input list**: The de-duplication function on an empty list MUST return an empty list.
- **Empty field values**: The key function MUST produce `"|"` for empty `platform` and `projectName`; two such entries MUST collapse to one under the de-duplication function.
- **Separator inside a field**: The key is a plain concatenation with no escaping, so an entry with platform `"a|b"`/projectName `"c"`, and an entry with platform `"a"`/projectName `"b|c"`, MUST both produce the key `"a|b|c"` and MUST collapse together. Collision requires a platform identifier containing `|`; platforms come from the backend's fixed platform set, so this is a documented limitation rather than an expected input.
- **Case-variant platforms**: Entries whose platform differs only in case (for example `Railway` vs `railway`) MUST be treated as distinct projects, because the raw platform is keyed deliberately.
- **Single entry**: A single-entry input MUST be returned unchanged as a one-element list.
- **All duplicates**: An input where every entry shares one key MUST reduce to a one-element list holding the first entry.
- **Backend order not production-first**: If the input lists a non-production environment first, the kept entry MUST be that non-production entry; the logic performs no correction.
- **Malformed input at runtime**: The functions rely on the expected shape for validation, not enforcement. An entry whose `platform` or `projectName` is absent at runtime MUST still produce a key via the same concatenation rule (for example yielding something like `"undefined|api"`, depending on how the runtime renders an absent value as text); no runtime validation or exception occurs.
- **Concurrent access**: Not applicable — both functions are synchronous and run to completion without yielding, and the de-duplication function allocates its seen-key tracking per call, so calls cannot interleave.
- **Error states and offline**: Not applicable — the logic performs no I/O and has no dependencies that can fail or disconnect.

