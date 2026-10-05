
### Plugins Coordinator

- **coordinator-identity**: Constructing a plugins coordinator MUST register
  it with the app's shared feature registry as a side effect of construction,
  and it MUST be confined to a single execution context.
- **coordinator-plugin-manager**: Creating a plugins coordinator with an app
  name and additional search paths MUST construct exactly one plugin manager
  (exposed as its public plugin-manager reference) scoped to that app name
  and those search paths.
- **coordinator-startup-order**: Constructing a plugins coordinator MUST run,
  in order: discovery on the plugin manager, then migration-if-needed, then
  default-seeding-if-needed — migration and default seeding both read the
  plugin manager's discovered descriptors and available templates, which are
  empty until discovery has run.
- **coordinator-settings-panel**: Requesting the settings panel MUST return a
  freshly constructed settings panel view built from the coordinator's plugin
  manager.

### Chat Configuration Provider (interface)

- **config-provider-shape**: A chat configuration provider MUST expose a
  selected plugin identifier (text), a selected model (text), and resolved
  configuration values (a text-keyed map of text) as read-only properties
  confined to a single execution context.
- **config-provider-resolved-values**: Resolved configuration values MUST be
  the already-resolved key/value map a plugin reads as its configuration bag,
  secrets included — the consuming chat backend MUST NOT read secure storage
  or any settings store itself.

### Chat-Backend Adapter

- **chat-backend-conformance**: The chat-backend adapter MUST conform to the
  chat-backend interface and MUST be declared safe for concurrent use through
  its own explicit synchronization rather than confinement to a single
  execution context; every access to the plugin manager or its configuration
  provider MUST happen by hopping onto that context, and every mutation of
  its subscriber list MUST happen while holding its lock.
- **chat-backend-weak-provider**: The chat-backend adapter MUST hold its
  configuration provider weakly; when it has been deallocated, readiness, the
  readiness-change stream, notifying of a readiness change, and sending
  messages MUST treat the missing provider as an empty selected plugin
  identifier, an empty selected model, and empty resolved configuration
  values.
- **chat-backend-is-ready**: Readiness MUST be true if and only if the
  configuration provider's selected plugin identifier is non-empty; an empty
  string or a missing provider MUST yield false.
- **chat-backend-ready-changes**: Subscribing to readiness changes MUST
  return an independent stream per call; each stream MUST yield the current
  readiness value once for its new subscriber (computed asynchronously right
  after subscription) and MUST yield again whenever a readiness change is
  signaled while the subscriber is still registered.
- **chat-backend-notify**: Signaling a readiness change MUST recompute
  readiness once and multicast that single value to every currently-registered
  subscriber; it MUST cost nothing beyond that (no recomputation broadcast to
  nobody) when there are no subscribers, and it is the host's responsibility
  to call it after a plugin- or credential-selection change — the adapter
  MUST NOT observe those changes on its own.
- **chat-backend-deinit-cleanup**: When the adapter is torn down, it MUST
  finish every still-registered subscriber's stream and clear its subscriber
  list, under its lock.
- **chat-backend-send-messages-text**: Sending messages (text-only form) MUST
  build one chat request context from the current configuration-provider
  snapshot and an empty tool list, run it through the plugin transport, and
  MUST forward only text-delta payloads into the returned stream of text
  chunks — tool-use and end events from the underlying stream MUST be dropped
  for this form.
- **chat-backend-send-messages-tools**: Sending messages (with tools) MUST
  map every decoded stream event 1:1 onto a chat-backend stream event (a
  text-delta event stays a text-delta event; a tool-use event carrying an id,
  name, and arguments-JSON stays a tool-use event with the same fields; an
  end event carrying a stop reason stays an end event with the same field)
  with no other transformation.
- **chat-backend-cancellation**: Cancelling either returned stream's
  consuming task MUST cancel the backing unit of work created to drive the
  request.
- **chat-backend-no-plugin**: When the configuration provider's selected
  plugin identifier is empty, or loading the resolved identifier's plugin
  fails, resolving request inputs MUST produce a result whose plugin is
  absent, and the driving logic MUST finish the stream by throwing a
  plugin-not-available error without running the plugin transport at all. The
  three distinct failure reasons the plugin manager's load operation can
  throw (not found, bundle-load failure, missing/invalid principal class) are
  collapsed into that same single plugin-not-available case here — the
  chat-backend adapter does not distinguish them.
