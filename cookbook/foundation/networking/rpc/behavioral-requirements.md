
- **framing-cases**: The framing scheme MUST support exactly three cases —
  newline-delimited, content-length-prefixed, unframed — each defining a
  distinct encode/decode contract.
- **newline-frame-encoding**: Encoding a message under the
  newline-delimited scheme MUST append a single linefeed byte (`0x0A`) to
  the message, unless the message already ends in a linefeed byte, in
  which case it MUST return the message unchanged.
- **content-length-frame-encoding**: Encoding a message under the
  content-length-prefixed scheme MUST prepend `Content-Length:
  <n>\r\n\r\n` in ASCII to the message, where `<n>` is the message's byte
  count, with no other header.
- **unframed-frame-encoding**: Encoding a message under the unframed
  scheme MUST return the message unchanged, with no envelope added.
- **frame-boundary-completeness**: Consuming a chunk MUST return every
  frame the buffer newly completes, in arrival order, and MUST NOT return
  a partial frame.
- **newline-frame-shape**: Under the newline-delimited scheme, each
  decoded frame MUST be the byte-exact slice up to and including its
  trailing linefeed byte, preserving that byte rather than stripping it.
- **content-length-frame-shape**: Under the content-length-prefixed
  scheme, each decoded frame MUST be the body only; the `Content-Length:
  <n>\r\n...\r\n\r\n` header MUST be consumed and discarded, never
  included in the frame.
- **unframed-decoding**: Under the unframed scheme, consuming a chunk MUST
  hand back each non-empty chunk as its own frame, unmodified, the moment
  it arrives, and MUST return an empty array for an empty chunk; no bytes
  are ever buffered for this case, and the frame-size cap below MUST NOT
  apply to it.
- **content-length-header-parsed-once**: Under the content-length-prefixed
  scheme, the header MUST be parsed exactly once, at the moment its
  blank-line terminator is seen, and MUST NOT be reparsed while the body
  is still arriving in later chunks.
- **content-length-header-line-parsing**: Each header line MUST be split
  on its first colon into a key and a trimmed value; a header key MUST be
  matched case-insensitively against `Content-Length`; any other header
  (for example `Content-Type`) MUST be tolerated and discarded without
  error.
- **content-length-malformed-header**: Header parsing MUST throw a
  malformed-header failure when a header line is not valid UTF-8, when a
  header line has no colon separator, or when the `Content-Length` value
  is not a non-negative integer.
- **content-length-missing-header**: Header parsing MUST throw a
  missing-content-length failure when no header line's key matches
  `Content-Length`.
- **frame-size-cap**: Under the newline-delimited and content-length-
  prefixed schemes, the decoder MUST enforce a 16,777,216-byte (16 MiB)
  cap on any single frame's buffered bytes.
- **cap-violation-preserves-prior-frames**: When consuming one chunk both
  completes one or more valid frames and then begins an oversized one,
  that call MUST return the completed frames and MUST defer the frame-
  size-exceeded failure to the decoder's next call, rather than losing the
  valid frames to the same failure.
- **newline-cap-recovery**: When a newline-delimited buffer exceeds the
  cap, the decoder MUST discard every byte up to and including the next
  linefeed byte it receives (dropping the oversized line in full) before
  resuming normal framing, and MUST NOT ever deliver that oversized line
  as a frame.
- **content-length-cap-recovery**: When a content-length header declares a
  body length greater than the cap, the decoder MUST discard exactly that
  many body bytes before resuming header scanning, so a Content-Length-
  shaped line inside the rejected body cannot resynchronize the stream
  onto a boundary the peer chose.
- **finish-newline-remainder**: Flushing at end-of-stream, under the
  newline-delimited scheme, MUST return the buffer's trailing unterminated
  remainder as one final frame when the buffer is non-empty, and MUST
  return an empty array when the buffer is empty.
- **finish-content-length-truncated**: Flushing at end-of-stream, under
  the content-length-prefixed scheme, MUST throw a truncated-message
  failure (carrying the expected and received byte counts) when a header
  has already been parsed and stripped but the buffer holds fewer than the
  declared number of body bytes.
- **finish-content-length-malformed**: Flushing at end-of-stream, under
  the content-length-prefixed scheme, MUST throw a malformed-header
  failure when the buffer is non-empty but no complete header was ever
  parsed.
- **finish-unframed-noop**: Flushing at end-of-stream, under the unframed
  scheme, MUST always return an empty array and MUST NOT throw, because
  the unframed scheme never holds anything back.
- **finish-during-discard**: Flushing at end-of-stream while the decoder
  is mid-discard (skipping an over-cap line or the remainder of an
  over-cap body) MUST return an empty array and MUST clear all buffered
  and discard state, rather than returning a fragment of the rejected
  frame or reporting its unarrived bytes as a truncated message.
- **decoder-single-owner**: The framing decoder MUST be a mutable value
  with no shared ownership; a channel's message pump MUST create and hold
  exactly one instance per stream, consumed only from that pump's own
  execution context, never shared concurrently across contexts.
