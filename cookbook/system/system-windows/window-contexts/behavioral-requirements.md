
### Data shapes

- **state-shape**: The contexts state MUST hold `activeContextID` (optional) and `contextIDs` (a list), both defaulting to empty (absent, `[]`), and MUST be serializable, comparable for equality, and safe to use across concurrent execution contexts.
- **state-order-meaning**: `contextIDs` order MUST be the display order of contexts, where index 0 corresponds to keyboard shortcut 1.
- **state-excludes-settings**: The contexts state MUST NOT carry application settings; hosts persist the contexts settings separately.
- **settings-shape**: The contexts settings MUST hold `launchAtLogin` (default `false`), `reconcileBehavior` (default `prompt`), `hiddenApps` (default `[]`), and `showAppInDock` (default `false`), and MUST be serializable, comparable for equality, and safe to use across concurrent execution contexts.
- **settings-lenient-decode**: Decoding the contexts settings MUST substitute the default for each missing key, so `{}` decodes to the all-defaults value.
- **settings-typed-decode**: Decoding MUST fail when a present key holds the wrong type (for example `"launchAtLogin": "yes"`); only absence falls back to the default.
- **reconcile-behavior-cases**: The reconcile-behavior value MUST declare exactly `prompt`, `auto`, `ignore`, in that order, each with its name as its string raw value, and MUST support enumerating the complete list of values, serialization, equality comparison, and safe use across concurrent execution contexts.
- **reconcile-behavior-not-consumed**: The model MUST only store `reconcileBehavior` through its reconcile-behavior setter, and launch reconciliation always auto-applies matches and opens the reconcile UI for the rest, whatever the stored value.
- **reconcile-item-shape**: A reconcile item MUST carry `id` (the dormant snapshot's ID), `contextID`, `contextName`, `contextColor`, `app`, `titlePattern` (the fingerprint's title pattern), and `candidates` (a list of reconcile candidates), and MUST have a stable identity and support equality comparison.
- **reconcile-candidate-shape**: A reconcile candidate MUST carry `windowID`, `app`, `windowTitle`, and `score`, and its `id` MUST equal `windowID`.
- **reconcile-models-single-context**: A reconcile item and a reconcile candidate MUST NOT be usable across concurrency boundaries; they are confined to the single coordination context that creates them (the model's).
- **configuration-shape**: The contexts configuration MUST be safe to use across concurrent execution contexts and hold `selfAppName` (optional, default absent), `settingsKey` (required), `contextNoun` (default `"context"`), `contextNounPlural` (default the noun plus `"s"`), `notificationTitle` and `notificationIdentifier` (required), `defaultContexts` (a list, default `[]`), and `managesAppActivationPolicy` (default `true`).
- **error-descriptions-store**: Each context-store error case MUST produce its fixed English description: `directoryCreationFailed`, `encodingFailed`, `decodingFailed`, `writeFailed`, `readFailed` include the path (where present) and the underlying error's description; `lockAcquisitionFailed` reads "Failed to acquire file lock at <path>"; `contextNotFound` reads "Context not found: <uuid>".
- **error-descriptions-manager**: Each context error case MUST produce its fixed English description (for example `windowAlreadyAssigned` reads "Window <id> is already assigned to context '<name>'", `persistenceFailed` reads "Failed to persist state: <underlying>").
- **unraised-error-cases**: Callers MUST treat the context error's `alreadyActiveContext` and `noActiveContext` cases as declared but unraised: no operation raises either case.

### Store: layout and I/O

- **store-layout**: Constructing the context store with a root directory MUST place the state at `<root>/state.json`, one file per context at `<root>/contexts/<UUID uppercase string>.json`, and the lock file at `<root>/.lock`.
- **store-json-format**: The store MUST encode JSON pretty-printed with sorted keys and dates as ISO 8601, and MUST decode dates as ISO 8601.
- **store-ensure-directories**: Ensuring the directory structure MUST create `<root>` and `<root>/contexts` with intermediate directories, and MUST throw `directoryCreationFailed(path: <root>, underlying:)` when either creation fails.
- **store-load-state-missing**: Loading state MUST return an empty contexts state (no active context, no IDs) when `state.json` does not exist.
- **store-load-state-errors**: Loading state MUST throw `readFailed` when `state.json` exists but cannot be read, and `decodingFailed` when it cannot be decoded.
- **store-load-context-missing**: Loading a context by `id` MUST throw `contextNotFound(id:)` when the context file does not exist, `readFailed` when it cannot be read, and `decodingFailed` when it cannot be decoded.
- **store-save-context**: Saving a context MUST write the encoded context to its file with an atomic (write-then-replace) file write while holding the lock, throwing `encodingFailed` or `writeFailed` on failure.
- **store-delete-context**: Deleting a context by `id` MUST remove the context file under the lock when it exists, and MUST succeed without effect when it does not; a removal failure propagates the underlying file-system error unwrapped.
- **store-load-all-order**: Loading all contexts MUST return them in the state's `contextIDs` order.
- **store-load-all-skips**: Loading all contexts MUST skip any context whose file is missing, unreadable, or undecodable, logging "Skipping context <id>: <error>" at error level, rather than failing the whole load.
- **store-load-all-state-error**: Loading all contexts MUST propagate the error when `state.json` itself cannot be read or decoded.
- **store-save-all-content**: Saving all contexts MUST, under one lock, write every context's file and then write `state.json` with `activeContextID` and `contextIDs` equal to the contexts' IDs in the given order.
- **save-all-not-atomic**: Saving all contexts writes each context file independently, although the documentation says it updates the contexts state atomically. A failure on the Nth context throws after earlier context files are already replaced and before the state file is written, leaving disk partially updated; no rollback or journal exists.
- **store-save-all-no-prune**: Saving all contexts MUST NOT delete context files for IDs absent from the given list; orphan removal happens only through deleting a context by `id`.
- **store-list-files**: Listing context files MUST return `[]` when `<root>/contexts` is absent, MUST return the UUIDs parsed from every `*.json` filename whose stem is a valid UUID (ignoring other files), and MUST throw `readFailed` when the directory cannot be listed. The order MUST be treated as unspecified (directory listing order).
- **store-remove-all**: Removing everything MUST delete `<root>` recursively when it exists, without taking the lock, and propagate the underlying error unwrapped.
- **store-lock**: Every write operation (saving a context, deleting a context, saving all contexts) MUST first ensure the directory structure, open or create `<root>/.lock` with mode `0644`, take an exclusive file lock, run the write, then release the lock and close the file exactly once.
- **store-lock-failure**: When the lock file cannot be opened, or the exclusive lock cannot be taken, the operation MUST throw `lockAcquisitionFailed(path:)` without running the write; on a failed lock the file MUST be closed once.
- **store-lock-blocking**: The lock MUST block until acquired; there is no timeout and no non-blocking attempt.
- **store-reads-unlocked**: Loading state, loading a context, loading all contexts, and listing context files MUST NOT take the lock.
- **store-concurrency-safe**: The context store MUST be usable from any thread; its safety rests on the write lock and on encoder and decoder instances that are configured once and never mutated.

### Manager: lifecycle and load

- **manager-single-context**: The context manager MUST be confined to a single coordination context; every operation runs there and its state has no internal locking.
- **manager-init**: Constructing the context manager MUST start with no contexts and no active context, and MUST default the custom-heuristic store to one rooted at the state store's root directory.
- **manager-load-state**: Loading state MUST read the active context ID and the contexts from the store, then invalidate stale window IDs, then load custom heuristic rules, and MUST propagate store read or decode errors on `state.json` unwrapped.
- **manager-load-no-active-check**: Loading state MUST keep a persisted `activeContextID` even when no loaded context has that ID (for example its file was skipped); looking up the active context then returns no value.
- **reconcile-stale-recycled**: On load, a snapshot whose `windowID` belongs to a live window of a different app (compared case-insensitively) MUST have its `windowID` cleared.
- **reconcile-stale-missing**: On load, a snapshot whose `windowID` is not in the live window list MUST have its `windowID` cleared only when its app has at least one live window; when its app has no live windows the `windowID` MUST be kept.
- **reconcile-stale-persist**: When at least one ID was cleared on load, the manager MUST log "Invalidated <n> stale window ID(s) on load" and persist; a persistence failure there MUST be logged and not thrown.
- **manager-root-directory**: `rootDirectory` MUST return the state store's root directory.

### Manager: context CRUD

- **create-context**: Creating a context MUST append a new context (new unique identifier, color default `"#007AFF"`, no snapshots), persist, and return it; it MUST NOT validate the name (empty and duplicate names are accepted) or the color string.
- **delete-context-missing**: Deleting, renaming, recoloring, or switching to a context MUST throw `contextNotFound(id:)` for an unknown ID without changing state.
- **delete-active-context**: Deleting the active context MUST clear `activeContextID` and restore every context's live windows to their saved frames (not only the deleted context's).
- **delete-inactive-context**: Deleting an inactive context MUST restore only that context's live windows to their saved frames.
- **delete-context-disk**: Deleting a context MUST remove it from memory, then delete its file via the store, then persist the remaining state.
- **rename-and-color**: Renaming a context and updating its color MUST set the field and persist, without validation.

