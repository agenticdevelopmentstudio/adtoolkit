
- **Null and empty input**: The debug launch switch's constructor takes a
  required, non-optional key and performs no validation; an empty string is
  accepted and stored as the key, and looking up an empty key in the
  settings store is a legal (if useless) lookup that never crashes (MUST,
  see **switch-key-identity**).
- **Boundary values**: The only boundary in this component is the
  compile-time debug/release configuration split itself, exercised by the
  two branches of the enabled-state read (MUST, see
  **debug-build-reads-argument-domain** and **release-build-always-off**);
  there is no numeric range or size to bound.
- **Concurrent access**: The debug launch switch is an immutable value type,
  so concurrent reads of its enabled state from multiple threads require no
  synchronization of their own (MUST, see **switch-immutable-thread-safe**).
  The quiet presentation gate and the two quiet window-presentation
  operations are confined to the main/UI thread by declaration, so access to
  the gate's enabled state, the resolve step, and the quiet
  order-front/quiet make-key-and-order-front operations is serialized (MUST,
  see **quiet-presentation-runs-on-main-thread**,
  **quiet-operations-run-on-main-thread**). The sink-behind-desktop operation
  and test-host detection carry no such constraint of their own; nothing in
  this recipe enforces that either is called on the main thread, though
  every call site in this recipe's own units reaches them only from an
  already-main-thread caller (MUST, see
  **quiet-operations-run-on-main-thread**).
- **Error states**: None of the four units exposes a throwing or failable
  read. The settings-store lookup never throws — it returns `false` for a
  missing or non-boolean key by contract — and the test-framework-detection
  check never throws either. This component has no network, database, or
  file-system dependency whose unavailability it needs to report (MUST —
  there is no error path to define, not an omitted one).
- **Offline or disconnected state**: Not applicable — none of the four units
  makes a network call or models a connectivity state.
- **Colliding switch keys**: The debug launch switch has no built-in
  namespacing or collision guard; two switches constructed with the same key
  string observe the same settings-store/launch-argument slot, since
  equality between two switches is exactly string equality on the key. This
  is the documented contract — the key doubles as both the settings-store
  key and the launch-argument name — not an omitted guard (MUST, see
  **switch-key-identity**).
- **Test-framework linkage outside an actual test run**: Test-host detection
  reports `true` whenever the test framework's marker type is resolvable in
  the current process, per its own stated assumption that the test
  framework links its own runtime library into the runner, so the marker
  type exists in a test run and nowhere else. A host process that happens to
  link the test framework's library for some other reason would also report
  `true`; this is the documented assumption the check relies on, not a
  validation this component performs (MUST, see **test-host-detection**).
- **Live mutation of the launch argument or setting mid-process**: neither
  the switch's enabled-state read nor the gate's enabled state caches its
  result; each re-evaluates its settings-store/test-framework-detection read
  on every call, so a value changed in the supplied settings store between
  two calls MUST be reflected on the very next read (MUST, see
  **is-enabled-live-read**, **injectable-defaults-parameter**).
- **Repeated calls with no intervening state change**: calling the
  sink-behind-desktop, quiet order-front, quiet make-key-and-order-front, or
  conditional activation operation more than once in a row, with the quiet
  presentation gate's enabled state unchanged between calls, MUST leave the
  window or application in the same observable state a single call would
  have produced — each is a single property assignment or a single
  ordering/activation step, not an accumulating counter (MUST, see
  **sink-level-only**, **quiet-order-front**,
  **quiet-make-key-and-order-front**, **loud-activation-behavior**).

