
### Session Lifecycle

- **start-is-idempotent-and-joined**: starting the session MUST let a
  concurrent second caller join an in-flight start rather than spawn a
  second process, and every joined caller MUST observe the same outcome as
  the original caller.
- **start-after-stop-refused**: starting the session MUST throw a
  stopped-session error rather than spawn a new process once the session
  has been stopped.
- **concurrent-start-propagates-shared-failure**: when a joined start
  attempt fails, every joiner — the original caller and every later caller
  — MUST throw that same failure.
- **capabilities-only-while-running**: reading the session's capabilities
  MUST return nothing unless the session's state is running and its server
  connection still exists; the completion delegate relies on this as the
  only gate.
- **capabilities-go-nil-after-spontaneous-death**: once a running server
  dies on its own, reading the session's capabilities MUST answer nothing
  on every subsequent call.
- **outstanding-requests-block-teardown**: tearing the session down MUST
  wait, up to a fixed outstanding-request budget, for every in-flight
  request being tracked before shutting the server down.
- **stop-idempotent**: stopping the session MUST be safe to call more than
  once; a second call MUST NOT re-run teardown or overwrite a state the
  first call already reached.
- **stop-after-spontaneous-death-skips-budget**: stopping the session after
  a server has already died on its own MUST return without waiting out the
  graceful-shutdown budget.
- **stop-preserves-failed-state**: stopping the session MUST leave the
  state failed rather than overwrite it to stopped when the session had
  already failed before being stopped.
- **stop-during-start-does-not-orphan**: stopping the session while it is
  still spawning the process MUST NOT crash the process and MUST NOT leave
  the child process running.
- **state-changes-terminal-ordering**: the state-change stream MUST finish
  only after its terminal state value has been yielded, never before.
- **published-diagnostics-independent-of-state-changes**: the
  published-diagnostics stream MUST finish only via tearing the session
  down (or never, if the server dies without that happening) — unlike the
  state-change stream, reaching a terminal state does not by itself finish
  it.
- **stream-end-diagnosis-first-cause-wins**: when the channel ends,
  recording the end cause MUST record the first failure cause observed and
  MUST ignore later, redundant reports of the same end.
- **initialize-request-framed-once**: the `initialize` request MUST reach
  the server exactly once per session start.
- **initialize-response-round-trips**: a framed `initialize` response MUST
  decode back into the session's capabilities unchanged.
- **initialize-declares-only-honourable-capabilities**: the declared client
  capabilities MUST declare `snippetSupport`, `commitCharactersSupport`,
  `overlappingTokenSupport`, and `multilineTokenSupport` as `false`,
  matching renderer limitations the client cannot actually honor.
- **truncated-frame-fails-session**: a transport error that truncates a
  response frame mid-body MUST fail the session's start with that
  transport error rather than hang or silently succeed.
- **stderr-captured-on-failed-start**: standard error text emitted by a
  server process that dies during start MUST be captured and exposed as
  part of the reported failure.
- **unasked-exit-is-a-failure**: a clean process exit not requested by
  stopping the session MUST be reported as failed, never treated as an
  ordinary shutdown.

### Registry and Configuration Reconciliation

- **user-config-replaces-not-merges-builtin**: computing the effective
  configuration set MUST replace a built-in configuration for a language id
  entirely with the user's configuration for that id, never merge fields
  between them.
- **unrelated-builtin-survives**: a user configuration for one language id
  MUST leave the built-in configuration for every other language id
  untouched.
- **builtin-sourcekit-lsp-fixed-identity**: the built-in configurations
  MUST ship a fixed-identifier (`1CE31A0E-0000-4000-A000-5357494654FF`)
  SourceKit-LSP configuration claiming `swift`, `objective-c`,
  `objective-cpp`, `c`, and `cpp`, with command `/usr/bin/sourcekit-lsp` and
  root markers `Package.swift`, `*.xcodeproj`, `*.xcworkspace`, `.git`.
- **root-marker-walk-innermost-first**: resolving the workspace root MUST
  walk upward from the starting path and stop at the nearest ancestor
  directory containing any marker, including glob-suffix markers like
  `*.xcodeproj`.