- **channel-calls-serialized**: The subprocess channel MUST serialize
  every call made against one instance (launch, read messages, send, send
  raw, close input, read standard-error text, read standard-error bytes,
  terminate) so no two such calls run concurrently against the same
  instance; waiting for exit MUST be exempt from that serialization, so
  awaiting it never blocks the channel for the life of a long-running
  child.
- **configuration-and-result-thread-safe**: The channel's configuration
  and its run result MUST be safe to share across concurrent callers, so a
  caller MAY construct and pass either freely across concurrency domains.
- **single-stdout-reader**: Reading the message stream MUST throw a
  not-launched failure if called before launch has succeeded, and MUST
  throw an already-consumed failure if called a second time on the same
  channel; a channel MUST expose exactly one reader over the child's
  standard output.
- **launch-idempotency**: Launching MUST throw an already-launched failure
  if called on a channel that has already launched successfully.
- **launch-sigpipe-suppression**: Launching MUST disable the SIGPIPE
  signal, scoped specifically to the child's standard-input write
  descriptor, before starting the process, and MUST throw a launch-failed
  failure without spawning the process if that step fails.
- **environment-replace-policy**: Under the replace environment policy, a
  non-empty configured environment MUST become the child's entire
  environment; an empty configured environment MUST leave the child
  inheriting the parent process's environment untouched.
- **environment-merge-policy**: Under the merge-over-parent environment
  policy, a non-empty configured environment MUST be merged over the
  parent process's own environment, with the configured values winning on
  key collision; an empty configured environment MUST leave that merge a
  no-op.
- **send-applies-framing**: Sending a message MUST frame it using the
  channel's configured framing scheme before writing it to the child's
  standard input.
- **send-raw-unframed**: Sending raw bytes MUST write them to the child's
  standard input exactly as given, with no delimiter or header added,
  regardless of the channel's configured framing scheme.
- **send-call-order-preserved**: Two or more concurrent calls to send a
  message or send raw bytes on the same channel MUST reach the child's
  standard-input descriptor in the order those calls were made, because
  each call's write is submitted synchronously, while the channel is
  held, before the caller suspends to await completion.
- **write-after-close-throws**: A raw-bytes (or framed) send call made
  after the child's standard input has been closed (by closing input or by
  terminating) MUST throw an input-closed failure; a write attempted
  after the child has exited MUST throw an error derived from a
  broken-pipe condition rather than raising the SIGPIPE signal, because
  launching has already disabled SIGPIPE on that one descriptor.
- **close-input-orderly**: Closing input MUST flush every byte already
  submitted via a prior send call to the child before releasing the
  standard-input descriptor, so the child observes those bytes and only
  then end-of-file.
- **stderr-continuous-drain**: The channel MUST drain the child's standard
  error continuously on its own execution context, independent of both
  the channel's serialized calls and the standard-output message pump,
  rather than reading it only once at exit.
- **stderr-tail-cap**: The accumulated standard-error buffer MUST be
  capped at 1,048,576 bytes (1 MiB); once exceeded, the buffer MUST retain
  the most recently written bytes (the tail) and discard the oldest, and
  MUST record that truncation occurred.
- **stderr-text-decoding**: Reading standard-error text MUST decode the
  buffered bytes as UTF-8, and MUST fall back to Latin-1 decoding (which
  accepts every byte) when the buffer is not valid UTF-8, rather than
  returning an empty string.
- **stderr-text-diagnostic-prefixes**: Reading standard-error text MUST
  prepend `"[stderr truncated to the last 1048576 bytes]\n"` when the tail
  cap trimmed the buffer, and MUST prepend `"[stderr capture incomplete:
  the drain did not finish within 0.5s]\n"` when the bounded drain wait
  lapsed before the drain finished; either, neither, or both prefixes MAY
  appear together.
- **stderr-data-raw**: Reading standard-error bytes MUST return the
  buffered bytes exactly as captured, with no decoding, no re-encoding,
  and no diagnostic prefix of any kind.
- **stderr-drain-bounded-wait**: Reading standard-error text or bytes MUST
  wait no more than 0.5 seconds for the standard-error drain to finish
  before answering with whatever has been buffered so far; expiry of that
  wait MUST NOT be treated as an error.
- **exit-status-no-invented-value**: Waiting for exit MUST throw a
  not-launched failure when called on a channel that was never launched,
  and MUST throw a cancellation signal when the awaiting context is
  cancelled before the child exits; it MUST NOT return `0`, or any other
  value, for either case.
- **exit-status-multi-waiter-independence**: Cancelling one caller's
  wait-for-exit call MUST leave every other concurrent caller's
  wait-for-exit call on the same channel parked and unaffected, and MUST
  NOT touch the child process.
- **termination-sequence**: Terminating MUST perform, in order: stop the
  standard-input writer, cancelling any write in flight; send the
  graceful termination signal (SIGTERM) to the child if it is still
  running; wait up to 2.0 seconds for it to exit; send the forceful
  termination signal (SIGKILL) if it is still running after that wait;
  stop both standard-output/standard-error readers (the only point at
  which their descriptors close); then wait up to 0.5 seconds for the
  standard-output message pump to finish flushing and finishing the
  message stream.
