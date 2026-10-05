
### Data shapes

- **discovered-window-shape**: A discovered window MUST be a value with a stable identity (`id`, the system window number, used to focus the window), `title` (a string), `pid` (a process id) and `isMatch` (a boolean), all immutable.
- **discovered-app-shape**: A discovered app MUST be a value with a stable identity (`id`, a process id), `name` (a string), `icon` (an optional image) and `windows` (a list of discovered windows), all immutable.
- **app-has-match**: A discovered app's `hasMatch` MUST be a computed property that is `true` exactly when at least one element of `windows` has `isMatch == true`.
- **published-state**: The model MUST publish three observable properties: `isLoading` (a boolean, initially `true`), `apps` (a list of discovered apps, initially empty) and `accessibilityDenied` (a boolean, initially `false`).
- **session-exposed**: The model MUST expose the `session` it was initialised with as an immutable public property; constructing the model MUST NOT start discovery.

### Discovery

- **discovery-resets-flags**: Discovering windows MUST set `isLoading` to `true` and `accessibilityDenied` to `false` before any other work.
- **discovery-permission-gate**: When Accessibility permission is not granted, discovering windows MUST set `isLoading` to `false` and `accessibilityDenied` to `true` synchronously and return without enumerating windows.
- **denied-keeps-apps**: On the permission-denied path, discovering windows MUST leave `apps` unchanged; it does not clear a previous result.
- **permission-check-no-prompt**: The permission gate MUST only read the trust state; it MUST NOT show the system Accessibility prompt.
- **app-snapshot-on-caller-thread**: Discovering windows MUST snapshot the running applications (process id, localized name, icon) synchronously on the calling thread before dispatching any background work.
- **regular-apps-only**: The snapshot MUST include only applications whose activation policy is regular (user-visible apps); accessory and background-only processes MUST be excluded.
- **unknown-app-name**: An application with no localized name MUST be snapshotted with the name `"Unknown"`.
- **project-name-captured**: Discovering windows MUST read the session's project name once, on the calling thread, and match every window against that captured value.
- **enumeration-off-caller-thread**: Window enumeration and matching MUST run on a background queue at user-initiated priority, not on the calling thread.
- **results-published-on-main**: The grouped result MUST be assigned to `apps`, and `isLoading` set to `false`, on the main queue in a single main-queue block, `apps` first.
- **weak-owner**: The background work MUST hold the model weakly; when the model has been deallocated before the work starts, nothing MUST be enumerated or published.
- **no-cancellation-or-timeout**: Discovery MUST NOT offer cancellation or a timeout; once dispatched, the enumeration runs to completion and publishes.
- **overlapping-discovery-order**: Two overlapping discovery calls each dispatch independent background work and each publish on completion, so the app list ends with whichever enumeration finishes last (not last started) and the loading flag turns false when the first finishes; there is no generation token or serialisation.

### Enumeration and grouping

- **all-windows-source**: Enumeration MUST use the engine's full window list, which includes minimized and off-screen windows, excludes desktop elements, and keeps only normal-layer (layer 0) windows.
- **title-backfill-inherited**: Window titles MUST be the engine's titles after its Accessibility backfill; the model performs no title lookup of its own.
- **untitled-windows-dropped**: A window whose title is empty after the engine's backfill MUST be excluded.
- **foreign-pid-dropped**: A window whose owning pid is not among the snapshotted regular apps MUST be excluded.
- **group-by-pid**: Kept windows MUST be grouped into one discovered app per owning pid, with `name` and `icon` taken from that pid's snapshot.
- **window-order-preserved**: Within a discovered app, `windows` MUST keep the order in which the engine reported them.
- **windowless-apps-omitted**: A snapshotted app with no kept window MUST NOT appear in `apps`.
- **duplicate-pid-first-wins**: If the snapshot contains the same pid twice, the first snapshot entry MUST be used for name and icon.
- **match-first-sort**: `apps` MUST be ordered with every app whose `hasMatch` is `true` before every app whose `hasMatch` is `false`.
- **alphabetical-sort**: Within each `hasMatch` group, apps MUST be ordered by `name` ascending using a localized, case-insensitive comparison.

### Matching

- **match-is-pure-static**: Matching a window against a project name MUST be a pure function of a window's info and a project name, with no dependency on model state, so it is testable in isolation.
- **empty-project-never-matches**: When `projectName` is the empty string, matching MUST return `false`.
- **unknown-project-never-matches**: When `projectName` is exactly `"Unknown"` (the sentinel value a session's project name returns for an empty or root working directory), matching MUST return `false`.
- **heuristic-pattern**: Matching MUST look up the heuristic registered for the window's owning app name (case-insensitive lookup) and, when one exists and extracts a pattern from the title, test that pattern.
- **raw-title-fallback**: When no heuristic is registered for the app, or the heuristic extracts no pattern, matching MUST test the raw window title in place of the pattern.
- **pattern-or-title-contains**: Matching MUST return `true` when either the tested pattern or the raw window title contains `projectName` under a localized, case-insensitive substring comparison, and `false` otherwise.

### Activation

- **activation-logs-intent**: Activating a window MUST log an info-level message naming the window title and pid before attempting focus.
- **activation-focuses-by-id**: Activating a window MUST ask the engine to focus the window by its `id`, which raises the window, nudges a horizontally off-screen window back onto the main screen, and activates the owning app.
- **activation-success-callback**: When focus succeeds, activating a window MUST invoke the activation callback exactly once, if it is set.
- **activation-failure-logged**: When focus fails, activating a window MUST log an error-level message with the pid and the error's description.
- **activation-failure-no-callback**: When focus fails, activating a window MUST NOT invoke the activation callback, so the host panel stays open for a retry.
- **activation-error-not-rethrown**: Activating a window MUST NOT throw or return the error; the log entry is the only failure signal.
- **activation-synchronous**: Activating a window MUST run the focus synchronously on the calling thread.
- **stale-window-not-rediscovered**: Activating a window MUST NOT re-run discovery; a window that has closed since discovery fails focus with the engine's window-not-found error and is logged like any other failure.

### Permission prompt

- **settings-request**: Opening Accessibility settings MUST request Accessibility permission, which shows the system Accessibility prompt and opens the Accessibility pane of system settings.
- **settings-no-refresh**: Opening Accessibility settings MUST discard the returned trust state and MUST NOT re-run discovery; the host calls discovery again when it wants a refresh.

### Concurrency

- **unchecked-thread-safety**: The model MUST be usable with no compiler-checked thread isolation; callers are responsible for its thread use.
- **main-thread-caller**: Discovering windows MUST be called on the main thread; its own documentation requires this (app metadata comes from main-thread-only system APIs, and it should be called when the view appears), and it mutates observable state synchronously on the caller's thread.
- **value-types-single-context**: A discovered window and a discovered app MUST NOT be usable across concurrency boundaries (a discovered app holds a platform image), so they are confined to the isolation domain that creates them.

