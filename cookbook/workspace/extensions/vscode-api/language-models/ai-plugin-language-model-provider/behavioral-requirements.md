
- **thread-confined-access**: The provider MUST be confined to a single,
  serialized execution context; every stored value read and write, and
  the synchronous portion of every method, MUST execute on that same
  confined context.
- **protocol-conformance**: The provider MUST conform to the extension
  host's language-model-providing role, implementing both listing
  available chat models and streaming a response for a given model,
  message list, justification, and extension identifier.
- **injected-plugin-manager**: Constructing the provider MUST store the
  given plugin manager as the sole source of plugin descriptors and
  loaded plugin instances; the type MUST NOT construct its own plugin
  manager.
- **configuration-observer-wiring**: Constructing the provider MUST
  subscribe an observer to the saved provider-configuration list so that
  every subsequent write to that setting invokes the
  available-chat-models-changed notification.
- **no-notification-on-construction**: Constructing the provider MUST NOT
  itself invoke the available-chat-models-changed notification, even when
  the saved provider-configuration list already holds one or more
  configurations at construction time.
- **every-configured-model-listed**: Listing available chat models MUST
  return one descriptor for every model in every template of every
  configuration currently in the saved provider-configuration list — the
  full cross product of configurations and their templates' models, not
  the app's single selected configuration.
- **deterministic-model-order**: Listing available chat models MUST order
  its results first by the order configurations appear in the saved
  provider-configuration list, then by the order models appear in that
  configuration's resolved template's model list.
- **unresolvable-template-skipped**: When a configuration's template
  cannot be resolved from the plugin manager, listing available chat
  models MUST contribute no descriptor for that configuration and MUST
  continue processing the remaining configurations.
- **descriptor-id-format**: Each descriptor's id MUST be the string
  formed by joining the configuration's identifier and the model name
  with a single `"/"` separator.
- **descriptor-id-separator-safety**: The id split performed when
  resolving a configuration MUST use the FIRST occurrence of `"/"` only,
  so a model name that itself contains `"/"` is preserved verbatim in the
  parsed model name.
- **descriptor-name**: Each descriptor's name MUST be the configuration's
  name, a `"·"` separator, and the model name.
- **descriptor-vendor**: Each descriptor's vendor MUST be the resolved
  template's provider name, falling back to the template's display name
  when the provider name is absent.
- **descriptor-family**: Each descriptor's family MUST be the model's
  canonical identifier.
- **descriptor-version**: Each descriptor's version MUST be the raw model
  name, unmodified.
- **descriptor-max-input-tokens**: Each descriptor's maximum input tokens
  MUST be the model catalog's resolved context-window size when the
  catalog has an entry for that model/template pair, and MUST be `4096`
  when it does not.
- **justification-recorded-only**: When streaming a response is called
  with a present justification, it MUST log the extension identifier and
  the justification before doing anything else, and MUST NOT use the
  justification's content to gate, filter, or alter which model or plugin
  the request reaches.
- **justification-privacy**: The logged justification value MUST be
  logged as sensitive/redacted; the logged extension-identifier value
  MUST be logged as not sensitive.
- **no-log-when-justification-absent**: When justification is absent,
  streaming a response MUST NOT emit the justification log line at all.
- **model-id-parse-failure**: Resolving a configuration MUST throw an
  unknown-model error naming the requested id when that id contains no
  `"/"` character.
- **model-id-unknown-configuration**: Resolving a configuration MUST
  throw an unknown-model error naming the requested id when the substring
  before the first `"/"` does not parse as a valid identifier, or parses
  but names no configuration currently in the saved provider-configuration
  list.
- **configuration-reread-per-call**: Resolving a configuration MUST
  re-read the saved provider-configuration list on every call rather than
  reuse a value captured when the descriptor was built, so a
  configuration deleted after the descriptor was issued is reflected on
  the next call.
- **plugin-resolution-failure**: Streaming a response MUST throw a
  plugin-unavailable error naming the resolved configuration's plugin
  identifier when the provider-configuration resolver cannot resolve the
  configuration's plugin.
- **plugin-load-failure-collapsed**: Streaming a response MUST throw a
  plugin-unavailable error naming the resolved plugin identifier when
  loading the plugin fails, regardless of which specific load-failure case
  occurred (not found, load failed, no principal class, principal class
  not a plugin); the specific failure cause MUST be discarded.
- **request-model-override**: Streaming a response MUST set both the
  plugin's request-configuration bag's model entry and the chat context's
  model to the model name parsed from the requested descriptor's id,
  overriding whatever model the resolved configuration's own stored value
  would otherwise supply.
- **no-system-prompt**: Every chat context streaming a response builds
  MUST have no system prompt.
- **no-tools-forwarded**: Every chat context streaming a response builds
  MUST have an empty tool list; streaming a response's own parameters
  carry no tool list of their own for this to forward.
- **default-max-tokens**: Every chat context streaming a response builds
  MUST omit an explicit maximum-tokens argument, so every request uses
  the chat context's own default of `4096`, independent of the resolved
  descriptor's own maximum input tokens.
- **build-request-error-propagation**: When building the plugin's request
  throws, streaming a response MUST propagate that error unwrapped — it
  MUST NOT catch it or convert it into one of the provider's own named
  error cases.
- **transport-delegation**: Streaming a response MUST delegate all
  network access and subprocess execution to the plugin transport's run
  operation; the provider MUST perform no HTTP request, no subprocess
  launch, and no credential lookup of its own.
- **response-part-mapping**: Mapping a stream event to a response part
  MUST map a text-delta event to a text part, a tool-use event to a
  tool-call part carrying the same id, name, and arguments, and an end
  event to an end part carrying the same stop reason, with no case
  dropped or merged.
- **message-role-mapping**: Mapping a message MUST map a user-role
  message to a user-role chat message and MUST map an assistant-role
  message — the role's only other case — to an assistant-role chat
  message.
- **message-name-dropped**: Mapping a message MUST NOT carry the
  message's name into any field of the chat message it produces.
- **stream-single-consumption**: Streaming a response MUST return a fresh
  stream per call; it MUST NOT return or reuse a previously-returned
  stream.
- **stream-cancellation-propagation**: When the consumer of a streamed
  response terminates early, that termination MUST cancel the wrapping
  unit of work, which cancels the plugin transport stream it is
  iterating.
- **no-instance-caching**: Listing available chat models and resolving a
  configuration MUST NOT cache a prior call's result; each call MUST
  recompute from the current saved provider-configuration list and the
  current plugin-manager state.
- **unknown-model-caller-guidance**: A caller catching the unknown-model
  error SHOULD treat it as a stale descriptor and re-query available chat
  models, rather than as a malformed request from the extension —
  deviation is acceptable because both of that error's triggers (an
  unparseable id, or a configuration deleted since the descriptor was
  issued) originate from state that changed after the descriptor was
  handed out, not from anything the extension itself chose; both cases
  are "the same event from an extension's point of view: it held a model
  descriptor across the user deleting the provider behind it."
- **model-name-membership**: Neither resolving a configuration nor
  resolving its plugin checks that the model name parsed out of a
  descriptor's id is still present in the resolved template's current
  model list — only that the configuration id and its template id still
  resolve. If a plugin update removes or renames a model between the time
  a descriptor was built and a later request call parses it, streaming a
  response MUST send the request with the stale model name unchanged,
  leaving the plugin's own request builder and the provider to reject it;
  any such rejection surfaces to the caller as the stream's error.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

