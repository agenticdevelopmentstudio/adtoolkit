
The client's error and connection-state types

- **client-disconnected-error-message**: The client's "already disconnected" error MUST provide the human-readable description "The MCP server was disabled or removed before its connection finished starting; nothing was launched." — an error with no explicit description otherwise reads as an opaque, generic failure message in every logger and alert that consumes it.
- **client-state-shape**: The client's connection state MUST be one of exactly four values — disconnected, connecting, connected, failed (carrying a message) — and MUST support equality comparison and safe use across concurrent contexts.

The client protocol

- **client-protocol-surface**: Any implementation of the client protocol MUST serialize its own operations so concurrent calls resolve deterministically, and MUST expose `id` and `name` as immediately readable without waiting on that serialization, plus a readable connection state and cached tool list. It MUST support exactly four operations: connect, disconnect, refresh the tool list, and call a tool by name with arguments — returning the tool's content and an error flag.

The client

- **client-identity**: The client's `id` and `name` MUST be taken from the server configuration's own `id` and `name` at construction and MUST NOT change for the life of the instance.
- **client-initial-state**: A newly constructed client MUST report a disconnected state and an empty cached tool list before connecting is ever attempted.
- **connect-guard-is-first**: Connecting MUST check whether the client has already been shut down as its first action, before doing anything else, and MUST throw the "already disconnected" error without doing anything else when disconnecting has already completed on this instance.
- **connect-runs-in-held-task**: Connecting MUST mark itself connecting, then run the connection-establishment work as a separately tracked, cancellable operation rather than inline, so that a concurrent teardown has a specific operation to cancel and wait for.
- **connect-success-transition**: On success, connecting MUST stop tracking that operation only if it is still the one that just finished, and MUST advance the state to connected only if the state is still connecting at that point — a teardown that ran to completion while this connect was suspended MAY have already reset both, in which case connecting MUST return successfully anyway while the state reads disconnected and the client owns no transport.
- **connect-failure-transition**: On failure, connecting MUST stop tracking that operation under the same guard, MUST set the state to failed (carrying the error) only if the state is still connecting, MUST tear down before returning, and MUST rethrow the original error.
- **establish-connection-order**: Establishing a connection MUST, in order: check for cancellation, build the transport and store it, connect the underlying MCP client to that transport, register the tool-list-changed notification handler, then refresh the tool list.
- **disconnect-is-terminal**: Disconnecting MUST mark the client as permanently shut down before doing anything else, MUST never clear that mark, MUST tear down, and MUST leave the state disconnected afterward — a later attempt to connect the same instance MUST throw rather than starting a second server; reconnecting requires constructing a new client.
- **teardown-sequence**: Tearing down MUST perform, in this exact order: (1) cancel the tracked connect operation, if any; (2) disconnect the transport, if one exists; (3) disconnect the underlying MCP client; (4) if the connect operation is still tracked, wait for it to finish under a fixed wall-clock budget, discarding both its own error and a budget-exceeded error, then cancel it again and stop tracking it; (5) disconnect the transport again and release it; (6) disconnect the underlying MCP client again. Each of the two repeated calls MUST run even though the first of its pair may already have been a no-op, because the ordering that makes step 4's wait bounded is exactly the ordering steps 2 and 3 cannot reach.
- **abandoned-connect-budget-value**: The wall-clock budget teardown gives an in-flight connect operation MUST be `1.0` seconds, and it MUST NOT be configurable per instance.
- **teardown-error-suppression**: An error thrown by the awaited connect operation in step 4 of teardown-sequence, or a budget-exceeded error from the budget itself, MUST NOT propagate out of tearing down — both MUST be discarded.
- **transport-selection**: Building the transport MUST produce a subprocess transport for a `.stdio` configuration and an HTTP client transport for a `.http` configuration.
- **secrets-override-environment**: For a `.stdio` transport, the child's environment MUST be the configuration's own environment merged with the client's secrets, with a key present in both resolving to the secret's value.
- **stdio-transport-configuration**: The subprocess transport built for a `.stdio` server MUST configure its channel to merge the child's environment over the host process's own (so the child still inherits `PATH`/`HOME`) and to frame messages as newline-delimited.
- **tool-list-changed-refresh**: The client MUST register a handler for the tool-list-changed notification that refreshes the tool list whenever the server emits that notification.
- **refresh-tools-replaces-cache**: Refreshing the tool list MUST call the underlying MCP client's list-tools operation and MUST replace the cached tool list with the result in full (not merge or append).
- **call-tool-forwards-and-defaults-error-flag**: Calling a tool MUST forward the tool's name and arguments to the underlying MCP client's call-tool operation and MUST return its content plus an error flag — a missing error flag from the server MUST be treated as `false`.
- **client-serializes-operations**: The client MUST serialize every one of its operations onto a single execution context, so its connection state, cached tool list, tracked connect operation, shutdown flag, and transport are never touched concurrently and every external call resolves deterministically; only `id` and `name` are exempt from that serialization, since they never change after construction and are safe to read at any time.
- **connect-suspension-hook-is-nil-in-production**: The connect-suspension test hook MUST default to none and MUST be settable only through a method reserved for test code; with no hook installed, the two checkpoints inside establishing a connection MUST cost exactly one nil check each and MUST NOT suspend.

