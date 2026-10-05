
- **switch-key-identity**: The debug launch switch MUST store the given key
  string verbatim and unchanged; the key MUST serve both as the
  settings-store key that reading the switch's enabled state looks up and as
  the launch-argument name a caller passes when the process is launched with
  that argument set.
- **switch-immutable-thread-safe**: The debug launch switch MUST be an
  immutable value with its key as its only stored data, so an instance MUST
  be safe to read from any thread concurrently without additional
  synchronization.
- **default-defaults-source**: The switch's enabled state, read with no
  store specified, MUST forward to reading it against the standard/default
  settings store.
- **injectable-defaults-parameter**: Reading the switch's enabled state MUST
  accept its settings-store source as a parameter rather than reading the
  default store internally, so a caller MAY supply an isolated settings
  store instead of the real one.
- **debug-build-reads-argument-domain**: Reading the switch's enabled state,
  when built in a debug configuration, MUST return the stored boolean value
  for its key from the supplied settings store (whose lookup includes the
  process's launch arguments).
- **release-build-always-off**: Reading the switch's enabled state, when
  built in a release configuration, MUST return `false` unconditionally,
  without reading the supplied settings store at all — the switch MUST be
  unreachable in a release build regardless of any launch argument,
  preference, or profile passed to it.
- **quiet-activation-gate**: The conditional activation operation MUST
  return immediately, without performing unconditional application
  activation, when the quiet presentation gate is enabled.
- **loud-activation-behavior**: The conditional activation operation MUST
  perform unconditional application activation when the quiet presentation
  gate is disabled.
- **test-host-detection**: Test-host detection MUST return `true` if and
  only if the test framework's marker type can be resolved in the current
  process, and MUST return `false` otherwise.
- **sink-level-only**: The sink-behind-desktop operation MUST change only
  the window's z-order level, setting it to the desktop's window level, and
  MUST NOT hide the window, close it, or change its visibility or opacity.
- **quiet-order-front**: The quiet order-front operation MUST perform the
  sink-behind-desktop operation before ordering the window to the front
  when the quiet presentation gate is enabled, and MUST perform only the
  front-ordering step when the gate is disabled.
- **quiet-make-key-and-order-front**: The quiet make-key-and-order-front
  operation MUST perform the sink-behind-desktop operation before making the
  window key and ordering it to the front when the quiet presentation gate
  is enabled, and MUST perform only the make-key-and-order-front step when
  the gate is disabled.
- **level-set-before-ordering**: The quiet order-front and quiet
  make-key-and-order-front operations MUST set the window's level before
  performing their ordering step, so the window MUST NOT be visible at the
  normal level even briefly on its way to the sunk level.
- **quiet-operations-run-on-main-thread**: The quiet order-front and quiet
  make-key-and-order-front operations MUST run on the main/UI thread; the
  sink-behind-desktop operation and test-host detection carry no such
  constraint of their own.
- **quiet-presentation-runs-on-main-thread**: The quiet presentation gate
  MUST be confined to the main/UI thread as a whole, so every one of its
  operations — reading its enabled state, resolving the quiet-presentation
  decision, and its underlying switch access — MUST be confined to that
  thread.
- **debug-switch-fixed-key**: The quiet presentation gate's underlying
  switch MUST be constructed with a fixed literal key, `"QuietWindowPresentation"`.
- **defaults-key-alias**: The quiet presentation gate's exposed settings key
  MUST return the underlying switch's key exactly, i.e. the same string
  `"QuietWindowPresentation"`.
- **is-enabled-live-read**: The quiet presentation gate's enabled state MUST
  evaluate the resolve step (test-host detection OR-ed with the underlying
  switch) freshly on every access; it MUST NOT cache or memoize the result.
- **resolve-or-precedence**: Resolving the quiet-presentation decision MUST
  return `true` when the test-host input is `true`, and otherwise MUST
  return the underlying switch's enabled state, read against the supplied
  settings store.
- **test-host-short-circuits-defaults-read**: Because the OR evaluation
  short-circuits, resolving the quiet-presentation decision MUST NOT
  evaluate the underlying switch's enabled state — and therefore MUST NOT
  read the supplied settings store at all — when the test-host input is
  `true`.

