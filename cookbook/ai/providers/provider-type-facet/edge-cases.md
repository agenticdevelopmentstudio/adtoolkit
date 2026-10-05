
- **Empty Config Type string**: Bucketing `""` MUST resolve to `custom`, since the lowercased empty string satisfies none of the six matched substrings (provider-type-facet-002).
- **Multiple rules satisfied at once (boundary of the matching rules)**: A Config Type string satisfying more than one rule's substring test MUST resolve via the fixed evaluation order subscription, then local, then apiKey, then custom; no input can reach a later rule once an earlier one has matched (provider-type-facet-003, provider-type-facet-008).
- **Unrecognized wire value**: A wire-value lookup given a string that is not one of the four case names MUST return no result rather than crash or default to a case (provider-type-facet-007).
- **Malformed JSON during decode**: Decoding a JSON string that is not `"subscription"`, `"apiKey"`, `"local"`, or `"custom"` MUST fail with a decoding error, since decoding is implemented in terms of the wire-value lookup and fails whenever that lookup returns no result.
- **Concurrent access**: Because the facet is a case-only value with no stored mutable state, calling the matching function or the bucketing operation concurrently from multiple threads or execution contexts MUST be safe with no synchronization, since neither function reads or writes shared state.
- **Error states from a dependency**: Not applicable — this concept has no dependency (no network, database, or file-system call) of its own to fail; bucketing is a pure string transform over a value already resolved by the descriptor's Config Type display logic.
- **Offline or disconnected state**: Not applicable — this concept performs no network access of its own.
- **Cancellation and timeouts**: Not applicable — every operation is synchronous and non-throwing; there is no asynchronous or long-running operation to cancel or time out.

