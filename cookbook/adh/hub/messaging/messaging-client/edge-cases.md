
- **Blank required fields**: `"channel"` and `"userId"` blank MUST be rejected by the shared
  form validator (`"Customer ID is required"`) before the save action's own body ever runs (MUST).
- **Blank conditionally-required fields**: `"subject"` (email freeform), `"body"` (any freeform),
  and `"recipient"` (SMS) are not field-level required, so a blank value MUST be caught by the save
  action's own checks instead, in the order recipient (SMS only) → subject (email freeform only) →
  body (MUST).
- **Blank or whitespace-only `templateVars`**: MUST parse to an empty key-value object rather than
  throwing, given a trim-and-blank check (MUST).
- **Template with no placeholders**: MUST be sendable with `templateVars` empty, since the
  placeholder-validation loop has nothing to iterate (MUST).
- **Boundary: exactly `logPageSize` (100) log entries**: the log level MUST render all 100 without
  requesting a second page; entries beyond 100 are not shown (see **log-pagination**) (MUST).
- **Malformed `templateVars` JSON**: parsing fails with a validation error ("Invalid JSON: ...")
  for text that is not valid JSON at all (not just not-an-object), and that error MUST propagate
  through the save action unchanged, since parsing the template variables does not catch it (MUST).
- **Concurrent access**: this logic holds no mutable stored state, so no synchronization primitive
  is needed within one instance; nothing here coordinates two independent form instances (for
  example two open Send forms) submitting against the same ecosystem concurrently — each send is
  validated and dispatched independently, and both would be recorded as separate log entries with
  no deduplication (this is an absent feature, not a race this recipe documents any ordering rule
  for; MUST NOT be assumed to be serialized).
- **Error states**: the template-listing, log, and send operations' failures MUST propagate
  unchanged (wrapped into the common error type) to the caller; the status operation's failures
  MUST instead degrade to the absent-status status line / a per-channel "Couldn't check..." banner
  rather than blocking the rail or the Send form (MUST, per `rail-status-swallowed-at-top-level` /
  `send-detail-status-swallowed`).
- **Offline or unreachable backend**: an offline or transport error thrown by the template-listing,
  log, or send operations MUST propagate unchanged; a status-operation offline failure is swallowed
  instead, so a user can still open and fill out the Send form while offline, only to have the send
  itself throw when actually attempted (MUST).
- **Cancellation**: every data-source call has no explicit cancellation handling in this logic
  beyond what the underlying asynchronous runtime provides by default; a surrounding cancellation
  is expected to propagate as a thrown error through the same path any other error takes, so it is
  wrapped into the common error type (or, for the status operation, swallowed) exactly like any
  other failure (MUST — this is a guarantee the runtime provides with no extra code, not a gap).
- **Unrecognized send-result status**: any value other than the literal string `"sent"` (including
  an unrecognized one such as `"queued"`) MUST be treated as a failure and reported via the save
  error, never as success (MUST).

