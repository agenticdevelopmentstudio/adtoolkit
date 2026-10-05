
- **Null/empty input**: An empty selected plugin identifier MUST make the
  chat-backend adapter's readiness false and MUST make loading that (empty)
  identifier's plugin fail, which the adapter maps to a plugin-not-available
  error (see chat-backend-no-plugin). An empty legacy selection MUST leave
  the plan's selected id at "" (see migration-selected-id). Empty resolved
  configuration values MUST still build a valid, empty configuration bag for
  the plugin — an empty config bag is passed to the plugin unmodified;
  validating it is the plugin's concern, not this component's.
- **Null/empty input**: The MCP tool source decoding empty or malformed tool
  arguments MUST NOT throw — the permissive decode swallows the failure and
  passes no arguments to the underlying MCP call (see
  mcp-tool-source-argument-validation and its Design Decision).
- **Boundary values**: The tool-calling chat session's iteration cap (8) is
  a hard cap. On the 8th iteration, if the model still returns tool-use
  events, the outer loop MUST still end after that iteration completes —
  there is no 9th plugin call, and no explicit signal to the UI that the cap
  was hit (see local-session-tool-loop-bound).
- **Concurrent access**: Sending a message to the tool-calling chat session
  while a turn is active MUST be dropped, not queued
  (local-session-send-busy-guard). The chat-backend adapter's subscriber list
  MUST only ever be mutated under its lock, so concurrent
  readiness-change-stream/notify calls from different execution contexts
  MUST NOT corrupt the registry (chat-backend-conformance). The
  per-configuration store, migration, default-seeding, resolver, and legacy
  per-plugin config store are all confined to a single execution context, so
  an attempt to call them from outside that context is rejected outright —
  no runtime race is possible for those types.
- **Concurrent access**: A new readiness-change subscriber's "seed" value
  (computed asynchronously right after registration) and a concurrent notify
  call MAY race; the subscriber is guaranteed at least one yield of a
  readiness value, but the relative order between the seed and a concurrent
  notify SHOULD NOT be relied upon.
- **Error states**: A failure from the plugin manager's load operation (any
  of its distinct failure reasons) MUST surface identically as a
  plugin-not-available error from the chat-backend adapter — the specific
  failure reason is not preserved (chat-backend-no-plugin). A failure from
  building a request or from the plugin transport MUST surface as a
  turn-failed event (always marked retryable) in the tool-calling chat
  session, or as the stream's thrown error unchanged in the chat-backend
  adapter — in both cases the tool-calling chat session always reports the
  failure as retryable, regardless of whether the underlying cause is
  transient (a timeout) or permanent (a misconfigured plugin). The
  chat-backend session wrapper's analogous catch block does the same.
- **Error states**: The MCP tool source MUST convert any thrown MCP error
  into a result of "Tool error: <description>" marked as an error, never
  propagating the original error type to the model
  (mcp-tool-source-error-mapping).
- **Offline/disconnected state**: None of the given sources perform network
  I/O directly — that is the plugin transport's responsibility. From this
  component's perspective, a network failure (unreachable host, timeout, a
  non-2xx response) MUST surface through the same generic error path as any
  other thrown error: the tool-calling chat session's turn-failure path and
  the chat-backend adapter's stream-failure path — neither distinguishes an
  offline/unreachable failure from any other kind of error.
- **Offline/disconnected state**: The MCP tool source re-fetches the
  registry's tools on every call; if the MCP server for a previously-listed
  tool has disconnected between listing tool definitions and calling a tool,
  the tool is simply absent from the re-fetched pairs and the call MUST
  return a result of "Unknown tool: <name>" marked as an error — identical
  to a tool that never existed.

