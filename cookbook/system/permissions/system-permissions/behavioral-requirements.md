
### Data shapes

- **permission-cases**: The permission model MUST have exactly seven
  cases: accessibility, notifications, automation (carrying a target
  bundle identifier), location, microphone, screen capture, and keychain
  (carrying a service name).
- **permission-value-semantics**: The permission model MUST support
  equality and hashing and MUST be safe to use across concurrent
  contexts; two automation values with different target bundle
  identifiers, or two keychain values with different service names, MUST
  be unequal (each is a distinct grant).
- **status-tri-state**: The status value MUST have exactly three cases —
  granted, denied, and undetermined — MUST support equality comparison,
  and MUST be safe to use across concurrent contexts.
- **undetermined-meaning**: undetermined MUST mean "cannot prove granted
  or denied" (never asked, target not running, no keychain item,
  timeout), and MUST NOT be used for a known refusal.

### Permission metadata

- **display-name**: The display-name property MUST return
  `"Accessibility"`, `"Notifications"`, `"Automation"`, `"Location"`,
  `"Microphone"`, `"Screen Capture"` and `"Keychain"` for the seven cases
  respectively, ignoring any carried value.
- **identifier-token-fixed**: The identifier-token property MUST return
  `"accessibility"`, `"notifications"`, `"location"`, `"microphone"` and
  `"screen-capture"` for the five cases with no carried value.
- **identifier-token-derived**: For the automation and keychain cases,
  the identifier-token property MUST be the prefix `"automation-"` or
  `"keychain-"` followed by the carried string lowercased, split on every
  non-alphanumeric character, with empty pieces dropped, and joined with
  `"-"`.
- **icon-name**: The icon-name property MUST return the icon identifiers
  `"hand.raised"`, `"bell.badge"`, `"gearshape.2"`, `"location"`, `"mic"`,
  `"display"` and `"key.fill"` for the seven cases respectively.
- **explanation-default**: The explanation property MUST equal the
  explanation-with-resolved-name operation called with the identity
  function, so an automation target is named by its raw bundle
  identifier.
- **explanation-automation-target**: For the automation case, the
  explanation-with-resolved-name operation MUST call the supplied naming
  function with the bundle identifier and embed its result in `"Needed to
  find, raise and open windows in <name>."`
- **explanation-keychain-service**: For the keychain case, the
  explanation MUST embed the service name in curly double quotes
  (U+201C, U+201D), so two services yield two different sentences.
- **settings-pane-url-tcc**: The settings-pane-location property MUST
  return the `x-apple.systempreferences:com.apple.preference.security?Privacy_<Pane>`
  location for accessibility (`Privacy_Accessibility`), automation
  (`Privacy_Automation`, one location for every target), location
  (`Privacy_LocationServices`), microphone (`Privacy_Microphone`) and
  screen capture (`Privacy_ScreenCapture`).
- **settings-pane-url-notifications**: For notifications, the
  settings-pane-location property MUST be
  `x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=<bundle id>`
  when the host has a non-empty bundle identifier, and the same location
  without the `?id=` query otherwise.
- **settings-pane-url-keychain**: For the keychain case, the
  settings-pane-location property MUST be absent, because keychain access
  is not gated by this settings mechanism and the system settings app
  lists no pane for it.
- **settings-pane-url-invalid-traps**: If a pane location string fails to
  parse as a URL, the settings-pane-location property MUST terminate the
  process with a precondition failure naming the string rather than
  return an absent value.
- **action-title**: The action-title property MUST be `"Allow…"` (with
  U+2026) when the permission has no settings pane, and `"Open Settings"`
  otherwise.
- **action-title-all**: The full list of action titles MUST list exactly
  `["Open Settings", "Allow…"]` so a caller can size a control to the
  widest title.

### Status-checking contract

- **checker-concurrency-safety**: The status-checking contract and the
  probe contract MUST be safe to use from any concurrent context; the
  production status checker and probe conformances MUST likewise be safe
  to use from any isolation domain.
- **status-no-prompt**: The status operation MUST NOT show any system
  prompt for any permission, and MUST be safe to call repeatedly (it is
  polled on every app activation by the panel).
- **request-surfaces-flow**: The request operation MUST surface the
  system's own request flow for the permission when one exists and MUST
  return the resulting status; callers MAY ignore the returned value.
- **is-granted**: The granted-check convenience MUST return true only
  when the status operation returns granted, and false for both denied
  and undetermined.

### Status mapping per permission

- **accessibility-status**: The status operation for accessibility MUST
  return granted when the process is trusted for assistive access and
  denied otherwise; it never returns undetermined.
- **accessibility-request**: The request operation for accessibility
  MUST ask for trust with its prompting option enabled, and return
  granted if trusted at that moment, else denied; it does not wait for
  the user to act in system settings.
- **notifications-mapping**: Notification authorization MUST map
  authorized, provisional and ephemeral outcomes to granted; a denied
  outcome to denied; a not-yet-determined outcome and any unknown future
  value to undetermined.
- **notifications-request**: The request operation for notifications
  MUST request authorization for alerts and sound, discard any error the
  request raises, and then return a fresh read of the notifications
  status.
- **automation-probe-flag**: The status operation for automation MUST
  call the injected probe without allowing it to prompt, and the request
  operation MUST call it with prompting allowed; both MUST forward the
  target bundle identifier unchanged.
