
- **Null / empty input**: consume with no bytes SHOULD return an empty
  list — every conformer in this repository does — but the decoder role
  itself imposes no such requirement, so this is each decoder's own
  consistent convention, not a role guarantee.
- **Boundary values**: Not applicable in the numeric sense — this contract
  defines no size-limited field of its own (no maximum byte-buffer length,
  no cap on buffered bytes). Any upper bound on how large an unresolved
  frame may grow before a newline appears is a decision made by the host
  that drives consume, not by this component.
- **Concurrent access**: Two execution contexts MUST NOT call consume or
  finish on the same decoder instance concurrently for two different
  responses; the decoder role carries no cross-context sharing safety and
  its per-response state is unprotected by design (MUST, per
  decoder-single-context-state and single-response-isolation above).
- **Error states**: A malformed or unrecognizable frame (invalid JSON,
  bytes that fail text decoding, an unrecognized event type) MUST NOT cause
  consume or finish to raise an error — the source declares neither
  operation as failure-raising, so a decoder MUST fall back to returning an
  empty list for that frame. See decode-failure-signal and its
  Design Decision for the gap this leaves.
- **Offline / disconnected state**: When the underlying byte stream fails
  before ending normally (e.g. a network read interrupted by a dropped
  connection), the host's byte pump MUST propagate that error immediately,
  and in doing so it MUST NOT reach either the trailing-partial-line
  consume call or the final finish call — any bytes a decoder was still
  buffering internally are discarded without ever reaching the returned
  event sequence; only the raised error, not any partial content, reaches
  the stream's consumer.
- **Cancellation**: the host's byte pump checks for cancellation once per
  byte inside its loop; a cancelled consuming operation MUST therefore be
  able to stop delivery to consume mid-frame, and in that case finish MUST
  NOT be called either — cancellation and a dropped connection produce the
  same outcome for this component: no flush, only whatever events were
  already yielded before the cancellation was observed.