### Manager: window assignment

- **add-window-duplicate**: Adding a window to a context MUST throw `windowAlreadyAssigned(windowID:contextName:)` when the window ID is on a snapshot in a different context.
- **add-window-refresh**: When the window ID is already in the target context, adding a window MUST refresh that snapshot's `savedFrame`, `title`, and `lastSeen` from the live window, persist, and return it instead of adding a second snapshot.
- **add-window-errors**: Adding a window MUST throw `contextNotFound` for an unknown context and `windowNotFound(windowID:)` when the ID is not among all live windows.
- **add-window-snapshot**: Adding a window MUST create a snapshot with the matcher's fingerprint for the window and the live window's frame, display, app, and title, append it to the context, persist, and return it.
- **park-on-attach**: Every operation that attaches a window to a context (add-window-snapshot, apply-matches, assign-to-snapshot, assign-batch, rematch-app, new-window-autoassign, custom-rule-autoassign) MUST park that window when there is an active context and the owning context is not it, and MUST NOT park it when no context is active.
- **remove-window**: Removing a window by `windowID` MUST remove the first snapshot carrying that window ID, move the window back to its saved frame when its context is not the active one, persist, and return the removed snapshot; it MUST throw `windowNotInAnyContext(windowID:)` when no snapshot carries the ID.
- **remove-clears-last-focused**: Removing a snapshot MUST clear the context's `lastFocusedWindowID` when it pointed at that snapshot.
- **set-last-focused**: Setting the last-focused window MUST record the snapshot ID of the matching window as the active context's `lastFocusedWindowID` and persist; it MUST do nothing, without error, when no context is active or the window is not in the active context.
- **context-lookup**: Looking up the context for a window ID MUST return the first context (in display order) with a snapshot carrying it, or no value.

