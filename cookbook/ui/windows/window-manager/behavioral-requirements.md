
### Isolation and ownership

- **single-thread-isolation**: The window manager, the window registry, the
  window-state storage protocol, and the settings-store-backed storage
  backend MUST be confined to a single designated thread; every operation
  on them MUST run on it.
- **namespace-thread-safety**: The window-state namespace MUST be callable
  from any thread; its current prefix MUST be guarded by a lock rather than
  by thread confinement.
- **screenshot-isolation**: The own-window-capture operation MUST be
  callable from any thread, and the write-PNG operation MUST run on the
  window manager's single designated thread.
- **shared-instance**: The shared window manager MUST be a single
  process-wide instance built with the shared screen manager.
- **single-screen-manager**: A window manager constructed without an
  explicit screen manager MUST use the shared screen manager, never a newly
  created one, so exactly one instance owns the persisted screen-set list
  and the screen-change observer.
- **frames-ownership**: Each window manager MUST create exactly one frame
  manager from its screen provider, storage, and screen manager, and expose
  it.
- **registry-ownership**: Each window manager MUST create exactly one empty
  window registry and expose it.
- **self-registration-target**: The single-instance window base MUST
  register itself with the shared window manager's registry during its
  initializer; a separately constructed window manager's registry is
  populated only by explicit registration calls.

### Initialization side effects

- **recent-limit-on-init**: The initializer MUST write the current value of
  the recent-windows-count setting to the platform's recent-documents limit
  setting before returning.
- **recent-limit-mirror**: After initialization, every change to the
  recent-windows-count setting MUST be re-applied to the platform's
  recent-documents limit setting, delivered on the main run loop.
- **recent-limit-weak-capture**: The settings subscription MUST hold the
  manager weakly, so it does not keep the manager alive.
- **termination-observer**: The initializer MUST subscribe to the
  platform's app-termination notification from any sender.

### Termination latch

- **terminating-default**: The termination flag MUST be false after
  initialization.
- **terminating-latch**: When the app-termination notification is posted,
  the termination flag MUST become true.
- **terminating-one-way**: The manager MUST NOT reset the termination flag
  to false on its own; only module-internal code (tests) can write it.
- **terminating-consumer**: The single-instance window base's
  window-will-close callback MUST skip persisting a hidden visibility state
  while the shared window manager's termination flag is true, and MUST
  persist it when the flag is false.

### Recents recording

- **interaction-kinds**: The interaction kind MUST have exactly two values,
  "show" and "close", and MUST be safe to pass across concurrency domains.
- **close-ignored**: Recording an interaction with kind "close" MUST have
  no effect.
- **spec-gate**: Recording an interaction with kind "show" MUST have no
  effect when the controller has no registered spec or when the spec's
  behavior does not include "include in recents".
- **document-recent**: Recording a "show" interaction, for a controller
  with a spec that includes "include in recents" and a non-nil document
  URL, MUST pass that URL to the platform's recent-documents API.
- **non-document-recents-noop**: A non-document window (no document URL)
  that passes the spec gate MUST NOT be recorded anywhere; the source
  states single-window tracking "lands in a follow-up slice with a
  dedicated recents tracker".
- **document-url**: The single-instance window base's document-URL
  accessor MUST return the file URL of the controller's document when the
  document is a platform document, and nothing otherwise.

### Recent-document limit

- **recent-limit-write**: Applying the recent-document count from settings
  MUST write the current value of the recent-windows-count setting,
  unchanged and unvalidated, to the platform's recent-documents limit
  setting.
- **recent-limit-default**: The recent-windows-count setting MUST default
  to 10.

### Launch restore

- **register-window**: Registering a window id (`register(id:make:)`)
  MUST store the factory under the id, replacing any factory previously
  stored under the same id, and MUST NOT call the factory. The host
  registers every window it has; whether one reopens is never the host's
  call (the deprecated `registerRestorable` forwards here).
- **restore-policy**: The launch-restore pass MUST skip the factory,
  visibility and missing-factory steps entirely when the
  reopen-on-launch-policy setting resolves to "do not reopen", and MUST
  leave every persisted visibility untouched in that case.
- **restore-builds-saved-visible**: The launch-restore pass MUST call, once
  per invocation and in unspecified order, the factory of every registered
  id that has no live registry controller and whose raw persisted
  visibility is exactly true. It MUST NOT call the factory of an id saved
  as closed or never saved.
