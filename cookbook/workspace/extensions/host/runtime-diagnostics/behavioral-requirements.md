
- **jit-value-shape**: The JIT availability value MUST be an immutable
  value with exactly two fields — a hardened-runtime flag and a
  JIT-entitlement flag, both booleans — and constructing it MUST assign both
  values directly with no validation.
- **jit-degraded-definition**: The degraded state MUST be true only when the
  hardened-runtime flag is set and the JIT-entitlement flag is absent, and
  false in every other combination, including when the hardened-runtime flag
  is unset (where the entitlement flag is irrelevant).
- **jit-diagnosis-nil-when-healthy**: The diagnosis message MUST be absent
  whenever the degraded state is false.
- **jit-diagnosis-content**: When the degraded state is true, the diagnosis
  message MUST be a fixed, non-empty sentence naming
  `com.apple.security.cs.allow-jit` as the missing entitlement, stating that
  extensions will run but every one of them interpreted, and naming
  `App.entitlements` as where the fix belongs.
- **jit-current-memoized-once**: The process-wide cached value MUST be
  computed by probing exactly once for the life of the process, and MUST
  return that same value on every later read for the rest of the process's
  lifetime.
- **jit-probe-live-each-call**: Probing MUST re-read the hardened-runtime
  flag and the JIT-entitlement flag fresh on every invocation, independent
  of whatever the process-wide cached value has already memoized.
- **jit-hardened-flag-read**: Reading the hardened-runtime flag MUST derive
  its answer from this process's own code-signing information, read as a
  flags value, and test it against the hardened-runtime bit (Platform
  Notes: SwiftUI — the exact call chain and bit mask).
- **jit-hardened-read-failure-is-false**: Reading the hardened-runtime flag
  MUST return false, never throw or crash, when any step of that reading
  fails — an unreadable code object, signing information that cannot be
  parsed, or a missing flags value.
- **jit-entitlement-read**: Reading the JIT-entitlement flag MUST read the
  `com.apple.security.cs.allow-jit` entitlement off this process's own task,
  and MUST return false when the process's task cannot be read or the
  entitlement value is not a boolean (Platform Notes — the exact
  calls).
- **jit-log-once-per-process**: Logging when degraded MUST write the
  diagnosis message to the diagnostic log at most once for the process's
  entire lifetime, however many times or from however many call sites it is
  invoked.
- **jit-no-log-when-healthy**: Logging when degraded MUST NOT write
  anything to the log when the diagnosis message is absent.
- **jit-log-privacy**: The one log line logging when degraded can produce
  MUST mark the diagnosis message as safe to disclose in full, not
  redacted, in the logging system's metadata.
- **jit-logging-category**: Logging for the JIT availability value MUST use
  a log category named after the value's own name and a subsystem
  identifying the host application.
- **divergence-value-shape**: A divergence catalogue entry MUST be an
  immutable, identifiable, serializable value with exactly the six fields
  `id`, `area`, `upstreamBehaviour`, `ourBehaviour`, `rationale`, and
  `detection`.
- **divergence-detection-cases**: The detection kind MUST have exactly two
  named cases, `counted` and `declared`, each represented as those exact
  strings wherever the value is serialized.
- **divergence-public-init**: Constructing a divergence catalogue entry
  MUST be available to any caller and MUST assign all six fields directly,
  with no validation, normalization, or default value.
- **divergence-known-catalogue**: The known catalogue MUST be the single
  list a consumer iterates to enumerate "every divergence this app knows
  about" — a divergence entry defined elsewhere but omitted from the known
  catalogue MUST remain individually addressable but MUST NOT appear to any
  caller that iterates the known catalogue.
- **divergence-known-fixed-membership**: The known catalogue MUST contain
  exactly six entries in this fixed order: `documentOutsideWorkspaceScope`,
  `semanticTokenLineOutOfRange`, `semanticTokenModifiersIgnored`,
  `semanticTokenMultilineUnsupported`, `semanticTokenOverlapDropped`,
  `semanticTokenTypeUnmapped`.