- **marker-order-does-not-affect-root**: the order markers are listed in
  MUST NOT change which directory the workspace-root resolution resolves
  to.
- **unmatched-marker-resolves-nil**: when no ancestor directory contains
  any marker, resolving the workspace root MUST resolve to nothing rather
  than loop indefinitely.
- **session-rooted-at-marker-not-workspace**: reconciling the desired
  sessions MUST root a session's working directory at the resolved marker
  directory, not at the outer workspace root.
- **reconcile-diffs-desired-vs-current**: reconciling the desired sessions
  MUST diff the desired session set against the current one by descriptor
  equality, starting only sessions whose descriptor changed and retiring
  only those superseded.
- **secret-change-triggers-replacement**: a change to a configuration's
  secrets MUST count as a descriptor change that replaces the running
  session, so the new secret reaches the replacement session's
  environment.
- **disabling-tears-down-session**: setting a configuration's enablement to
  disabled MUST tear down its running session.
- **command-change-replaces-session**: changing a configuration's launch
  command MUST replace its running session.
- **observe-state-refuses-second-observer**: observing a session's state
  MUST refuse (log at fault level, return failure) a second concurrent
  observation of the same session id rather than deliver a doubled stream.
- **retired-session-late-transition-cannot-overwrite**: a state transition
  delivered by a session after it has been retired and replaced MUST NOT
  overwrite the published session-state table's entry for the session that
  replaced it.
- **shutdown-is-terminal**: shutting the registry down MUST set its
  shut-down flag before its first suspension point and MUST stop every
  session concurrently.
- **shutdown-waits-for-retired-teardowns**: shutting the registry down MUST
  wait for a session that reconciliation had already begun retiring before
  shutdown started.
- **settings-write-during-shutdown-starts-nothing**: a configuration change
  delivered while shutdown is in flight MUST start no new session.
- **session-states-never-outruns-configurations**: the published
  session-state table MUST never hold an id whose configuration is not
  also present in the current configuration set.

### Document Sync

- **per-session-ordered-queue**: the document-sync pipeline MUST maintain
  exactly one ordered event queue per session (not per document), and
  enqueueing an event MUST preserve the caller's emission order.
- **sync-capability-resolved-once**: running the pipeline MUST resolve the
  session's resolved sync capability exactly once per pipeline run, before
  forwarding any queued event.
- **open-close-defaults-true**: resolving the sync capability MUST default
  `openClose` to `true` when the server's capability omits it.
- **change-reopens-unopened-document**: forwarding a change MUST send
  `didOpen` for a document before forwarding a `didChange` for it, when the
  server has not yet been told the document is open.
- **saved-gating-is-asymmetric**: forwarding of save events MUST NOT be
  gated on the tracked open-URI set, unlike change and close events — a
  deliberate asymmetry documented in source, not an oversight.
- **incremental-sync-forwards-verbatim**: when the resolved sync kind is
  incremental, forwarding a change MUST forward the store's change array
  verbatim.
- **full-sync-forwards-whole-document**: when the resolved sync kind is
  full, each edit MUST be forwarded as exactly one whole-document
  `didChange`.
- **text-and-version-captured-together**: each `didChange` MUST carry the
  document's text as of the same version it reports, never a text/version
  pair captured across an intervening edit.
- **failed-start-pipeline-forwards-nothing**: a pipeline whose session
  start failed MUST NOT retry the start and MUST forward none of its
  queued events.
- **not-running-logged-as-debug**: logging a forwarding failure MUST log a
  not-running forwarding failure at debug level; every other forwarding
  failure MUST log at error level.
- **open-close-disabled-still-sends-change**: when the resolved capability
  disables `openClose`, the pipeline MUST send no `didOpen`/`didClose` but
  MUST still send `didChange`.
- **reconcile-retires-stale-before-adding**: reconciling pipelines with the
  current sessions MUST retire pipelines for sessions no longer present
  before starting pipelines for newly reconciled sessions.
- **addpipeline-joins-in-flight-registry-start**: adding a pipeline's own
  start call MUST join a registry-reconciliation-initiated start already
  in flight for the same session, rather than starting the session a
  second time.