### Manager: switching

- **switch-same-context**: Switching to the already-active context MUST restore its live windows to their saved frames and persist, and MUST NOT park any other context or throw.
- **switch-save-active**: Switching to a different context MUST, for each live window of the previously active context, capture its current frame into `savedFrame` (and update `lastSeen`) only when the frame overlaps some display horizontally, then park it.
- **switch-park-others**: Switching MUST park every live window of every other non-target context, first capturing any on-screen frame the same way.
- **switch-restore-target**: Switching MUST set every live window of the target context to its `savedFrame`.
- **switch-focus**: Switching MUST focus the target context's last-focused window when that snapshot exists and is live, else the first live window in the context, else nothing.
- **switch-commit**: Switching MUST set `activeContextID` to the target after parking, restoring, and focusing, then persist.
- **parking-position**: Parking MUST move a window's origin to x = (the minimum `minX` across all screens, or 0 when there are none) − `parkingMargin` (`30000`), keeping y equal to the snapshot's saved-frame y.
- **frame-capture-guard**: A window whose live frame does not overlap any screen horizontally MUST NOT have that frame saved, so a parked or clamped position never becomes a restore target.
- **window-ops-best-effort**: Park (move), restore (set frame), and focus calls to the window controller MUST NOT throw out of the manager; their failures are discarded — parking is declared best-effort, and accessibility failures are swallowed.
- **restore-failure-silent**: A failed restore or un-park (setting a window's frame) when restoring windows to saved positions or removing a window is discarded with no log, return value or error, so a window can stay parked 30000 points off every screen with no signal to the caller or user. The best-effort guarantee (window-ops-best-effort) covers only parking.

### Manager: re-matching

- **has-stale-windows**: The has-stale-windows flag MUST be `true` exactly when some snapshot in some context has an absent `windowID`.
- **run-rematching**: Running re-matching MUST pass all contexts and all live windows to the window matcher's match operation and return its match result without mutating state.
- **apply-matches**: Applying matches MUST, for each matched pair whose context and snapshot still exist, set the snapshot's `windowID` and `title` from the matched window and `lastSeen` to now, park when required (park-on-attach), and return the count applied; pairs whose context or snapshot is gone MUST be skipped silently.
- **apply-matches-unconditional**: Applying matches MUST NOT re-check scores; every pair given to it has already cleared the matcher's threshold.
- **apply-matches-persist**: Applying matches MUST persist only when at least one pair was applied, and MUST throw `persistenceFailed` when that persist fails.
- **launch-rematching**: Performing launch re-matching MUST return no value without enumerating windows when the has-stale-windows flag is false, and otherwise run re-matching, apply the result, and return it.
- **assign-to-snapshot**: Assigning a window to a snapshot MUST set the snapshot's `windowID`, `title` (the live window's title, or `""` when the ID is not live), and `lastSeen`, park when required, and persist; it MUST throw `contextNotFound` for an unknown context and `windowNotInAnyContext(windowID:)` when the snapshot ID is not in that context.
- **assign-batch**: Assigning windows to snapshots in a batch MUST return 0 for an empty list without enumerating windows; otherwise enumerate windows once, apply each resolvable assignment as assign-to-snapshot does, skip unresolvable ones silently, persist once when at least one applied (a persistence failure is logged, not thrown), and return the count applied.
- **assignment-window-unvalidated**: Assign-to-snapshot and assign-batch do not check that the window ID is live or not already on another snapshot, unlike add-window-snapshot. Auto-assigning all remaining matches builds each assignment from an item's top candidate independently, so two dormant snapshots sharing a top candidate both receive the same window ID.
- **remove-dormant**: Removing a dormant snapshot MUST remove the snapshot by its stable ID (whether dormant or live) and persist; it MUST throw `contextNotFound` for an unknown context and MUST succeed without change when the snapshot ID is absent.
- **dormant-snapshots**: Listing dormant snapshots MUST return every snapshot with an absent `windowID`, with its context's ID, name, and color, in context order then snapshot order.
- **score-window**: Scoring a window against a fingerprint MUST return the window matcher's score unchanged.