- **termination-idempotent**: Terminating MUST be idempotent: a channel on
  which it has already run, or on which it is already running, MUST let
  every caller — concurrent or subsequent — observe the same completed
  teardown rather than starting a second one.
- **termination-uncancellable**: The work terminating performs MUST run
  independent of the calling context's own cancellation, so a caller that
  is itself cancelled while awaiting termination MUST NOT cause the child
  to be abandoned mid-teardown.
- **termination-preserves-trailing-frame-on-natural-eof**: When the
  child's standard output reaches end-of-file on its own — not because
  terminating tore the descriptor down — the message pump MUST flush the
  decoder's end-of-stream remainder and yield any frame it returns before
  finishing the message stream.
- **termination-suppresses-flush-on-forced-teardown**: When terminating
  itself ends the child's standard output (a forced teardown), the
  message pump MUST finish the message stream without flushing the
  decoder's end-of-stream remainder, so a partial newline-delimited line
  is never delivered as a whole frame and a content-length-prefixed
  shutdown is never reported as a truncated-message transport error.
- **termination-signal-scope**: Terminating's graceful and forceful
  signals MUST each target only the direct child process, never a process
  group; a grandchild the child itself spawned and backgrounds MUST NOT
  receive either signal from this operation — a caller that needs
  grandchildren reaped MUST arrange it in the command it launches, since
  this component exposes no process-group spawn option to use instead.
- **run-forces-unframed**: The one-shot run operation MUST set the framing
  scheme to unframed before constructing its channel, regardless of the
  framing value supplied in the configuration passed in.
- **run-captures-full-output**: The one-shot run operation MUST launch the
  channel, close its standard input immediately, and concatenate every
  chunk yielded by the message stream in arrival order to form the run
  result's standard output, reproducing the child's raw standard output
  byte-for-byte.
- **run-tolerates-exited-case**: The one-shot run operation MUST catch an
  exited failure thrown while draining the message stream and treat it as
  a normal end of that iteration rather than propagating it, tolerating a
  case the message stream does not currently throw but could in the
  future; every other channel failure thrown from that drain MUST
  propagate.
- **run-budget-enforcement**: The one-shot run operation MUST wrap its
  launch, drain, and exit-wait sequence in the wall-clock budget race, so
  a budget-exceeded failure thrown by that race propagates from the run
  operation unchanged.
- **run-terminates-on-every-path**: The one-shot run operation MUST
  terminate the channel on any thrown error including a budget-exceeded
  failure, before rethrowing.
- **run-result-shape**: On success, the one-shot run operation MUST return
  a run result whose standard error comes from reading standard-error
  text, whose exit status comes from waiting for exit, and whose duration
  is the wall-clock time elapsed between just before the run began and the
  moment the run result is constructed.
- **run-does-not-interpret-exit-status**: The one-shot run operation MUST
  NOT throw on a non-zero exit status in its run result; callers MAY treat
  a non-zero exit as success or failure at their own discretion, since the
  subprocess channel itself defines no notion of a non-zero exit being an
  error.
- **decoder-feed-chunk-sized-input**: Callers SHOULD feed the decoder
  chunks of realistic size rather than one byte at a time; per-byte
  feeding does not change the frames produced, but it defeats the
  decoder's scan-cursor optimization and turns every call into mostly
  wasted overhead.
- **budget-race-not-scoped-join**: The wall-clock budget race MUST
  implement its race between the operation and a timer as two
  independent, unstructured executions resumed through a single
  continuation, resumed exactly once, and MUST NOT use a structured join
  that would implicitly await the losing side before a timeout could ever
  be observed.
- **budget-cancels-not-awaits-loser**: When the timer wins the race, the
  wall-clock budget race MUST cancel the operation and throw a
  budget-exceeded failure (carrying the elapsed seconds) immediately,
  without awaiting that operation's completion.
- **budget-caller-cancellation-propagates**: Cancelling the context
  awaiting the wall-clock budget race MUST cancel both the operation and
  the timer and MUST rethrow a cancellation signal promptly, rather than
  waiting out either one.
- **budget-nan-starts-no-timer**: A `seconds` value of not-a-number MUST
  start no timer — the operation runs to completion or to the caller's own
  cancellation, unbounded by this call — rather than being treated as a
  zero-second budget.
- **budget-ceiling-starts-no-timer**: A `seconds` value at or above
  31,536,000 (60 × 60 × 24 × 365, one year), including positive infinity
  and the largest representable value, MUST start no timer.
- **budget-nonpositive-expires-immediately**: A `seconds` value at or
  below `0` (including negative infinity) MUST be treated as an immediate
  expiry — a zero-duration wait — not as "no budget."
- **descriptor-close-failure-silent**: Closing a descriptor MUST discard whatever error code the underlying close reports; a descriptor that fails to close (for example a double close, or a bad-file-descriptor error) is never logged, thrown, or otherwise surfaced to any caller.

