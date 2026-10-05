
- **zero-argument-initialization**: A conforming plugin type MUST provide a
  synchronous, non-failing, zero-argument construction path, since the host
  constructs plugin instances by invoking it on a type obtained by
  resolving a bundle's principal class.
- **cheap-instantiation**: Constructing a conforming plugin SHOULD be
  inexpensive, because the contract documents instances as cheap and states
  a caller MAY create a new instance per request.
- **request-description**: Building a request MUST synchronously return a
  request spec that fully describes the HTTP or subprocess request for one
  chat turn, derived from the given chat context.
- **insufficient-context-error**: Building a request MUST fail with an
  error instead of returning a value when the given chat context does not
  contain what the plugin needs to build a request (e.g. a required config
  value is missing).
- **fresh-decoder-per-response**: Creating a decoder MUST return a newly
  created stream-decoder instance on every call, and that instance MUST own
  whatever mutable state it needs to parse exactly one response stream.
- **validation-request-default**: Building a validation request MUST
  return no result for a conforming plugin that does not override this
  behavior, via the contract's default implementation.
- **validation-request-cannot-validate**: An overriding validation-request
  implementation MUST return no result when it has no way to validate the
  given plugin configuration.
- **error-message-default**: Describing an error MUST return no result for
  a conforming plugin that does not override this behavior, via the
  contract's default implementation, signaling the host SHOULD fall back to
  a generic "HTTP `<status>`" message.
- **transport-non-ownership**: A conforming plugin MUST NOT perform
  networking or spawn a subprocess itself; building a request and building
  a validation request MUST only describe a request, never execute one —
  the plugin performs no networking, and the host owns the transport.
- **ui-non-ownership**: A conforming plugin MUST NOT present any user
  interface; the host builds the settings UI from the bundle's descriptor
  schema, and the plugin ships no UI of its own.
- **secret-non-ownership**: A conforming plugin MUST NOT implement its own
  secret storage; the host owns secret storage, and any credential the
  plugin needs arrives already resolved inside the chat context's
  configuration.
- **metadata-non-ownership**: A conforming plugin MUST NOT expose identity
  or presentation metadata (identifier, display name, supported models,
  capabilities, settings schema) through this contract; all identity and
  presentation metadata live as data in the bundle, not in the plugin's own
  code, so the host can list and configure a plugin without loading its
  binary.
- **shared-instance-concurrency-safety**: The contract MUST require every
  conforming plugin to be safe to invoke concurrently from multiple callers
  on one shared instance, and to be usable as a reference type so the host
  can hold and reuse one instance across calls — the plugin itself MUST be
  safe to capture and invoke from any concurrency domain.
- **concurrent-invocation-safety**: Because a conforming plugin must be
  safe to invoke concurrently, a conforming plugin MUST make any internal
  mutable state safe for concurrent invocation of building a request,
  building a validation request, and describing an error from multiple
  callers on one shared instance. The implementation's compiler MAY
  statically enforce this for ordinary stored state; an implementation that
  opts out of that static enforcement assumes the safety obligation
  manually.
- **decoder-isolation**: The stream decoder a decoder-creation call returns
  MUST be used to parse a single response only and MUST NOT be shared
  across concurrent responses, since it is not safe to share across
  concurrency domains and is documented to hold per-response parsing
  state.
- **foundation-only-dependency**: The module declaring this contract MUST
  depend only on the platform's base runtime library, with no UI framework
  or third-party dependency.
- **shared-framework-image**: A plugin bundle MUST link the module
  declaring this contract without embedding a separate copy of it, so a
  freshly loaded plugin type resolves against the host's single loaded
  copy of that module and can be recognized as conforming to the contract.

