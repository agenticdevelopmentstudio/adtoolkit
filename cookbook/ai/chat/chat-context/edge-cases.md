
- **Empty `messages` list**: constructing a chat context MUST NOT reject an
  empty message list; nothing in this contract requires a non-empty
  history. What a plugin's request-building step does with zero
  conversation turns is outside this contract's scope.
- **Empty `model` string**: constructing a chat context MUST NOT reject
  `model: ""`; this contract performs no content validation on `model`.
- **`maxTokens` non-positive**: constructing a chat context does not
  reject `0` or a negative `maxTokens`; there is no lower-bound check, and
  every plugin currently implemented forwards `context.maxTokens` verbatim
  into its provider's request body with no clamping either (see Platform
  Notes for which plugins), so a non-positive value reaches the network
  layer unvalidated. Per the Design Decisions section below, this is
  deliberate: `maxTokens` is treated as an opaque budget number, and
  enforcing a floor is left to the request-building step or a downstream
  layer, not to this contract.
- **Plugin configuration with an empty value dictionary**: `apiKey`,
  `baseURL`, `model`, and the keyed lookup MUST all return nothing for any
  key, since an empty dictionary returns nothing for every lookup.
- **Plugin configuration lookup with an unrecognized key**: MUST return
  nothing; the lookup is a direct dictionary read with no fallback or
  default.
- **Tool specification's `parametersJSONSchema` containing non-JSON or
  malformed bytes**: constructing a tool specification MUST NOT reject it;
  this contract performs no validation that the raw bytes it carries are
  well-formed JSON — despite the field's name, it is treated as an opaque
  byte buffer. Any parsing or validation happens in the plugin that reads
  it.
- **Chat message with inconsistent tool fields** (e.g., `toolArgumentsJSON`
  set but `toolName` and `toolUseId` both absent, or `role == toolResult`
  with all four tool fields absent): constructing a chat message MUST NOT
  reject any such combination; this contract ties no field to any other,
  or to `role`, by validation.
- **Concurrent access**: the chat message, the tool specification, the
  plugin configuration, and the chat context are all unchangeable and safe
  to share across concurrency boundaries; the same instance MAY be read
  from multiple points of execution concurrently with no synchronization,
  and no shared mutable state exists in this contract to race on. A new
  instance is expected to be constructed per request rather than mutated
  and reused.
- **Error states from a dependency**: Not applicable — this contract has
  no dependency (no network, database, or file-system call) to fail; a
  swallowed error or an unreachable server is a concern of the resulting
  request description or the host's transport, not this contract.
- **Offline or disconnected state**: Not applicable — this contract
  performs no network access of its own; connectivity loss mid-request is
  a concern of the host's transport layer, driven over a network
  connection or a subprocess, not this data.
- **Cancellation and timeouts**: Not applicable — the chat context carries
  no cancellation token and no timeout of its own (timeout lives on the
  sibling request-description type, not here); cancelling or timing out
  the underlying request is the host's responsibility.

