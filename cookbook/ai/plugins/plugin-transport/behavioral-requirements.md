
- **single-entry-point**: The plugin transport MUST expose exactly one public
  operation — running a request specification against a plugin, which
  returns a stream of stream events — as the sole way to drive a request.
- **stateless-invocation**: The plugin transport MUST hold no stored state of
  its own — it is a stateless namespace of operations, not an instance — so
  two concurrent, independent calls to run a spec MUST NOT interfere with one
  another; each call creates its own unit of work, its own decoder, and (for
  a command spec) its own subprocess channel.
- **transport-dispatch**: Running a request specification MUST dispatch on
  the spec's transport kind — HTTP to the HTTP path, command to the command
  path — and MUST NOT perform both for a single spec.
- **wall-clock-enforcement**: Running a request specification MUST wrap
  whichever transport path it dispatches to in a wall-clock budget bounded by
  the spec's timeout, bounding the entire request — connection, streaming,
  and (for a command) process exit — by wall-clock time rather than by an
  idle timeout that resets on every received byte.
- **timeout-error-mapping**: Running a request specification MUST catch a
  thrown budget-exceeded condition and finish the returned stream with a
  timed-out error carrying the elapsed seconds in its place, never surfacing
  the budget-exceeded condition itself to the caller.
- **error-passthrough**: Running a request specification MUST propagate any
  error other than the budget-exceeded condition to the stream's consumer
  unchanged, without wrapping it in a transport-error case.
- **stream-completion-on-success**: Running a request specification MUST
  finish the stream with no error once the dispatched transport path returns
  without throwing.
- **consumer-cancellation-propagation**: Running a request specification MUST
  cancel its internal unit of work when the returned stream's consumer stops
  iterating or is cancelled.
- **http-request-construction**: The HTTP path MUST build a request from the
  spec's URL, setting its method to the spec's method, applying every header
  entry, and setting the request body to the spec's body.
- **http-idle-timeout-set**: The HTTP path MUST also set the request's own
  idle-timeout value to the spec's timeout, even though this alone is an idle
  timeout that resets on every received byte and is therefore insufficient
  as a wall-clock bound — the wall-clock guarantee comes only from
  wall-clock-enforcement above.
- **http-streaming-fetch**: The HTTP path MUST fetch the response by
  streaming its bytes as they arrive rather than buffering the complete
  response before any processing begins.
- **http-response-type-check**: The HTTP path MUST throw an invalid-response
  error if the received response is not a well-formed HTTP response.
- **http-success-range**: The HTTP path MUST treat a response as successful
  if and only if its status code falls in 200–299; every other status code
  MUST be treated as a failure.
- **http-error-body-drain**: On a non-2xx status, the HTTP path MUST fully
  drain the response body into a buffer before asking the plugin to describe
  the error from it.
- **http-error-message-fallback**: On a non-2xx status, the HTTP path MUST
  use the plugin's error-description operation's returned string as the
  resulting error's message when it is non-empty, and MUST fall back to the
  literal string "HTTP <status>" when the plugin declines to describe it,
  then MUST throw an HTTP-failure error carrying the status and message.
- **http-success-decode**: On a 2xx status, the HTTP path MUST ask the plugin
  for a fresh decoder exactly once and pass the still-streaming response
  bytes and that decoder to the byte-pumping logic.
- **command-channel-configuration**: The command path MUST construct its
  subprocess channel with a replace-the-environment policy and
  newline-delimited framing, using the spec's executable path, arguments, and
  environment verbatim.
- **command-launch**: The command path MUST launch the child process before
  writing any standard input or reading any output.
- **command-stdin-write**: The command path MUST write a non-empty standard
  input payload to the channel unframed, never through the framing-aware
  send operation, so no delimiter is appended to the payload.
- **command-stdin-close**: The command path MUST close the channel's input
  unconditionally immediately after the standard-input write step, whether
  or not standard input was supplied, so the child always sees end-of-file on
  its input.