The server configuration

- **configuration-shape**: The server configuration MUST be persistable, safely shared across concurrent contexts, uniquely identifiable, and comparable for equality, and MUST expose an immutable `id`, a `name`, a `transport`, and an `isEnabled` flag.
- **configuration-transport-shape**: The configuration's transport MUST be one of exactly two shapes — a stdio launch (a command, its arguments, and environment variables) or an HTTP endpoint (a URL and whether it streams) — and MUST be persistable, safely shared across concurrent contexts, and comparable for equality.
- **configuration-default-id**: Constructing a server configuration MUST generate a fresh, unique `id` when the caller does not supply one, and MUST default `isEnabled` to `true`.
- **configuration-id-is-stable**: Changing `name`, `transport`, or `isEnabled` on a value with a given `id` MUST NOT change that value's `id`.
- **configuration-equality-covers-all-fields**: Two server configurations MUST compare equal only when `id`, `name`, `transport`, and `isEnabled` all match, and MUST compare unequal if any one field differs.
- **configuration-secrets-live-elsewhere**: The server configuration MUST carry no secret material of its own — secret environment values for a server MUST be looked up separately, keyed by the configuration's own `id`, from the server-secrets setting.

The settings

- **server-secrets-shape**: The server-secrets setting MUST map a server's `id` to that server's own environment-variable overrides, keyed by variable name.
- **configurations-setting-routing**: The list of server configurations MUST be declared with key `"mcp.serverConfigurations"`, default to an empty list, and MUST NOT be marked as secure, so it routes to the regular (non-secure) settings storage provider.
- **secrets-setting-routing**: The server-secrets setting MUST be declared with key `"mcp.serverSecrets"`, default to empty, and MUST be marked secure, so it routes to the secure storage provider (Keychain in production) and never reaches the regular settings file.

The registry

- **registry-publishes-clients-on-main-thread**: The registry MUST run on the main thread of execution and MUST publish its live map of clients (keyed by server id) reactively, so observers see every add and remove.
- **registry-clients-mirror-enabled-configurations-only**: The live client map MUST contain an entry only for a configuration whose `isEnabled` is `true`; a disabled or absent configuration's `id` MUST NOT appear as a key.
- **registry-subscribes-to-settings-changes**: Constructing the registry MUST observe both the server-configurations setting and the server-secrets setting together, and MUST reconcile the live client set against the latest values on every change to either one.
- **registry-reconcile-removes-first**: Reconciling MUST, for every `id` currently tracked that is not in the newly enabled set, remove that `id` from the live map immediately and begin disconnecting that client independently, without waiting for the disconnect to finish before reconciling itself returns.
- **registry-reconcile-adds-missing**: For every enabled configuration whose `id` is not already tracked, reconciling MUST look up that server's secrets (or none, if absent), create a client for it, store it in the live map under that `id`, and begin connecting it independently, without waiting for the connection to finish before reconciling itself returns.
- **registry-connect-failure-is-logged-not-thrown**: If the connection attempt started in registry-reconcile-adds-missing fails, reconciling MUST catch the error and log it, interpolating the configuration's `name` and the error's description as public log data, and MUST NOT remove the client from the live map or rethrow.
- **registry-default-client-factory**: The client factory MUST default to constructing a real client from a server configuration and its secrets; a caller (test or otherwise) MAY substitute a different factory when constructing the registry.
- **registry-tools-for-ids**: `tools(forIds:)` MUST, for each `id` in the given set, skip any `id` with no entry in the live map, and otherwise await that client's cached tool list and append one (client, tool) pair per cached tool; the result MUST include every cached tool from every matching client and MUST NOT include tools from a client whose `id` is absent from `ids`.