### Manager: window lifecycle events

- **mark-window-dormant**: Marking a window dormant MUST clear the `windowID` of the first snapshot carrying it, persist (failure logged, not thrown), and return the updated snapshot, or return no value when no snapshot carries it.
- **mark-app-dormant**: Marking an app's windows dormant MUST clear `windowID` on every live snapshot whose `app` equals the given name exactly (case-sensitive), persist when any changed, and return the count.
- **update-title**: Updating a window's title MUST set `title` and `lastSeen` on the first snapshot carrying the ID, persist, and return `true`, or return `false` when none carries it.
- **rematch-app**: Re-matching an app's dormant windows MUST consider only live windows of that app (case-insensitive) that are not already on any snapshot, and for each dormant snapshot of that app (in context then snapshot order) assign the highest-scoring remaining candidate whose score is at least the matcher's auto-assign threshold (80), first-seen winning ties; each window MUST be assigned at most once per call. It MUST persist when any matched and return the count.
- **new-window-autoassign**: Checking a new window for auto-assignment MUST return no value when the window is already on a snapshot; otherwise it MUST assign the window to the single dormant snapshot (across all contexts and apps) with the highest score of at least 80, first-seen winning ties, persist, and return that context's ID, or return no value when none qualifies.
- **custom-rule-autoassign**: Checking custom rules for auto-assignment MUST return no value when the window is already on a snapshot; otherwise it MUST take the first rule (in stored order) with `autoAssign` true, an `appName` equal to the window's app case-insensitively, a title that the rule's title match accepts, and a `targetContextName` equal case-insensitively to some context's name, add a new snapshot for the window to the first such context, persist, and return that context's ID; rules whose target name matches no context MUST be skipped.
- **event-persist-logged**: Lifecycle-event operations (mark-window-dormant, mark-app-dormant, update-title, rematch-app, new-window-autoassign, custom-rule-autoassign) MUST NOT throw; a persistence failure is logged at error level by the persist step and the in-memory change stands.

### Manager: persistence and custom rules

- **persist-after-mutation**: Every mutating manager operation MUST persist the whole state by saving all contexts after changing memory.
- **persist-error-wrap**: A persistence failure MUST be logged ("Failed to persist state: ...") and rethrown as the context error's `persistenceFailed(underlying:)` case by throwing operations.
- **memory-ahead-of-disk**: When persistence fails, the in-memory change MUST remain applied; context operations mutate memory before writing and do not roll back.
- **rules-load**: Loading custom heuristic rules MUST load them from the custom-heuristic store and register them with the matcher's registry; on failure it MUST log the error and set `customHeuristicRules` to `[]` without touching the registry.
- **rules-write-first**: Adding, updating, and deleting a custom heuristic rule MUST save the new rule list to disk before changing `customHeuristicRules` or the registry, so a failed write leaves memory, disk, and registry unchanged, and MUST propagate the save error.
- **rules-update-unknown**: Updating a custom heuristic rule MUST return without writing or throwing when no rule has the given ID.
- **rules-delete-unknown**: Deleting a custom heuristic rule MUST rewrite the unchanged list and succeed when no rule has the given ID.

### Model