- **restore-visibility-pass**: After running the factories, the
  launch-restore pass MUST run the visibility-restore step on the live
  controller for every id in the registry's registered ids.
- **restore-visibility-rule**: The visibility-restore step MUST show the
  window only when the controller's spec both persists visibility and can
  reopen on launch, and the last persisted visibility for its window id is
  exactly true; a persisted false or no persisted value MUST leave it
  closed.
- **restore-missing-factory-log**: For each id reported by the storage's
  visible-window-ids operation that has neither a registered factory nor a
  live registry controller, the launch-restore pass MUST log one error
  `restoreOnLaunch: visible window '<id>' has no registered factory; clearing its flag`
  with the id marked public, and MUST then clear that id's persisted
  visibility so the gap is reported once rather than on every launch.
- **restore-then-reopen**: The launch-restore pass MUST run the
  reopen-recents step after the visibility pass and the missing-factory
  check.
- **restore-reentrant**: The launch-restore pass MAY be called again (the
  source recommends it on reactivation, such as a second-launch distributed
  notification); each call reruns the full pass, building only windows not
  already live.
- **visible-ids-default**: Storage that does not implement the
  visible-window-ids operation MUST report an empty list.
- **visible-ids-settings-store**: The settings-store-backed storage backend
  MUST report every id whose namespaced visibility key holds true, found
  through the settings store's key-enumeration operation
  (`keys(withPrefix:)`, non-secure provider only).

### Reopen on launch

- **reopen-no-app**: The reopen-recents step MUST return without effect
  when no app instance exists.
- **reopen-policy**: The decision MUST follow the reopen-on-launch-policy
  setting: "match the system setting" returns the system default, "always"
  returns true, and "never" returns false.
- **reopen-policy-default**: The reopen-on-launch-policy setting MUST
  default to "match the system setting".
- **reopen-system-default**: The system default MUST be the boolean value
  of the platform's system-wide reopen-windows-on-quit default, reading
  false when the key is absent.
- **reopen-disabled-closes**: When the decision is not to reopen, the
  method MUST close, through its window controller, every app window whose
  window controller has a non-nil document, and MUST open nothing.
- **reopen-disabled-keeps-others**: When the decision is not to reopen,
  windows without a window controller or whose controller has no document
  MUST be left open.
- **reopen-enabled-opens-recents**: When the decision is to reopen, the
  method MUST request that the platform document controller open, with
  display requested, every URL in the platform's list of recent document
  URLs that is not already the file URL of an open window's document.
- **reopen-all-recents**: When the decision is to reopen, the method MUST
  open every recent URL, not only the documents that were open when the app
  last quit; whether a window spec allows reopening on launch is not
  consulted.
- **reopen-open-failure**: The open-recent completion handler discards its result, so a recent document that fails to open (moved, deleted, unreadable) produces no log, no user-facing error and no removal from recents (see Design Decisions).

### Window registry

- **registry-register**: Registering a controller MUST store a weak
  reference to it under its window id, replacing any prior entry for that
  id.
- **registry-empty-id**: Registering a controller MUST ignore one whose
  window id is the empty string.
- **registry-lookup**: Looking a controller up by id MUST return the live
  controller registered under it, or nothing when none was registered or
  the registered controller has been deallocated.
- **registry-registered-ids**: The registered-ids list MUST name every
  registered controller that is still alive, whether or not its window is
  open, in unspecified order.
- **registry-visible-ids**: The visible-ids list MUST name registered,
  alive controllers whose visibility flag is true, in unspecified order.
- **registry-has-visible**: The has-visible-window flag MUST be true
  exactly when at least one registered, alive controller has its visibility
  flag true.
- **registry-single-visibility-definition**: The visible-ids list and the
  has-visible-window flag MUST use the same visibility test.
- **registry-no-pruning**: Entries for deallocated controllers MUST remain
  in storage until the same id is re-registered; they are filtered out of
  every read.

### Window state storage

- **storage-protocol**: The window-state storage protocol MUST provide
  operations to load state, save state, remove state, load visibility, save
  visibility, remove visibility, and list visible window ids, all keyed by
  window id string.
- **storage-independent-keys**: Frame state and visibility MUST be stored
  under separate keys so a window can persist one without the other.