- **automation-mapping**: An automation probe result of `noErr` (0) MUST
  map to granted, `errAEEventNotPermitted` (-1743) to denied, and every
  other value — including -1744 (consent required) and -600 (target not
  running) — to undetermined.
- **automation-probe-runs-on-dedicated-thread**: The automation probe
  MUST run on a dedicated background execution context, bridged back to
  the awaiting caller, never on the thread pool that services ordinary
  asynchronous work, because with prompting allowed it blocks until the
  user dismisses the consent dialog.
- **automation-probe-no-launch**: The production probe MUST check
  permission for the specific target bundle identifier (matching its
  event class and id as wildcards) without launching the target app, and
  MUST return the descriptor-creation status unchanged if the target
  descriptor cannot be created.
- **microphone-mapping**: Audio-capture authorization MUST map an
  authorized outcome to granted; denied and restricted outcomes to
  denied; a not-yet-determined outcome and unknown values to undetermined.
- **microphone-request**: The request operation for microphone MUST
  request audio access, ignore the returned boolean, and return a fresh
  read of the microphone status, so a restriction is distinguished from a
  first denial.
- **screen-capture-status**: The status operation for screen capture MUST
  return granted when the screen-capture preflight check passes and
  denied otherwise; it never returns undetermined, so never-asked reads
  the same as refused.
- **screen-capture-request**: The request operation for screen capture
  MUST call the system's screen-capture request and return granted or
  denied from its boolean result; after a remembered refusal the system
  shows nothing and the result is denied.
- **location-mapping**: Location authorization MUST map only an
  always-authorization outcome to granted; a when-in-use outcome, a
  denied outcome, and a restricted outcome to denied; a not-yet-determined
  outcome and unknown values to undetermined.
- **location-when-in-use-denied**: A when-in-use location grant MUST read
  as denied, not undetermined, so the caller falls back to the settings
  pane (an always-authorization decision will not re-prompt once any
  decision exists).
- **location-single-coordinator**: All location status reads and
  requests MUST go through one process-wide, serialized coordinator that
  owns a single long-lived location manager, created and receiving its
  callbacks on that same serialized context.
- **location-request-settled**: The request operation for location MUST
  request always-authorization and, when the status before the call was
  anything other than not-yet-determined, return the current status
  immediately without waiting.
- **location-request-waits**: When the status before the call was
  not-yet-determined, the request operation MUST suspend until the
  authorization changes to a decided value or the timeout fires, and
  return the status at that moment.
- **location-request-recheck**: After registering its waiter, the
  coordinator MUST re-read the authorization status and resume all
  waiters immediately if it is no longer not-yet-determined, so a
  decision landing between the request and the wait is not lost.
- **location-request-timeout**: The coordinator MUST resume all waiters
  with the then-current status 120 seconds after the first waiter
  registered, if no decision has arrived.
- **location-shared-waiters**: Concurrent request calls made while
  undetermined MUST share one system prompt and one timeout; only the
  first waiter starts the timeout.
- **location-resume-once**: Every waiter MUST be resumed exactly once:
  the coordinator reads and clears the waiter list in one serialized step
  with no suspension point, cancels the timeout, then resumes each
  waiter.
- **location-delegate-ignores-undetermined**: A callback reporting a
  not-yet-determined authorization change MUST NOT resume waiters.

### Keychain permission

- **keychain-status-no-access**: The status operation for keychain MUST
  NOT touch the keychain; it MUST return the keychain ledger's own
  recorded status for that service.
- **keychain-request-is-read**: The request operation for keychain MUST
  perform a real in-process read of a generic-password item for the
  service, requesting its data (not just attributes), matching one item,
  across both local and synchronizable keychains, so the platform raises
  its access-control dialog naming this app.
- **keychain-read-runs-on-dedicated-thread**: The keychain read MUST run
  on a dedicated background execution context, bridged back to the
  awaiting caller.
- **keychain-mapping**: A keychain read status of `errSecSuccess` MUST
  map to granted, `errSecItemNotFound` to undetermined, and every other
  status (for example `errSecAuthFailed`, `errSecUserCanceled`,
  `errSecInteractionNotAllowed`, `errSecMissingEntitlement`) to denied.
- **keychain-request-records**: The request operation for keychain MUST
  record the mapped status in the keychain ledger before returning it.
- **keychain-read-discards-bytes**: The keychain read MUST discard the
  returned item data; only the status is kept.
- **ledger-key**: The keychain ledger MUST store its record under the key
  `"permission.<identifier token of the keychain case>.status"` in the
  host's standard persisted settings store.
- **ledger-values**: The ledger MUST store the string `"granted"` or
  `"denied"`; the status-read operation MUST return granted or denied for
  those strings and undetermined for a missing key or any other value.
- **ledger-undetermined-erases**: Recording undetermined for a service
  MUST remove the key rather than store a third value.
- **ledger-record-status-code**: Recording a raw system status code for a
  service MUST map the code with the same rules as **keychain-mapping**
  and record the result.
- **ledger-forget**: Forgetting a service MUST be equivalent to recording
  undetermined for it.
- **ledger-persistence**: Ledger records MUST survive app restarts (they
  persist in the host's standard settings store) and MUST NOT be
  revalidated against the keychain on read.
- **keychain-ledger-key-collision**: Distinct keychain service names
  after normalization are a caller precondition. The identifier-token
  derivation collapses case and every run of non-alphanumeric characters,
  so services such as `"Foo Bar"` and `"foo-bar"` share one ledger key and
  overwrite each other's grant record; nothing validates or disambiguates
  service names.

