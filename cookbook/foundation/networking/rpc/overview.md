
This component is the non-UI logic root for talking to a child process as
if it were an RPC peer. It has four parts:

- A framing scheme describing how a byte stream is split into discrete
  messages: newline-delimited (a frame is the byte-exact slice up to and
  including its trailing linefeed byte), content-length-prefixed (a frame
  is the body only, with its `Content-Length: <n>\r\n...\r\n\r\n` header
  consumed and discarded), and unframed (a stream with no message
  boundaries at all, where a "frame" is whatever chunk of bytes arrived).
  Encoding a message for a given scheme is the framing operation.
- An incremental decoder that turns arbitrary byte chunks (never aligned to
  message boundaries) into complete frames, one chunk at a time, and
  flushes any end-of-stream remainder on request. It caps any single
  buffered frame at 16 MiB and recovers from a peer that exceeds that cap
  without losing frames already completed in the same call or letting the
  rejected frame's own bytes resynchronize the stream.
- The subprocess channel that spawns a child process and exposes its
  standard output as an asynchronous stream of frames decoded by the
  framing decoder, its standard input as a place to send framed or raw
  bytes, and its standard error as a continuously drained, capped buffer.
  It owns launch, environment policy, and a termination sequence (a
  graceful signal, then a forceful one, then reader teardown) that
  distinguishes a child ending its own output from one this operation
  killed.
- A one-shot run operation and a general wall-clock race — a one-shot
  helper that launches a channel, drains all of standard output as
  unframed regardless of the caller's configured framing, and returns a
  run result; and the general wall-clock race it (and the plugin
  transport, see `related`) uses to bound any asynchronous operation,
  cancelling — never awaiting — the loser.

This is the one shared replacement for what had been several independent
process-plus-three-pipes implementations in the codebase.