- **chat-backend-build-request-failure**: If the resolved plugin's
  request-building operation throws, the driving logic MUST finish the
  stream by throwing that error unchanged (no wrapping), without ever running
  the plugin transport.
- **chat-backend-transport-failure**: If the plugin transport throws while
  iterating, the driving logic MUST propagate that error unchanged as the
  stream's failure.
- **chat-backend-message-mapping**: Mapping a chat-backend message to the
  plugin's message type MUST translate it field-for-field (role, content,
  tool-use id, tool name, tool-arguments JSON, tool-is-error), and mapping a
  tool definition to the plugin's tool-spec type MUST translate it
  field-for-field (name, description, parameters JSON schema) with no content
  transformation.

### Provider Chat Session

- **provider-session-graph**: Creating a provider chat session with a
  configuration and a plugin manager MUST construct, in order, a
  single-configuration provider pinned to that configuration, a chat-backend
  adapter wired to that provider, and a chat view model wrapping a
  chat-backend session built from that adapter.
- **provider-session-lifetime**: A provider chat session MUST hold a strong
  reference to its adapter; since the chat-backend adapter holds its
  configuration provider weakly, this is the only thing that keeps the
  provider object alive for as long as the session exists.

### Per-Plugin Config Store (legacy)

- **plugin-config-store-key-convention**: The per-plugin config store MUST
  be the single place that derives per-plugin setting keys: a field's key
  MUST be `"aiplugin.<identifier>.field.<key>"` and a model's key MUST be
  `"aiplugin.<identifier>.model"`.
- **plugin-config-store-secret-routing**: Building a field's persisted
  setting MUST mark it secure exactly when the field is a secret field — a
  secret field's value MUST be routed to secure storage, and a plain-text
  field's value MUST be routed to the plain store.
- **plugin-config-store-model-default**: Resolving the selected model MUST
  return the stored model value when non-empty, else the descriptor's
  resolved default model.
- **plugin-config-store-config-values**: Resolving configuration values MUST
  return every field's current stored value keyed by the field's key, plus a
  `"model"` entry from the resolved selected model.

### Provider Configuration

- **provider-configuration-identity**: A provider configuration MUST support
  value equality, MUST be serializable for persistence, and MUST have a
  stable unique identifier assigned at creation (defaulting to a freshly
  generated identifier), a mutable name, and immutable plugin-identifier and
  template-id fields.
- **provider-configuration-unique-name**: Deriving a unique name MUST return
  the base name unchanged when it is not already taken; otherwise it MUST
  return `"<base> 2"`, `"<base> 3"`, … — the first suffixed form not already
  taken.

### Provider Settings

- **provider-settings-list**: The provider-configurations list setting MUST
  persist the ordered list of provider configurations under
  `"aiplugin.configurations"`, defaulting to an empty list.
- **provider-settings-selection**: The selected-configuration-id setting
  MUST persist the selected configuration's identifier under
  `"aiplugin.selectedConfigurationId"`, defaulting to `""`; an empty value
  MUST be interpreted by every consumer in this component as "no provider
  selected," not as an invalid reference.
- **provider-settings-guards**: The migration-guard and default-seeding-guard
  settings MUST each persist an independent one-time boolean guard
  (`"aiplugin.migratedToConfigurations"` and `"aiplugin.defaultConfigSeeded"`
  respectively, both defaulting to false) so migration and default-seeding
  are tracked, and can each run at most once, independently of one another.

### Per-Configuration Store

- **config-store-key-delegation**: Deriving a field's or model's setting key
  for a configuration MUST delegate to the shared per-configuration key
  logic, producing `"aiplugin.config.<id>.field.<key>"` and
  `"aiplugin.config.<id>.model"` respectively.
- **config-store-secret-routing**: Building a field's persisted setting MUST
  mark it secure exactly when the field is a secret field.
- **config-store-model-default**: Resolving the selected model for a
  configuration and template MUST return the stored model value when
  non-empty, else the template's resolved default model.
- **config-store-values-overlay**: Resolving configuration values for a
  configuration, template, and field list MUST start from the template's
  default values, then for each field overlay the stored value into the
  result under two conditions: the field is a secret field (always overlaid,
  even when the stored value is empty), or the stored value is non-empty. A
  field that is not secret and whose stored value is empty MUST NOT overwrite
  a template default for that key. The result MUST always include a `"model"`
  entry from the resolved selected model.
