
- **Null/empty input**: An empty headers map, no body, an empty arguments
  list, no standard-input payload, and an empty environment map are each
  that field's own documented default and MUST be accepted as ordinary,
  valid values, not as an error condition. An empty environment MUST leave
  the child process inheriting the host's environment, per
  environment-replace-semantics.
- **Boundary values**: timeout accepts any numeric value, including 0, a
  negative value, not-a-number, and infinite; the request specification
  itself imposes no minimum, maximum, or validity constraint on timeout (per
  no-input-validation). What each of those boundary values means once the
  host consumes it is defined entirely outside this type, by the request's
  one consumer.
- **Concurrent access**: Because the request specification is safe to share
  across concurrent execution contexts, a single instance MAY be read or
  copied concurrently from multiple execution contexts without
  synchronization, since each concurrent holder either owns an independent
  copy or observes an immutable snapshot at the point it was captured.
  Concurrent mutation of one shared mutable binding to a request
  specification (e.g., a mutable field stored on a reference type
  elsewhere) is not a concern this type resolves; it is an ordinary
  shared-mutable-state hazard no different from any other value safe to
  share this way, and this type defines no such shared binding itself.
- **Error states**: No operation this type defines (its constructor or
  either convenience constructor) can fail. A failure to actually perform
  the described request (an unreachable host, a non-2xx HTTP status, a
  non-zero subprocess exit) is reported by the host's transport layer after
  this type has already handed back a value, never by the request
  specification itself.
- **Offline/disconnected state**: This type performs no I/O and so never
  observes network connectivity; connectivity loss during the request the
  instance describes is entirely the concern of the host transport that
  consumes the instance, not of this type.
- **Missing file or unreachable server**: An executable location that names
  a file that does not exist, or a URL whose host is unreachable, is
  accepted unchanged by every constructor this type defines; the resulting
  failure surfaces only when the host later attempts to launch the process
  or open the connection, since the host owns the transport. This mirrors
  the sibling plugin recipe's own contract that such failures are never
  observed inside the plugin's own operations.
- **Cancellation and timeout**: This type's constructors are synchronous and
  return immediately; they have no cancellation or timeout point of their
  own. The timeout value they carry is enforced, and any in-flight request
  is cancelled, only by the host's transport layer once it begins executing
  the described transport kind — never by this type.