- **replay-matches-claimed-language-only**: replaying already-open
  documents MUST seed a newly connected session only with already-open
  documents whose language id the session's configuration claims.
- **session-replacement-rebuilds-pipeline**: replacing a session MUST hand
  the new session the currently open documents and MUST send the old
  session's pipeline nothing further.
- **out-of-scope-documents-silently-excluded**: checking workspace scope
  MUST exclude a document outside the workspace root from being opened,
  changed, or replayed to any session, producing no server notification at
  all.
- **scope-check-resolves-symlinks**: checking workspace scope MUST resolve
  and standardize both the document path and the workspace root before
  comparing path components, so a symlinked root or a mismatched
  temp-directory alias does not misclassify an in-scope document as out of
  scope.
- **string-prefix-sibling-excluded**: a sibling directory whose path is a
  string prefix of the workspace root MUST be classified out of scope, not
  admitted by a naive prefix compare.
- **out-of-scope-replay-skipped**: replaying already-open documents MUST
  NOT replay a document already open outside the workspace root to a newly
  connected session.
- **out-of-scope-refusals-counted-once-per-batch**: recording an
  out-of-scope refusal MUST record refusals encountered while seeding a
  session in one ledger entry per seeding pass, not one entry per document.
- **clean-seeding-pass-records-nothing**: a seeding pass that refuses
  nothing MUST NOT write any entry to the divergence ledger.

### Diagnostics

- **observe-is-idempotent-per-session**: beginning to observe a session
  MUST be idempotent for a given session, keyed by object identity —
  calling it again for a session already observed MUST NOT start a second
  consumer of that session's single-consumer published-diagnostics stream.
- **stale-diagnostics-never-dropped**: diagnostics published with a
  missing or older version MUST still be stored and MUST NOT be discarded,
  even though the version field is optional and frequently absent.
- **publishes-land-in-send-order**: two publishes for the same URI MUST
  leave the store holding the second (most recently sent), reflecting send
  order regardless of version.
- **empty-diagnostics-clears-not-ignored**: an empty diagnostics array
  published for a URI MUST clear that URI's stored diagnostics, not be
  treated as a no-op.
- **document-diagnostics-pruned-on-close**: observing documents in a
  project MUST forget a document's stored diagnostics once its last editor
  closes it (a close event with the document's reference count reaching
  zero).
- **shutdown-idempotent-preserves-diagnostics**: shutting the diagnostics
  store down MUST be safe to call more than once and MUST leave
  already-stored diagnostics intact — it stops observation, it does not
  clear state.
- **retired-session-does-not-block-later-observation**: once a session's
  stream ends, a later session MUST still be observed normally.
- **publishes-in-send-order-across-n**: N publishes for a session MUST
  arrive at the store in the order they were sent.
- **published-stream-finish-is-observed**: the store MUST recognize that a
  session's published-diagnostics stream has finished, both when the
  session stops cleanly and when it fails to start.

### Transport

- **stream-end-handler-called-exactly-once**: the stream-end handler MUST
  be invoked exactly once per channel, with nothing denoting a clean end.
- **drain-called-after-terminate**: callers MUST drain the channel only
  after terminating the underlying subprocess channel, never before.

### Security

- **secrets-keyed-by-id-then-env-var**: the per-server secrets store MUST
  key each server's secret values first by the configuration's id, then by
  environment-variable name.
- **secrets-stored-in-keychain-not-plain-settings**: the persisted secrets
  setting MUST be declared secure, routing stored secret values through
  the platform's secure credential storage rather than the plain settings
  provider used for the persisted server-configurations setting.
- **secrets-merged-into-environment-only-at-session-start**: a server's
  secret environment values MUST be merged into the subprocess environment
  only when a session starts, never persisted anywhere else in plaintext
  by this component.
- **command-path-not-validated**: an absolute launch command is a caller
  precondition the configuration's own documentation states (the host
  application's own PATH differs from a terminal's). The component does
  not check it before spawning the process, so a relative or bare-name
  value resolves against the subprocess's inherited working directory.