The subprocess transport

- **subprocess-transport-conforms-to-mcp-transport**: The subprocess transport MUST serialize its own operations and MUST conform to MCP's own Transport contract, built over this codebase's shared subprocess-channel abstraction rather than the MCP SDK's own stdio transport.
- **subprocess-transport-default-logger-is-noop**: The subprocess transport MUST default its logger to a no-op logger when the caller supplies none, matching the stock stdio transport's own default, so every JSON-RPC frame of every MCP server is not logged by default.
- **subprocess-transport-three-state**: The subprocess transport MUST track its lifecycle as one of exactly three states — idle, connecting, connected — rather than a simple on/off flag, because there is a window after launching the channel and before connecting resumes in which a live child exists that only terminating can reap.
- **subprocess-connect-is-idempotent**: Connecting MUST be a no-op when called while the state is already connecting or connected; a second, concurrent call MUST return immediately without waiting for the first call and MUST NOT spawn a second child process.
- **subprocess-connect-order**: A connect that proceeds MUST mark itself connecting before doing anything else, then launch the channel; on failure it MUST reset to idle and rethrow without spawning a forwarding operation. On success it MUST re-check that it is still connecting (returning early otherwise) before opening the channel's message stream, and MUST re-check that it is still connecting a second time (returning early otherwise) before marking itself connected and starting the forwarding operation — both re-checks exist because a disconnect may land in either suspension.
- **subprocess-blank-line-filtering**: The forwarding operation MUST discard any frame for which every byte is one of LF (`0x0A`), CR (`0x0D`), space (`0x20`), or tab (`0x09`) — including an empty frame — and MUST NOT yield it into the message stream; every other frame MUST be yielded unmodified, with its trailing delimiter byte intact.
- **subprocess-disconnect-is-idempotent**: Disconnecting MUST be a no-op when already idle; otherwise it MUST mark itself idle, terminate the channel, wait for the forwarding operation's completion, stop tracking that operation, and unconditionally close the message stream once more as a safety net.
- **subprocess-send-requires-connected-state**: Sending MUST throw a "not connected" transport error when the state is not connected — sending before connecting or after disconnecting MUST fail with that specific error, matching the stock stdio transport's contract byte for byte — and otherwise MUST forward the framed data to the channel.
- **subprocess-receive-returns-stable-stream**: Receiving events MUST return the same underlying stream instance on every call, not a new stream per call.

The host MCP server

- **host-server-runs-on-main-thread**: The host MCP server MUST run on the main thread of execution.
- **host-server-wires-in-memory-pair**: Constructing the host MCP server MUST create a connected in-memory transport pair, expose the client side publicly, and retain the server side privately.
- **host-server-declares-no-list-changed**: The underlying MCP server MUST declare that it does not support the tools-list-changed capability — this server MUST NOT claim it will emit `tools/list_changed`.
- **host-server-start-and-stop**: Starting MUST register the tool handlers and then start the underlying MCP server against its own transport; stopping MUST stop that server.
- **host-server-lists-two-tools**: Listing tools MUST return exactly two tools, `host_app_info` and `host_open_chat_window`, each declaring an object input schema with no properties.
- **host-app-info-tool-body**: Calling `host_app_info` MUST return non-error text containing the app's name, its version, and its plugin names joined by `", "`, or the literal `(none)` when there are no plugin names.
- **host-open-chat-window-tool-effect**: Calling `host_open_chat_window` MUST invoke the callback supplied when the host MCP server was constructed and MUST return the fixed non-error text "Opened a new chat window."
- **host-server-unknown-tool-is-not-an-error-throw**: Calling any tool name other than the two declared tools MUST return a result with an error flag set and text "Unknown tool: <name>" — it MUST NOT throw.
- **host-server-ignores-tool-arguments**: The tool handlers MUST NOT read the call's arguments — both declared input schemas have no properties and no handler inspects the arguments given, so any arguments a caller supplies are accepted and ignored.