- **storage-key-format**: The frame key MUST be the current namespace
  prefix plus the state-key prefix plus the id, and the visibility key MUST
  be the current namespace prefix plus the visibility-key prefix plus the
  id.
- **storage-key-defaults**: The state-key prefix MUST default to
  `WindowState_` and the visibility-key prefix MUST default to
  `WindowVisible_` in both implementations.
- **storage-namespace-late-binding**: Both implementations MUST read the
  namespace when composing each key, not at construction, so a namespace
  set after a storage was created applies to it.
- **storage-state-json**: The persisted window state MUST be stored as
  JSON-encoded data in both implementations, so either implementation reads
  state the other wrote over the same underlying store.
- **storage-visibility-native**: Visibility MUST be stored as a native
  boolean (not JSON) in both implementations.
- **storage-visibility-tristate**: Loading visibility MUST return nothing
  when the key has never been written, and the stored boolean otherwise, so
  "never shown" is distinct from "explicitly hidden".
- **storage-remove**: Removing state and removing visibility MUST delete
  the key, after which the matching load returns nothing.
- **userdefaults-target**: The platform-preferences storage backend MUST
  read and write the platform's local preferences store directly, bypassing
  the settings store.
- **userdefaults-visible-ids**: The platform-preferences storage backend's
  visible-window-ids operation MUST return, in unspecified order, the id
  suffix of every key in that store that starts with the current namespace
  prefix plus the visibility-key prefix and whose value is the boolean
  true.
- **settings-store-target**: The settings-store-backed storage backend
  MUST route every key through its injected settings store with secure
  storage turned off, so values land in the store's non-secure provider.
- **settings-store-change-signal**: Writes and removals through the
  settings-store-backed storage backend MUST emit the key name on the
  store's change-notification stream when the provider emits one (the
  platform-preferences provider does); the platform-preferences storage
  backend emits nothing.
- **settings-store-non-bool-visibility**: When a visibility key exists but
  does not hold a boolean, the settings-store-backed storage backend's
  load-visibility operation MUST return false (the setting's default),
  whereas the platform-preferences storage backend returns nothing.
- **storage-codec-failure**: In both storage implementations a persisted window state that fails to encode is silently not written, and stored data that fails to decode reads as absent (never saved), with no log or error to the caller (see Design Decisions).

### Namespace

- **namespace-default**: The current namespace prefix MUST be the empty
  string until a host sets a namespace, so un-namespaced keys match the
  existing on-disk format.
- **namespace-qualify**: Qualifying a key MUST return the current prefix
  concatenated with the key.
- **namespace-token**: Isolating to a path MUST set the current prefix to
  "Instance" plus the lowercase hex of the first 4 bytes of the SHA-256
  digest of the path's UTF-8 bytes plus "_" (8 hex characters).
- **namespace-stable**: Isolating to a path MUST produce the same prefix
  for the same path on every call and launch.
- **namespace-no-raw-path**: The prefix MUST NOT contain any substring of
  the path.
- **namespace-bundle**: Isolating to the running bundle MUST isolate to the
  bundle's standardized bundle-location path, defaulting to the main
  bundle.
- **namespace-reset**: Resetting the namespace MUST set the current prefix
  back to the empty string.
- **namespace-host-timing**: A host that wants isolation MUST isolate to
  the running bundle before it first touches the window manager (per the
  type's doc comment); keys written earlier stay under the previous
  prefix.

### Window screenshot

- **screenshot-capture**: The own-window-capture operation MUST return a
  captured image of the given window, requesting full window bounds
  without extra frame chrome, at the display's best available resolution,
  over a null rectangle, or nothing when the capture fails.
- **screenshot-symbol-missing**: When the platform's window-list image
  capture facility cannot be resolved at runtime, the own-window-capture
  operation MUST return nothing rather than crash.
- **screenshot-symbol-once**: The facility MUST be resolved at most once
  per process.
- **screenshot-no-permission**: Own-window capture MUST NOT require or
  request Screen Recording permission.
- **screenshot-png-offscreen**: The write-PNG operation MUST return false
  and write nothing when the window is not currently on screen (its
  platform on-screen handle is not positive).
- **screenshot-png-failure**: The write-PNG operation MUST return false
  when capture, PNG encoding, or the file write fails.
- **screenshot-png-success**: The write-PNG operation MUST write PNG data
  to the URL and return true when every step succeeds.

