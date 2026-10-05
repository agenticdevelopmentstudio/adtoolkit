
- **concurrent-share-safety**: The request specification type, its nested
  method kind, and its nested transport kind MUST all be safe to share
  across concurrent execution contexts without synchronization, so a value
  returned by the request-building operation MAY be handed from the
  plugin's own execution context to the host's transport logic without a
  data-race diagnostic.
- **value-type-semantics**: The request specification MUST have value
  semantics, not reference semantics, so assigning or passing an instance
  MUST copy it: mutating one binding's transport-kind or timeout MUST NOT
  affect any other binding holding a separately-assigned copy of the same
  instance.
- **mutable-fields**: The transport-kind and timeout fields MUST be mutable,
  so a caller MAY construct an instance and then reassign either field
  before handing the value to the host.
- **exactly-one-transport**: An instance MUST describe exactly one way to
  reach the provider, held in its single transport-kind field; the
  transport kind MUST have two mutually exclusive cases, so a single
  instance MUST NOT simultaneously describe an HTTP request and a subprocess
  command.
- **http-transport-fields**: The HTTP transport case MUST carry exactly a
  method, a URL, a headers map, and an optional body.
- **command-transport-fields**: The command transport case MUST carry
  exactly an executable location, an arguments list, an optional
  standard-input payload, and an environment map.
- **method-cases**: The method kind MUST expose exactly two cases: GET (wire
  value "GET") and POST (wire value "POST").
- **timeout-field**: An instance MUST carry a timeout representing the
  wall-clock budget for the whole request before the host cancels it.
- **designated-initializer**: Constructing an instance from a transport kind
  and a timeout MUST be the sole designated way to build one, MUST accept a
  required transport kind, MUST default the timeout to 120 when the caller
  omits it, and MUST be synchronous and non-failing.
- **http-convenience-constructor**: The HTTP convenience constructor MUST
  require only a URL and MUST default the method to POST, the headers to an
  empty map, the body to none, and the timeout to 120, returning an instance
  whose transport kind is HTTP with exactly the given (or defaulted) values.
- **command-convenience-constructor**: The command convenience constructor
  MUST require only an executable location and MUST default the arguments
  to an empty list, the standard-input payload to none, the environment to
  an empty map, and the timeout to 120, returning an instance whose
  transport kind is command with exactly the given (or defaulted) values.
- **non-throwing-construction**: No constructor this type defines MAY throw
  or fail; every path from valid argument values to an instance MUST succeed
  synchronously.
- **no-input-validation**: The designated constructor and both
  convenience constructors MUST NOT validate their arguments; any timeout value
  (including zero, negative, not-a-number, or infinite), any URL, and any
  string map or byte payload the caller supplies MUST be accepted and stored
  unchanged. This is a deliberate design, not a gap: interpreting an
  out-of-range timeout is left entirely to the request's one consumer (see
  Design Decisions).
- **description-only-contract**: A value of this type MUST NOT itself
  perform networking, spawn a process, or produce any other side effect; the
  plugin contributes only the description, the host owns the transport.
  Constructing or holding a request specification MUST have no observable
  effect beyond the value itself.
- **no-persistence**: A request specification instance MUST NOT be cached,
  reused across chat turns, or written to any store by this type; the
  request-building operation is documented to build a fresh spec from the
  current chat request context for one chat turn, and this type defines no
  storage of its own.
- **host-http-consumption**: When the host executes an HTTP-transport
  instance, the method becomes the resulting request's HTTP method, each
  header entry is applied as one HTTP header field, and the body becomes the
  request body — this is observable only through the request's sole
  consumer, the plugin transport's HTTP path, which is cited here because it
  is the only place these fields' meaning is observable.
- **host-command-consumption**: When the host executes a command-transport
  instance, the executable location and arguments describe the child
  process, the standard-input payload (if given) is written to the child and
  then the child's input is closed to signal end-of-file, and the child's
  output is streamed to the plugin's decoder — this is observable only
  through the request's sole consumer, the plugin transport's command path.
- **environment-replace-semantics**: A non-empty environment on a
  command-transport instance MUST become the entire environment of the
  spawned child process, replacing rather than merging with the host
  process's own environment; an empty environment MUST leave the child
  inheriting the host's environment unchanged. This is non-obvious from the
  field's name alone, so a plugin that wants the host's search-path variable
  (or any other inherited variable) available to its child MUST include it
  explicitly, as one local-command plugin does by starting from the current
  process's environment before appending search paths.
- **dual-purpose-timeout**: For an HTTP-transport instance, the timeout MUST
  be used both as the wall-clock budget racing the whole request and,
  independently, as the underlying request's own idle-timeout value — a
  timeout that resets on every received byte rather than bounding the whole
  transfer. A single timeout value therefore governs two different timeout
  semantics in the one consumer that reads it.

