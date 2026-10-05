
- **dedicated-session**: The loader MUST build its own transport session
  from the configuration it is given (not reuse a caller-supplied session
  instance), so that a configuration the caller customized — including any
  injected protocol handlers — still governs the loader's own transfers.
- **delegate-object**: The loader's session MUST use a separate callback
  object (not the loader itself) to receive transport events, holding only
  a reference to the shared per-transfer state and nothing that points
  back to the loader.
- **body-transfer**: Reading a body at a given URL and limit MUST start an
  independent transfer on the loader's own session and, on success, return
  the accumulated body together with the response value once the transfer
  completes without the accumulated size exceeding the limit.
- **per-call-task**: Each call to read a body MUST start an independent
  transfer; a single loader instance MUST support multiple such calls,
  sequential or concurrent.
- **header-ceiling-check**: When a received response declares an expected
  length greater than the limit, the loader MUST refuse the transfer —
  cancelling it as soon as the response arrives — before any body chunk is
  read.
- **chunked-length-fallthrough**: A response that declares no expected
  length (for example, a chunked transfer encoding) MUST NOT be refused by
  the declared-length check; such a transfer MUST instead be bounded
  solely by the running per-chunk check below.
- **running-ceiling-check**: The loader MUST append each received chunk to
  a per-transfer running buffer, and once that buffer's size exceeds the
  limit it MUST cancel the underlying transfer and MUST discard the buffer
  (reset it to empty) rather than return, or continue to accumulate, a
  partial body.
- **overflow-error**: When a transfer is refused for exceeding the limit by
  either the declared-length check or the running check, reading the body
  MUST throw the too-large failure, carrying the response received before
  the refusal, or nothing when no response had yet been recorded.
- **status-agnosticism**: The loader MUST NOT itself inspect or validate
  the HTTP status code of any response; a non-2xx response's body is read
  (or refused for size) exactly as a 2xx response's would be, and its
  response value is what the too-large failure or a successful return
  carries back so the caller can make that status decision itself.
- **underlying-error-propagation**: When the transport reports a transfer's
  completion with an error and that transfer was not refused for size,
  reading the body MUST rethrow that error unchanged.
- **missing-response-fallback**: If a transfer finishes with neither an
  error nor any response ever recorded, reading the body MUST throw a
  bad-server-response error.
- **cooperative-cancellation**: Reading a body MUST cancel its underlying
  transfer when the calling context is cancelled, and MUST let the
  resulting failure reach the caller through the same error path as any
  other transport error.
- **concurrent-isolation**: The loader MUST keep each in-flight transfer's
  buffer, limit, response, and continuation isolated by that transfer's own
  identifier, guarded by one lock, so that concurrent calls to read a body
  on the same loader instance never corrupt or merge one transfer's
  accumulated data with another's.
- **concurrent-sharing-safe**: The loader MUST be safe to share across
  concurrent callers; a single instance MAY be used from multiple
  concurrent calling contexts without the caller adding synchronization of
  its own.
- **stale-callback-tolerance**: A transport callback naming a transfer
  identifier the shared state no longer tracks (already finished and
  removed) MUST be treated as a no-op — it MUST NOT throw or crash.
- **disposal-allows-in-flight-completion**: Disposing of the loader MUST
  let any in-flight transfers run to completion rather than aborting them.
- **no-automatic-retry**: The loader MUST NOT retry a failed or
  oversized transfer on its own; every failure — size or transport — is
  surfaced exactly once, to the caller, which decides whether to retry.
- **no-added-timeout**: The loader MUST NOT impose any timeout of its own
  beyond what the caller's session configuration already specifies for the
  request.
- **buffer-preallocation**: On accepting a response (the declared-length
  check does not refuse it), the loader SHOULD reserve capacity for the
  accumulated buffer sized from the declared expected length, clamped to
  zero-or-more and capped at 1,048,576 bytes (1 MiB) — a performance hint,
  not a correctness requirement, so a SHOULD deviation carries no
  behavioral risk.
- **failure-shape**: The loader's failure type MUST expose exactly one
  case, too-large (carrying an optional response value), as this
  component's sole error type.