- **model-single-context**: The contexts model MUST be confined to a single coordination context and publish `contexts`, `activeContextID`, `lastError`, `showReconcileWindow`, `showContextPicker`, `showHelp`, `showDiscovery`, `unmatchedItems`, `customHeuristicRules`, and `settings` as observable properties, so a reactive UI layer updates when any of them changes.
- **model-test-environment**: When `isTestEnvironment` is true (default: detected by the presence of the platform's test-framework class), the model MUST disable notifications, window observation, and default-context seeding.
- **model-settings-init**: The model MUST read its initial `settings` from persisted user settings keyed by `configuration.settingsKey`, defaulting to the all-defaults contexts settings value.
- **model-errors-to-string**: Every model operation that calls a throwing manager operation MUST catch the error, set `lastError` to "<English prefix>: <description>", log it at error level, and not rethrow.
- **model-sync**: After every successful manager mutation the model MUST copy `contexts`, `activeContextID`, and `customHeuristicRules` from the manager.
- **model-load-state**: Loading state MUST load the manager's state and, when no contexts exist and seeding is enabled, create each default-context entry from configuration in order, logging and continuing past any that fails; a load failure MUST set `lastError` to "Failed to load state: ..." and skip seeding.
- **model-launch-reconciliation**: Performing launch reconciliation MUST do nothing further when the manager reports no stale windows; otherwise it MUST apply auto-matches, rebuild `unmatchedItems`, and, when any remain, set `showReconcileWindow` to `true` and send the reconcile notification.
- **model-unmatched-items**: Refreshing unmatched items MUST produce one reconcile item per dormant snapshot, whose candidates are every live window not on any snapshot with a score above 0, sorted by score descending.
- **model-assign**: Assigning a candidate window to an unmatched item MUST set `lastError` to "Unmatched item not found." when the item ID is not in `unmatchedItems`, and otherwise assign and refresh.
- **model-skip**: Skipping an unmatched item MUST remove the item's dormant snapshot and refresh, and MUST do nothing when the item ID is unknown.
- **model-auto-assign-all**: Auto-assigning all remaining matches MUST assign each unmatched item that has candidates to its first (highest-scoring) candidate in one manager batch, and refresh only when at least one applied.
- **model-notification**: The reconcile notification MUST be sent only when notifications are enabled and the app's bundle identifier is present and not the platform test-runner's own identifier; it MUST request alert authorization and, only if granted, post an immediate, silent request with `configuration.notificationTitle`, identifier `configuration.notificationIdentifier`, and body "1 window needs assignment" or "<n> windows need assignment".
- **model-own-windows**: The model MUST exclude windows whose owner process ID equals its own from listing all windows, adding the frontmost window, and removing the frontmost window.
- **model-add-frontmost**: Adding the frontmost window MUST set `lastError` to "No active context. Switch to a context first." and return `false` when no context is active, set "No window found to add." and return `false` when no foreign on-screen window exists, and otherwise add the frontmost foreign window from the window list to the active context and return `true`.
- **model-remove-frontmost**: Removing the frontmost window MUST set `lastError` to "No window found to remove." or "This window is not assigned to any context." and return `false` in those cases, and otherwise remove the window and return `true`.
- **model-batch-add**: Adding windows in a batch MUST add each window independently, log a skipped window at debug level without setting `lastError`, and return the number added.
- **model-cycle**: Switching to the next or previous context MUST do nothing with fewer than 2 contexts, MUST wrap around, and with no active context MUST switch to the first (next) or last (previous) context.
- **model-settings-write**: Each settings setter MUST update the observable `settings` and write the whole value to persisted user settings in one step; setting Dock visibility MUST NOT change the application's activation policy.
- **model-hidden-apps**: Adding a hidden app MUST ignore a name already present (exact match) and otherwise append it and sort the list; removing a hidden app MUST remove every exact match.
- **model-observer-events**: The model's window-observer delegate callbacks arrive off the model's coordination context and MUST each hop back onto it before calling the manager: a window-destroyed event marks the window dormant, a window-created event tries dormant-snapshot matching and then custom rules, a window-title-changed event updates the title, an app-terminated event marks the app's windows dormant, and an app-launched event re-matches the app's dormant windows.
- **observer-event-ordering**: Each observer delegate callback spawns an independent unit of work on the model's coordination context, and the source states no ordering between them, so a rapid app-terminated then app-launched event (or window-destroyed then window-created for a recycled ID) has no ordering guarantee beyond the scheduler's behavior.
- **model-observation-start**: Starting window observation MUST do nothing when observation is disabled, and otherwise create a window observer over the window manager, make the model its delegate, and start it; stopping window observation MUST stop and release it.