- **command-frame-consumption**: The command path MUST ask the plugin for a
  fresh decoder exactly once, then feed every frame produced by the
  channel's message stream to that decoder and yield each returned event to
  the continuation, in the order the frames arrive.
- **command-finish-before-status**: The command path MUST check for
  cancellation, and — only if that check does not throw — flush the
  decoder's trailing state and yield its events, before awaiting the child's
  exit status, so a completed answer is always delivered before the
  transport asks whether the child succeeded.
- **command-finish-skipped-on-cancellation**: If that cancellation check
  throws at that checkpoint, the command path MUST propagate the resulting
  error and MUST NOT flush the decoder's trailing state — a cancelled run
  never receives a flush of the decoder's trailing state.
- **command-exit-status-check**: The command path MUST await the child's
  exit status and treat exactly a zero status as success.
- **command-terminate-always**: The command path MUST terminate the channel
  once the exit status is known, on both the success and the failure branch
  of the status check, and MUST terminate it again from its outer
  failure-recovery step if any earlier step throws, so termination runs
  exactly once on the success path and again as cleanup on every throwing
  path.
- **command-nonzero-exit-error**: On a nonzero exit status, the command path
  MUST fetch the child's raw standard-error bytes — never a decoded text
  form — and pass them unmodified to the plugin's error-description
  operation, falling back to the literal string "Command exited with status
  <status>" when the plugin declines to describe it, then MUST throw a
  command-failure error carrying the status and message.
- **command-cleanup-rethrows-original-error**: The command path's outer
  failure-recovery step MUST terminate the channel and then rethrow the
  original caught error unchanged — it MUST NOT substitute or wrap that
  error.
- **byte-pump-line-framing**: The byte-pumping logic MUST accumulate incoming
  bytes into a buffer and, on each byte equal to the newline byte, feed the
  decoder the buffer including that trailing newline byte, then clear the
  buffer.
- **byte-pump-cancellation-check**: The byte-pumping logic MUST check for
  cancellation once for every byte received, before appending it to the
  buffer.
- **byte-pump-trailing-remainder**: Once the byte sequence ends, the
  byte-pumping logic MUST feed the decoder any remaining non-empty,
  unterminated buffer content; it MUST NOT feed the decoder an empty buffer.
- **byte-pump-finish-call**: The byte-pumping logic MUST flush the decoder's
  trailing state and yield its events exactly once, after the
  trailing-remainder step, whenever the byte loop completes without
  throwing.
- **byte-pump-cancellation-skips-finish**: If the cancellation check throws
  inside the byte loop, the byte-pumping logic MUST propagate that error
  immediately and MUST NOT reach the trailing-remainder or flush steps.
- **decoder-per-request**: Both the HTTP path and the command path MUST ask
  the plugin for a fresh decoder exactly once per run invocation, never
  reusing a decoder instance across two requests.
- **decoder-task-confinement**: The decoder created for one run invocation
  MUST be created and consumed only inside the single unstructured unit of
  work that running a request specification starts — never handed to, or
  invoked from, any other concurrent execution context — matching the
  decoder's own not-shareable-across-contexts contract (see the sibling
  stream-event recipe).
- **single-attempt**: Running a request specification MUST perform the
  described request exactly once per invocation; there is no retry loop,
  backoff, or repeated attempt at either transport path for a single run
  invocation.
- **subprocess-cancellation-eager-kill**: For a command request, cancelling
  the task that iterates the returned stream MUST terminate the child
  process eagerly rather than waiting for it to exit on its own terms —
  cancelling that task cancels the frame-consuming loop over the channel's
  message stream, whose termination cancels the subprocess channel's own
  internal pump, whose cancellation handler signals the child.
- **raw-error-passthrough**: Any failure that is neither a non-2xx HTTP
  status nor a nonzero subprocess exit (for example a connectivity failure,
  or a launch failure from the subprocess channel itself) MUST reach the
  stream's consumer as its original, unwrapped error, with neither transport
  path catching or reclassifying it further.