- **config-store-seed**: Seeding a configuration from a template and field
  list MUST, for each field that has an entry in the template's default
  values, write that default into the field's stored setting; a field with
  no corresponding template default MUST be left at its setting's own default
  (`""`). It MUST also set the model setting to the template's resolved
  default model.
- **config-store-clear**: Clearing a configuration's stored values MUST reset
  every given field's stored value to `""` and the configuration's model
  setting to `""`; because a secret field's persisted setting is secure,
  writing `""` MUST remove that value from secure storage. Clearing stored
  values MUST accept no template argument, so it remains callable even when
  the configuration's template no longer resolves (a removed plugin or a
  renamed template).

### Default Seeding

- **defaults-guarded-once**: Seeding defaults when needed MUST return
  immediately without side effects once the default-seeded guard is true;
  otherwise it MUST set that guard to true before returning, regardless of
  whether seeding actually produced a configuration.
- **defaults-only-when-empty**: Seeding defaults when needed MUST NOT write
  to the provider-configurations list when that list is already non-empty —
  an existing user- or migration-created list MUST be left untouched.
- **defaults-template-lookup**: Seeding defaults when needed MUST look up a
  template whose id is `"claude-local"` (the default template id) among the
  plugin manager's available templates; when no such template is advertised,
  it MUST leave the provider-configurations list empty.
- **defaults-seeded-configuration**: When the `"claude-local"` template is
  found and the list is empty, seeding defaults when needed MUST build one
  provider configuration named after the template's display name, seed its
  stored field values and model via the per-configuration store's seeding
  logic, and set the provider-configurations list to the single-element list
  containing it.
- **defaults-leaves-unselected**: Seeding defaults when needed MUST NOT set
  the selected-configuration-id setting — the seeded configuration is
  deliberately left unselected so behavior matches the daemon's zero-config
  "Default (Claude CLI)" path exactly.

### Migration

- **migration-plan-is-pure**: Planning a migration from descriptors, a legacy
  selection, and prior values MUST be a pure function of its arguments — it
  MUST perform no I/O and MUST NOT read or write any persisted setting.
- **migration-template-selection**: For each descriptor, planning a
  migration MUST select the template whose id matches that descriptor's
  legacy template id when that lookup succeeds and the descriptor advertises
  a template with that id, else the first entry of the descriptor's resolved
  templates.
- **migration-inclusion-rule**: Planning a migration MUST include a
  descriptor in the output only if at least one of the following holds: (a)
  some secret field has a non-empty legacy value, (b) the descriptor's
  identifier equals the legacy selection and the legacy selection is
  non-empty, or (c) some non-secret field's legacy value is non-empty and
  differs from that field's template default. A descriptor matching none of
  these MUST be skipped entirely — no configuration, field write, or model
  write MUST be produced for it.
- **migration-name-dedup**: Planning a migration MUST name each produced
  configuration via the unique-name derivation from the descriptor's display
  name, avoiding the names already assigned to configurations earlier in the
  same plan.
- **migration-field-write-rule**: For an included descriptor, planning a
  migration MUST emit a field write for a field only when its legacy value,
  falling back to the template's default for that key, falling back to `""`,
  is non-empty; a field that resolves to empty after that fallback MUST NOT
  produce a field write.
- **migration-model-write-rule**: For an included descriptor, planning a
  migration MUST emit exactly one model write per configuration, using the
  legacy `"model"` value when present and non-empty, else the template's
  resolved default model.
- **migration-selected-id**: The plan's selected id MUST be set to the newly
  created configuration's identifier for the (at most one) descriptor that
  matched the legacy-selection condition, and MUST remain `""` otherwise.
- **migration-run-once**: Running migration when needed MUST return
  immediately, performing no writes, once the migration guard is true.
- **migration-apply**: When migration has not yet run, running migration
  when needed MUST build a plan from the plugin manager's discovered
  descriptors, the legacy selected-plugin setting's current value, and the
  legacy config store's resolved values, then apply every field write (via a
  fresh persisted setting keyed by the per-configuration key logic, secure
  exactly when the write is a secret) and every model write (via the same key
  logic), then set the provider-configurations list to the plan's
  configurations (even when that list is empty), then set the
  selected-configuration-id setting to the plan's selected id ONLY when that
  id is non-empty (an empty selected id MUST leave the existing selection
  setting untouched), and finally set the migration guard to true.
