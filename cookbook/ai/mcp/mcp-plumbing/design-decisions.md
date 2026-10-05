
All four decisions below are specific to the Apple/Swift reference implementation; see Platform Notes for how another platform would reproduce the same guarantees.

**Decision**: `teardown()` disconnects the transport and the underlying `MCP.Client` twice each (steps 2+5 and 3+6), rather than once.
**Rationale**: Per `MCPClient.swift`'s own doc comment on `teardown()`, the first pair (steps 2-3) closes the window `MCP.Client.send`'s unstructured registration opens for a request that is mid-flight when a disconnect lands, while the second pair (steps 5-6) reaps a connect that resumes *after* steps 1-3 have already run out of things to catch — a connect suspended between publishing `self.transport` and calling `MCP.Client.connect(transport:)`. Both `SubprocessTransport.disconnect()` and `MCP.Client.disconnect()` are documented no-ops when already idle, so the repeated calls cost nothing in every ordering except the one each pair exists for.
**Approved**: pending

**Decision**: `teardown()`'s wait for an abandoned `connectTask` (step 4) is bounded to `abandonedConnectBudgetSeconds` (1.0 second) and both the operation's own error and a `WallClockBudgetExceeded` are discarded with `try?`.
**Rationale**: Per the source's own measurements cited in its doc comment, an unbounded wait here never returns for a connect wedged on the MCP SDK's bare `initialize` continuation, because nothing but step 6's `client.disconnect()` can resume it — and step 6 only runs after this wait ends. A bounded wait trades a fixed, small delay (measured at roughly 1.01-1.03 seconds end to end) for guaranteeing steps 5 and 6 run; propagating either the operation's error or the budget's own timeout error would serve no caller, since `teardown()`'s job is releasing resources, not reporting the abandoned connect's outcome.
**Approved**: pending

**Decision**: `SubprocessTransport` tracks `idle`/`connecting`/`connected` as a three-case enum rather than a `Bool`.
**Rationale**: Per the type's own doc comment, a `Bool` set only after `connect()`'s suspension at `channel.launch()` would let a `disconnect()` landing in that window observe "not yet connected" and become a no-op while a live child exists — stranding it for the life of the app. The `connecting` case exists precisely to make `disconnect()` treat that window the same as a fully connected one.
**Approved**: pending

**Decision**: `HostMCPServer` is self-contained, with no integration into `MCPServerRegistry` and no new case added to `MCPServerConfiguration.Transport` for an in-process server.
**Rationale**: Per the type's own doc comment, this keeps the sample from expanding the `Transport` enum with an in-process variant; a host application that wants `HostMCPServer`'s tools available to its own chat surface is expected to build an `MCP.Client` directly against `clientTransport` and wire that in wherever it already routes tool calls, rather than this component doing so on the host's behalf.
**Approved**: pending

**Decision**: A failed tool-list refresh after a list-changed notification is silent.
**Rationale**: The handler discards the refresh error, leaving the previously cached tools in place with no log, state change or retry; closing the gap needs a decision from whoever owns the client's error-reporting contract on whether a failed refresh should log or mark the client failed.
**Approved**: pending

