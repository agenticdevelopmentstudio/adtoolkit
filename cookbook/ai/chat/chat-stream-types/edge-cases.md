
- **Null / empty input**: constructing a text-delta event with an empty
  chunk, a tool definition with empty name/description/schema bytes, and a
  tool result with an empty identifier/empty content/error flag `false`
  MUST all succeed; none of the three performs a non-empty check on any
  string or byte field.
- **Boundary values**: Not applicable in the numeric sense — none of the
  three shapes declares a size-limited field of its own (no maximum length
  on content, description, arguments, or parameter-schema bytes). Any
  upper bound on how large a tool's arguments or schema may grow is
  enforced by the transport or provider that eventually sends the bytes,
  not by these shapes.
- **Concurrent access**: Because all three shapes are safe to pass across
  concurrency boundaries and every field or payload value is unchangeable,
  the same instance MAY be read from multiple points of execution
  concurrently with no synchronization; there is no shared mutable state
  in any of the three to race on. A new instance is expected to be
  constructed per event, per advertised tool, or per tool outcome rather
  than mutated and reused.
- **Error states**: Not applicable to the three shapes themselves — none
  depends on a network, database, or file-system call of its own. A
  dependency's failure (a tool call that errors, a stream that fails)
  surfaces as the tool result's error flag being set, or as the
  corresponding element of a tool source's call-tool outcome, or as a
  failure on the enclosing response stream from the chat backend's
  tool-aware sending method — never as a case or error type these three
  shapes declare themselves.
- **Offline / disconnected state**: Not applicable — none of the three
  shapes performs network access. Connectivity loss is a concern of the
  transport that produces the bytes a decoder turns into the sibling
  stream-event contract's value, which an adapter then maps onto this
  stream event; these value shapes themselves have no notion of being
  online or offline.
- **Cancellation**: Not applicable in isolation — the stream event, tool
  definition, and tool result carry no cancellation token of their own,
  and construction of any of the three is atomic, so no partially
  constructed instance of any can exist. Cancelling the surrounding
  operation simply stops producing or consuming further instances
  upstream or downstream of these shapes.
- **Malformed raw JSON arguments / parameter-schema bytes**: MUST NOT be
  rejected by the stream event or the tool definition themselves — neither
  field is validated as well-formed JSON at construction (per
  `tool-use-arguments-raw` and `definition-schema-opaque` above); parsing
  is deferred entirely to whichever consumer reads it, e.g. an MCP-backed
  tool source's argument-decoding step, which tolerates a decode failure
  by passing no arguments onward rather than any of these three shapes
  rejecting construction.