- **migration-legacy-values-untouched**: Running migration when needed MUST
  NOT delete, clear, or overwrite any legacy per-plugin-store-keyed setting
  (`"aiplugin.<identifier>.field.<key>"`, `"aiplugin.<identifier>.model"`, or
  `"aiplugin.selectedPlugin"`) as part of migrating it — it only reads them.
- **migration-legacy-secret-retained**: After migration copies a legacy
  secret (`"aiplugin.<identifier>.field.<key>"`, written as a secure setting)
  into the new per-configuration key, the legacy secure-storage entry MUST
  remain in place; no code path removes it.

### Configuration Resolver

- **resolver-shape**: Resolving a configuration against a plugin manager
  MUST return an optional result carrying a plugin identifier, model, values,
  and fields.
- **resolver-descriptor-lookup**: Resolving a configuration MUST return
  nothing when the plugin manager has no discovered descriptor for the
  configuration's plugin identifier (the plugin is no longer
  installed/discovered).
- **resolver-fails-closed-on-template**: Resolving a configuration MUST
  return nothing when the resolved descriptor's resolved templates contains
  no template whose id equals the configuration's template id. Resolving a
  configuration MUST NOT fall back to the descriptor's first template in
  this case — doing so would silently bind the configuration's stored
  credentials and model to an unrelated provider template.
- **resolver-values**: When both lookups succeed, resolving a configuration
  MUST return values from resolving configuration values for that
  configuration/template/fields and a model from resolving the selected
  model for that configuration/template, using the descriptor's fields for
  that template.

### Tool-Calling Chat Session

- **local-session-conformance**: The tool-calling chat session MUST conform
  to the chat-session interface and MUST be declared safe for concurrent use
  through its own explicit synchronization; its history and event
  subscription MUST be accessed only while holding its lock, and its busy
  flag MUST be accessed only through a separate mutex.
- **local-session-events-initial**: Subscribing to the session's events MUST
  return a stream that immediately yields a state-changed event carrying the
  ready state to its subscriber before any turn runs.
- **local-session-single-subscriber**: Subscribing to the session's events
  MUST replace any previously stored subscription with the new one on each
  call — this component supports at most one live subscriber at a time.
- **local-session-send-busy-guard**: Sending a message MUST be a silent
  no-op — emitting no event and starting no turn — when a turn is already
  active; otherwise it MUST set the busy flag and start running the turn as a
  new tracked unit of work.
- **local-session-interrupt**: Interrupting MUST cancel the live turn's unit
  of work and MUST reset the busy flag to false, allowing an immediate
  subsequent send even if the cancelled turn's own cleanup has not yet run.
- **local-session-clear**: Clearing MUST remove all entries from history and
  MUST NOT affect an in-flight turn.
- **local-session-close**: Closing MUST cancel the live turn, reset the busy
  flag, emit a state-changed event carrying the closed state, and finish the
  stored subscription, ending the event stream.
- **local-session-turn-start**: Running a turn for the user's text MUST emit
  a user-message event for that text, append it to history as a user-role
  chat message, and emit a state-changed event carrying the responding state
  before doing anything else.
- **local-session-no-plugin**: When no plugin can be resolved, running a
  turn MUST emit a turn-failed event carrying the message "No AI provider is
  configured." and marked not retryable, followed by a state-changed event
  carrying the ready state, and MUST NOT emit a response-started event or
  attempt any request. The user's already-appended history entry MUST remain
  in history.
- **local-session-tool-loop-bound**: Running a turn MUST iterate the
  build-request/stream/tool-execute cycle at most a fixed maximum number of
  times per turn (8); when the model still requests tools on the final
  permitted iteration, the loop MUST end after that iteration without
  starting a ninth, and without emitting any distinct "budget exceeded"
  signal.
- **local-session-stream-mapping**: Within one iteration, running a turn
  MUST emit a response-started event the first time a text-delta event
  arrives (once per turn) and MUST emit a response-delta event for every
  text-delta chunk; it MUST collect every tool-use event into the
  pending-tools list and emit a tool-call event marked started for it; it
  MUST ignore end events from the stream (never surfacing the provider's stop
  reason for that event).
