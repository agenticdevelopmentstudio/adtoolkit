
- **message-role**: the chat message's role MUST be one of `system`,
  `user`, `assistant`, `toolUse`, or `toolResult`, and MUST serialize as a
  string, where `toolUse` serializes as `"tool_use"` and `toolResult`
  serializes as `"tool_result"` (not the case name itself) and the other
  three cases serialize as their lowercase name.
- **message-content**: the chat message MUST carry a required text
  `content` field with no default value.
- **message-tool-fields-optional**: the chat message MUST allow
  `toolUseId`, `toolName`, `toolArgumentsJSON`, and `toolIsError` to be
  absent, and constructing one MUST default each of the four to absent when
  the caller omits it.
- **message-tool-fields-independent**: the chat message MUST NOT enforce
  any relationship between `role` and the four tool-related fields; a
  message may combine any `role` with any combination of `toolUseId`,
  `toolName`, `toolArgumentsJSON`, and `toolIsError` being present or
  absent.
- **tool-spec-identity**: the tool specification MUST require `name`,
  `description`, and `parametersJSONSchema` (raw JSON Schema bytes), none
  of which has a default value.
- **tool-spec-equality**: the tool specification MUST support equality
  comparison; two instances MUST compare equal if and only if their `name`,
  `description`, and `parametersJSONSchema` are each equal.
- **config-value-storage**: the plugin configuration MUST store its values
  as a string-keyed dictionary of strings and MUST expose a keyed lookup
  that returns the value for a key present in the dictionary, or nothing
  for a key that is absent.
- **config-conventional-accessors**: the plugin configuration MUST expose
  `apiKey`, `baseURL`, and `model` as convenience accessors reading the
  `"apiKey"`, `"baseURL"`, and `"model"` keys of its value dictionary
  respectively, returning nothing when the corresponding key is absent.
- **config-host-resolved**: the plugin configuration's values MUST already
  be fully resolved (settings-schema fields merged with secrets injected
  from secure storage) by the caller before the value is constructed; per
  its own documentation, "the plugin never touches storage itself" — the
  plugin configuration and the chat context MUST NOT perform any storage or
  settings-schema access of their own.
- **context-messages-required**: the chat context MUST require a
  `messages` list of chat messages with no default value, representing the
  full conversation history for the turn in caller-supplied order.
- **context-model-required**: the chat context MUST require a `model`
  string with no default value.
- **context-system-prompt-optional**: the chat context MUST allow
  `systemPrompt` to be absent and MUST default it to absent when the caller
  omits it.
- **context-max-tokens-default**: the chat context MUST default
  `maxTokens` to `4096` when the caller omits it.
- **context-tools-default-empty**: the chat context MUST default `tools`
  to an empty list when the caller omits it.
- **context-config-required**: the chat context MUST require a `config`
  (a plugin configuration value) with no default value.
- **immutability**: the chat message, the tool specification, the plugin
  configuration, and the chat context MUST expose every stored value as
  unchangeable once constructed; the four MUST NOT provide any way to
  mutate an existing instance after construction.
- **sendability**: the chat message, its role, the tool specification, the
  plugin configuration, and the chat context MUST each be safe to pass
  across a concurrency-domain boundary; because each holds only values that
  are themselves safe to share this way (strings, raw bytes, whole numbers,
  booleans, string-keyed dictionaries of strings, and lists thereof), no
  manual synchronization is required to move an instance from the host into
  a plugin's request-building step.
- **concurrent-read-safety**: Because every value on all four types is
  unchangeable and safe to share across concurrency boundaries, a single
  constructed instance MAY be read concurrently from multiple points of
  execution with no additional locking, and no operation defined by this
  contract mutates shared state, so no ordering or serialization rule is
  needed between concurrent reads of the same instance.
- **no-persistence**: the chat message, the tool specification, the plugin
  configuration, and the chat context MUST NOT persist or cache any of
  their fields; none defines any file, database, or secure-storage access,
  and each instance exists only as a transient parameter for one call into
  a plugin's request-building step.
- **no-side-effects**: Constructing or reading any field of the chat
  message, the tool specification, the plugin configuration, or the chat
  context MUST NOT perform network access, file I/O, subprocess execution,
  or notification posting; each is limited to stored values, simple
  accessors over those values, and a way to construct one from its parts.
- **no-error-domain**: Constructing any of the four types MUST NOT fail
  with an error, and this contract MUST NOT declare an error type of its
  own; rejecting an insufficient chat context (e.g., a `config` missing a
  required field) is the request-building step's responsibility, which is
  defined to be able to fail for exactly that purpose ("Fails if the
  context is insufficient, e.g. a required config value is missing") —
  this contract itself performs no such validation.
- **tool-schema-translation-is-the-plugins-job**: Translating the chat
  context's `tools` into a specific provider's tool/function schema MUST
  happen inside the consuming plugin's request-building step, not in this
  contract; the tool specification's role is limited to carrying `name`,
  `description`, and `parametersJSONSchema` unchanged.

