
- **case-set**: The stream event type MUST have exactly three cases — a
  text-delta case carrying a text chunk, a tool-use case carrying an
  identifier, a name, and the raw arguments payload, and an end case
  carrying an optional stop reason.
- **event-concurrent-share-safety**: The stream event type MUST be safe to
  share across concurrent execution contexts, so a decoded value MAY cross
  concurrency domains — e.g. yielded from a background streaming operation
  into an event sequence that a single-context-confined consumer such as a
  local chat session or a plugin chat backend iterates.
- **text-delta-payload**: text-delta's payload MUST be a chunk of assistant
  text and nothing else; this type imposes no constraint on chunk size or
  boundaries — that is each decoder's own choice.
- **tool-use-payload**: tool-use's payload MUST be an identifier, a name,
  and a raw arguments payload, where the arguments payload MUST be the raw,
  undecoded JSON arguments the model supplied — a decoder MUST NOT parse or
  validate that JSON before emitting the event.
- **end-stop-reason-optional**: end's stop-reason value MUST be optional, so
  a decoder MAY report none when the provider gives no reason for stopping.
- **decoder-reference-semantics**: The decoder role MUST require reference
  semantics, so only a reference-identity type may conform — a
  value-semantics conformer MUST fail to satisfy the contract.
- **decoder-single-context-state**: The decoder role MUST NOT require
  safety for sharing across concurrent execution contexts; a conforming
  type MAY hold mutable per-response parsing state without any
  synchronization of its own.
- **stream-decoder-isolation-domain**: Because the decoder role carries no
  cross-context sharing safety, a conforming instance MUST stay within the
  single execution context that created it via the decoder-construction
  operation — strict concurrency checking rejects passing such a decoder
  across a suspension point into a different execution context. The plugin
  transport's HTTP and command paths both create the decoder inside the
  same execution context that then drives every consume/finish call on it.
- **fresh-decoder-per-request**: A new request MUST use a newly created
  decoder instance, per the documented contract "a fresh decoder is created
  per request"; the plugin transport's HTTP and command paths each call
  the decoder-construction operation exactly once, inside the streaming
  operation, before consuming any bytes.
- **single-response-isolation**: One decoder instance MUST be used to
  decode a single response stream only and MUST NOT be shared across two
  concurrent responses, since it holds per-response state and requires no
  thread-safety of its own.
- **consume-accepts-incremental-bytes**: consume MUST accept newly received
  bytes and return the events that can now be fully decoded from them.
- **consume-buffers-partial-frame**: consume MUST retain any partial
  trailing frame internally rather than discard it or error on it, because
  the host MAY split a single logical frame across multiple consume calls.
- **consume-returns-decodable-only**: consume MUST return only the events
  fully decodable from the bytes accumulated so far — it MUST NOT return a
  partial or speculative event for data it has not finished decoding.
- **non-throwing-decode**: consume and finish MUST NOT raise an error —
  both are declared without a failure path — so a decoder that cannot make
  sense of its buffered bytes MUST signal that by omitting an event, not by
  raising an error.
- **finish-returns-final-events**: finish MUST return whatever final events
  the decoder was still holding once the stream closes.
- **finish-default-empty**: A conforming type that does not implement
  finish MUST receive a default implementation that returns an empty list.
- **finish-called-once-per-stream**: The host MUST call finish exactly once
  per response stream, after the stream closes, to flush any trailing
  state.
- **sequential-delivery**: The host MUST deliver bytes to consume and the
  terminating finish call in strict arrival order on one instance, never
  out of order and never interleaved with another response's bytes — this
  is the only ordering guarantee this component's design (per-instance
  mutable state, no cross-context sharing safety) makes workable.
- **host-framing-contract**: The one host in this codebase, the plugin
  transport, MUST feed consume newline-delimited frames — each complete
  line including its trailing newline byte, or one final unterminated
  remainder — rather than arbitrary byte chunks. The decoder role itself
  imposes no such framing; its own documented contract promises only "raw
  bytes... possibly splitting a single logical frame across calls."
- **no-persistence-or-caching**: This component MUST NOT persist any event
  or cache decoder state beyond the data and decoder-instance lifetimes
  already described above — the source contains no file, database, or
  secure-storage write of its own.
- **decode-failure-signal**: Neither the stream event type nor the decoder role defines a case or return path meaning "this frame is malformed and will never decode": a permanently corrupt frame (for example JSON truncated by a dropped connection, or bytes that fail text decoding) is indistinguishable from a frame that is merely incomplete and awaiting more bytes, and both currently yield an empty list from consume with no signal reaching the host.