- **local-session-cooperative-cancellation**: Running a turn MUST check for
  cancellation between stream events and break out of the inner event loop
  when cancelled, without cancelling mid-event.
- **local-session-partial-text-kept**: After an iteration's stream ends
  (normally or via the cancellation break), if the accumulated turn text is
  non-empty, running a turn MUST append it to history as an assistant message
  even when the iteration was cut short.
- **local-session-tool-turn-end**: Running a turn MUST end the iteration
  loop (without a further plugin call) once the pending-tools list is empty,
  or once no tool source is configured even if pending tools remain.
- **local-session-tool-execution**: When continuing the loop, running a turn
  MUST execute every pending tool call sequentially, in the order received:
  append a tool-use history entry, call the tool source, append a tool-result
  history entry carrying the result's is-error flag, and emit a tool-call
  event marked completed — before moving to the next pending tool.
- **local-session-turn-finish**: When the iteration loop ends, running a
  turn MUST emit a response-finished event (with no stop reason — the
  provider's own stop reason is never surfaced) if and only if a
  response-started event was emitted at least once during the turn, then
  MUST emit a state-changed event carrying the ready state.
- **local-session-error-path**: Any error thrown while building a request,
  from the event-stream factory, or propagated from the plugin transport
  MUST end the turn by emitting a turn-failed event built from that error
  and always marked retryable — regardless of the error's underlying cause —
  followed by a state-changed event carrying the ready state.
- **local-session-with-tools**: Attaching tools to a chat request context
  MUST return a copy of the context with its tools replaced by the mapped
  tool specs and every other field (messages, model, system prompt, max
  tokens, config) unchanged.

### MCP Tool Source

- **mcp-tool-source-conformance**: The MCP tool source MUST conform to the
  tool-source interface and MUST be declared safe for concurrent use through
  its own explicit synchronization; its registry reference and
  active-server-id set MUST be fixed at initialization time (a snapshot, not
  a live-observed set).
- **mcp-tool-source-namespacing**: Listing tool definitions and calling a
  tool MUST identify a tool by `"<server-name>__<tool-name>"` (separator
  `"__"`), built from the registry's tools for the active server ids.
- **mcp-tool-source-schema-encoding**: Listing tool definitions MUST build
  one tool definition per registry pair whose input schema JSON-encodes
  successfully, and MUST silently drop any pair whose schema fails to encode
  — no error is surfaced for a dropped pair.
- **mcp-tool-source-unknown-tool**: Calling a tool MUST return a result of
  "Unknown tool: <name>" marked as an error when no currently-registered
  pair's namespaced name matches the given name.
- **mcp-tool-source-dispatch**: Calling a tool MUST re-fetch the registry's
  tools for the active server ids on every call (not cached from listing
  tool definitions), find the matching pair, and invoke that pair's own
  tool-call operation.
- **mcp-tool-source-error-mapping**: Calling a tool MUST convert any error
  thrown by the underlying MCP call into a result of "Tool error: <the
  error's description>" marked as an error.
- **mcp-tool-source-content-flatten**: Calling a tool MUST join only the
  text content items of a successful call's response with a newline, and
  MUST silently drop any non-text content item.
- **mcp-tool-source-argument-validation**: Calling a tool decodes its arguments permissively and, on a decode failure, silently substitutes no arguments rather than surfacing a validation error: a malformed tool-call payload from the model is forwarded to the underlying call as though no arguments were supplied, instead of being reported back as a tool error the model or user could act on.

### Chat Configuration Providers (Plugin-Backed and Single-Configuration)

- **provider-defaults-on-unresolved**: Both the plugin-backed provider and
  the single-configuration provider MUST return an empty selected plugin
  identifier, an empty selected model, and empty resolved configuration
  values whenever the underlying configuration-resolution call returns
  nothing — each type MUST NOT throw.
- **plugin-chat-config-provider-selection**: The plugin-backed provider's
  resolved configuration MUST derive from the selected-configuration-id
  setting: an empty string, a string that does not parse as a valid
  identifier, or an identifier with no matching entry in the
  provider-configurations list MUST each result in no resolved configuration.
- **single-configuration-provider-pinning**: The single-configuration
  provider MUST resolve against the exact provider configuration passed to
  it at construction, independent of the selected-configuration-id setting,
  on every access — an edit made elsewhere to the same configuration's
  stored fields or model MUST be visible on the next access, since
  resolution is recomputed live rather than cached.

