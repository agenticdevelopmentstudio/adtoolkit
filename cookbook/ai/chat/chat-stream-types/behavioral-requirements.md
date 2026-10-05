
- **stream-event-case-set**: the stream event MUST have exactly three
  cases — a text delta carrying a string chunk, a tool-use event carrying
  an identifier/name/raw JSON arguments, and an end event carrying an
  optional stop reason.
- **stream-event-sendable**: the stream event MUST be safe to pass across
  a concurrency-domain boundary.
- **text-delta-payload**: the text-delta case's payload MUST be exactly
  one string chunk of assistant text and carry no other data; this shape
  imposes no constraint on chunk size or where a chunk boundary falls.
- **tool-use-payload**: the tool-use case's payload MUST be an identifier,
  a tool name, and raw JSON arguments.
- **tool-use-arguments-raw**: the raw JSON arguments on a tool-use event
  MUST carry the model's tool-call arguments as raw, undecoded bytes,
  unchanged from the sibling stream-event contract's tool-use value it is
  mapped from — the mapping step passes the arguments straight through
  with no parsing, and this shape itself performs no JSON decoding of the
  field.
- **end-stop-reason-optional**: the end case's stop reason MUST be
  optional, so a producer MAY report nothing when no reason is available.
- **stream-emission-contract**: Per its own documentation, a text-only
  backend MUST emit only text-delta and end events on a stream it returns,
  and a tool-capable backend MUST additionally emit one tool-use event for
  each call the model requests ("Text-only backends only emit
  text-delta and end; tool-capable backends additionally emit tool-use for
  each call the model wants to make").
- **tool-call-result-correlation**: The identifier carried by a tool-use
  event MUST be the same identifier a caller later supplies when reporting
  that call's outcome, whether as the tool result's correlating identifier
  or as a chat message's matching identifier on a tool-result-role
  message — the local chat session propagates the same identifier recorded
  from each pending tool call into the tool-result-role message it later
  appends.
- **definition-identity**: the tool definition MUST require a name, a
  description, and raw JSON Schema bytes for its parameters, none of
  which has a default value.
- **definition-equality**: the tool definition MUST support equality
  comparison; two instances MUST compare equal if and only if their name,
  description, and parameter-schema bytes are each equal.
- **definition-sendable**: the tool definition MUST be safe to pass across
  a concurrency-domain boundary.
- **definition-immutability**: the tool definition MUST declare its name,
  description, and parameter-schema bytes as unchangeable once constructed
  and MUST provide no way to mutate an existing instance.
- **definition-schema-opaque**: the parameter-schema bytes MUST be treated
  as an opaque, pre-serialized JSON Schema byte buffer — the tool
  definition MUST NOT parse, decode, or validate it; nothing in this shape
  reads or transforms the field beyond storing and returning it.
- **definition-provider-translation-elsewhere**: Translating a tool
  definition into a specific backend's provider tool schema (e.g. one
  provider's `tools`, another's `functions`) MUST happen in the consuming
  backend, not in the tool definition itself, per its own documentation
  ("Backends translate this into the provider-specific shape... before
  sending the request") — the local chat session and the plugin-backed
  adapter each perform exactly this translation, copying the three fields
  unchanged into a tool specification.
- **result-identity**: the tool result MUST require a correlating
  identifier, content text, and an error flag, none of which has a
  default value.
- **result-equality**: the tool result MUST support equality comparison;
  two instances MUST compare equal if and only if their correlating
  identifier, content, and error flag are each equal.
- **result-sendable**: the tool result MUST be safe to pass across a
  concurrency-domain boundary.
- **result-immutability**: the tool result MUST declare its correlating
  identifier, content, and error flag as unchangeable once constructed and
  MUST provide no way to mutate an existing instance.
- **result-error-flag-independence**: the tool result MUST NOT enforce any
  relationship between its error flag and its content — constructing one
  stores both fields exactly as given, with no validation tying them
  together; a caller MAY construct an error result with non-empty content
  (an error message) or a non-error result with empty content.
- **cross-domain-safety**: Because the stream event, the tool definition,
  and the tool result are all safe to pass across concurrency boundaries
  and every value they carry is itself safe to share this way (strings,
  raw bytes, booleans, optional strings), an instance of any of the three
  MAY cross a concurrency-domain boundary — e.g. from a background task
  into a UI thread's chat surface, or from a tool-dispatch loop into a
  tool source running on its own execution context — with no additional
  synchronization.
- **no-persistence-no-side-effects**: Constructing or reading any case or
  field of the stream event, the tool definition, or the tool result MUST
  NOT perform file, database, secure-storage, or network access, and none
  of the three persists or caches a value beyond the caller's own variable
  lifetime — each is limited to a case list or stored values plus a way to
  construct one, with no I/O of any kind.