- **divergence-ids-unique**: Every entry in the known catalogue MUST have a
  distinct `id` string.
- **divergence-fields-nonempty**: Every entry in the known catalogue MUST
  have a non-empty `id`, `area`, `upstreamBehaviour`, `ourBehaviour`, and
  `rationale`.
- **divergence-detection-mix**: The known catalogue MUST contain at least
  one entry of each detection kind, and the number of `counted` entries MUST
  be greater than or equal to the number of `declared` entries (currently
  five `counted` entries and one `declared` entry).
- **hit-value-shape**: A divergence hit record MUST be an immutable,
  identifiable value with exactly the five fields `divergence`, `detail`,
  `firstSeen`, `lastSeen`, and `count`.
- **hit-identity-key**: A divergence hit record's identity MUST be computed
  as its divergence's `id` and its `detail` joined by the ASCII
  unit-separator character `\u{1F}` — never a generated identifier.
- **ledger-shared-instance-available**: The ledger MUST expose one
  process-wide shared instance usable safely from any thread, and MUST also
  leave direct construction available so a caller (a test, or another host)
  MAY build an independent ledger instead of using the shared one.
- **ledger-record-noop-nonpositive**: Recording a hit MUST perform no row
  write, no log write, and no publish when the given count is zero or
  negative.
- **ledger-record-default-count-one**: Recording a hit with no count given
  MUST record exactly one occurrence.
- **ledger-row-key-by-detail**: A ledger row MUST be keyed by the pair of
  the divergence's `id` and the caller-supplied `detail` string — two
  recordings for the same divergence but different `detail` values MUST
  produce two independent rows, never merged into one.
- **ledger-row-accumulates**: A second recording for a key that already has
  a row MUST add its count to the existing row's count, MUST replace
  `lastSeen` with the current time, and MUST leave `firstSeen` unchanged
  from the row's original creation.
- **ledger-write-serialization**: Every read and every write of the
  ledger's rows MUST be mutually exclusive, so that concurrent recording,
  clearing, and reading calls from different threads MUST NOT corrupt the
  rows or lose an update (confirmed by a test that fires 200 concurrent
  recordings for one key and observes all 200 counted).
- **ledger-first-hit-logs-once**: Recording a hit MUST write an info-level
  diagnostic log line containing the divergence's `id` and its
  `ourBehaviour` text, marked safe to disclose in full, only on the call
  where the key has no existing row (the key's first-ever hit); every later
  recording for that same key MUST NOT log again.
- **ledger-hits-sorted**: Reading all rows or reading the rows for one
  divergence MUST return them sorted by the pair `(divergence.id, detail)`,
  never in insertion or arrival order.
- **ledger-hits-for-filters**: Reading the rows for one divergence MUST
  return only the rows whose key's divergence id equals the given
  divergence's `id`.
- **ledger-publisher-current-value**: The ledger's live rows publisher MUST
  deliver its current value immediately to a new subscriber, even if no
  recording or clearing happens afterward.
- **ledger-every-mutation-publishes**: Both recording (when the count is
  positive) and clearing MUST publish exactly once per call, each sending a
  fresh snapshot of the current rows to every subscriber.
- **ledger-clear-empties**: Clearing MUST remove every row from the ledger
  and then publish an empty list to subscribers; it MUST NOT touch
  `firstSeen`/`lastSeen` bookkeeping for any row, because it discards the
  rows themselves rather than resetting a per-row field.
- **ledger-publish-lock-ordering**: Publishing MUST guarantee that two
  publish operations racing from different threads deliver to subscribers
  in the same order their respective row mutations actually committed, and
  MUST NOT deliver a stale snapshot after a newer one (Platform Notes — implemented as a second exclusion around the snapshot-and-send
  step).
- **ledger-logging-category**: Logging for the divergence ledger MUST use a
  log category named after the ledger's own name.

