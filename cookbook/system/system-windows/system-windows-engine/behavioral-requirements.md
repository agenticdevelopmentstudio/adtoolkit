
### Data shape

- **window-info-value**: A window record MUST be an immutable value type that is serializable, uniquely identifiable (by `id`), comparable for equality, and safe to share across concurrent contexts.
- **window-info-with-title**: Returning a copy with a replaced title MUST leave every field except `title` equal to the original.

### Parsing a window-list record

- **parse-required-fields**: Parsing a window-list record MUST return nil when any of window number, owner PID, layer, or bounds dictionary is missing or of the wrong type.
- **parse-optional-defaults**: A missing owner name MUST become `""`, a missing window name MUST become `""`, and a missing on-screen flag MUST become `false`.
- **parse-bounds-defaults**: Each missing bounds key (`X`, `Y`, `Width`, `Height`) MUST default to 0.
- **parse-display-from-center**: `display` MUST be the display containing the frame's center point, resolved by looking up the display that contains it.
- **display-fallback**: Looking up the display for a point MUST return the main display id when no display contains the point or the display query fails.
- **parse-no-policy**: Parsing MUST NOT filter by layer, app or size; policy is applied only by enumeration.

### Enumeration

- **list-on-screen**: Listing on-screen windows MUST enumerate only on-screen windows, excluding desktop elements.
- **list-all**: Listing all windows MUST enumerate all windows including off-screen (minimized or parked) ones, excluding desktop elements.
- **list-failure-empty**: Both list operations MUST return `[]` when the window-list query returns nothing; the failure is not distinguishable from "no windows".
- **policy-layer**: Enumeration MUST drop every window whose `layer` is not 0.
- **policy-excluded-apps**: Enumeration MUST drop every window whose `app` is in the excluded-apps list: "Window Server", "WindowManager", "Dock", "Control Center", "Notification Center", "SystemUIServer".
- **policy-zero-size**: Enumeration MUST drop every window whose frame width or height is not greater than 0.
- **list-order**: Enumeration MUST preserve the order in which the system window list returned the records.
- **list-no-permission-needed**: Enumeration MUST succeed without accessibility permission; only title backfill depends on it.

### Title backfill

- **backfill-trigger**: After policy filtering, each list operation MUST attempt to backfill titles only for windows whose `title` is empty.
- **backfill-skip**: When no window has an empty title, the list MUST be returned unchanged with no accessibility calls.
- **backfill-batch-per-pid**: The engine MUST enumerate the accessibility windows of each owning process that needs a title exactly once per list call.
- **backfill-single-window-app**: When the owning app exposes exactly one accessibility window, that window's title MUST be used regardless of frame.
- **backfill-unique-frame**: When the app exposes more than one accessibility window, the title MUST come from the single accessibility window whose position and size each lie within 2 points (strictly less than 2) of the window's frame.
- **backfill-ambiguous**: When zero or more than one accessibility window matches the frame, the title MUST stay empty.
- **backfill-empty-result**: An accessibility title that is nil or empty MUST leave the title empty.
- **backfill-read-only**: Backfill MUST use accessibility attribute reads only (no actions, no observers), so list operations MAY run off the main thread.

### Window-ID to accessibility-element matching

- **ax-element-lookup**: Looking up the accessibility element for a window ID MUST use the supplied window record when given, and otherwise look the id up in the full window list (all windows, excluding desktop elements) using the same parsing as enumeration, without enumeration policy or backfill.
- **ax-element-unknown-id**: The lookup MUST return nil when the id is not in the window list.
- **ax-element-no-ax-windows**: The lookup MUST return nil when the owning app's accessibility windows cannot be read.
- **match-title-score**: A candidate MUST score +10 when the target title is non-empty and equals the candidate's accessibility title exactly.
- **match-empty-title-score**: A candidate MUST score +1 when both the target title and the candidate's accessibility title are empty.
- **match-position-score**: A candidate MUST score +5 when both its accessibility position coordinates lie within 2 points (strictly less than 2) of the target frame origin.
- **match-size-score**: A candidate MUST score +3 when both its accessibility width and height lie within 2 points (strictly less than 2) of the target frame size.
- **match-unreadable-attribute**: An accessibility attribute that cannot be read MUST contribute 0 to the score.
- **match-winner**: The candidate with the strictly highest score MUST win; on a tie the earliest candidate in the app's accessibility window order MUST win.
- **match-zero-rejected**: A candidate with score 0 MUST NOT be selected; when every candidate scores 0 the lookup MUST return nil.
- **ax-windows-for-pid**: Reading an app's accessibility windows MUST return the app's accessibility windows, or `[]` when the attribute cannot be read.

### Accessibility attribute helpers

- **attr-read-nil**: Reading a title, position or size attribute MUST return nil when the read fails or the value is not of the expected type.
- **attr-write-result**: Writing a position, writing a size, and raising a window MUST return the raw accessibility result code, with failure when the value cannot be created.

### Control operations

- **resolve-not-found**: Every control operation MUST throw a window-not-found error (with the window ID) when the id is absent from the full window list (after enumeration policy).
- **resolve-no-ax**: Every control operation MUST throw an accessibility-not-available error (with the app and PID) when the window is listed but no accessibility element matches, whatever the underlying reason (permission missing, attribute unreadable, no scoring candidate).
- **move**: Moving a window MUST set its accessibility position to the point and throw an attribute-set-failed error (with the position attribute name and the raw accessibility code) when the write fails.
- **resize**: Resizing a window MUST set its accessibility size and throw the same error with the size attribute name and the raw accessibility code when the write fails.
- **set-frame-order**: Setting a frame MUST set position first and size second, from one accessibility-element resolution.
- **set-frame-partial**: When the size write fails after a successful position write, setting a frame MUST throw the attribute-set-failed error for the size attribute and MUST leave the window at its new position (no rollback).
- **set-frame-stops**: When the position write fails, setting a frame MUST throw for the position attribute without attempting the size write.
- **focus-unpark**: Focusing a window MUST first move a window whose frame overlaps no screen horizontally to x = main screen visible-frame minX + 80, keeping its y, when a main screen exists.
- **focus-unpark-failure**: Focusing a window discards the result of the unpark move: a failed unpark lets focus raise a still-invisible window and return success with no signal.
- **focus-raise**: Focusing MUST then perform the raise action and throw the attribute-set-failed error (with the raise action name) when it fails.
- **focus-activate**: Focusing MUST then activate the owning app and throw an activation-failed error (with the app and PID) when no running app has the PID or activation returns false.
- **axelement-public**: Publicly resolving the accessibility element for a window MUST return the resolved element and its window record, throwing the same resolution errors as the control operations.
- **no-permission-check**: The manager MUST NOT check or prompt for accessibility permission; missing permission surfaces only as the accessibility-not-available error or as empty backfilled titles.
- **horizontal-visibility**: Testing horizontal on-screen visibility MUST return true exactly when the frame's X extent overlaps at least one screen's frame X extent (strict `maxX > minX` and `minX < maxX`); Y is never compared.

### Errors

- **error-descriptions**: Each control error case MUST produce the description text given under Localization, interpolating its associated values.

### Permission helper

- **permission-is-granted**: Checking whether the app is granted accessibility trust MUST report the current trust state without showing any system prompt.
- **permission-request**: Requesting permission MUST ask the system to show the accessibility prompt and return the current trust state, which is false until the user grants trust and the process is re-evaluated.
- **permission-request-user-initiated**: Hosts SHOULD call the request only from user-initiated actions, per its documentation, because it surfaces a system dialog and system settings.

### Observer lifecycle

- **observer-start-idempotent**: Starting observation MUST do nothing when already observing.
- **observer-start-snapshot**: Starting observation MUST snapshot known window ids per PID from the full window list before subscribing.
- **observer-start-apps**: Starting observation MUST create one accessibility observer per running app that has a non-empty localized name and a regular activation policy.
- **observer-ax-subscriptions**: Each app observer MUST subscribe to window-created and focused-window-changed on the app element, and to element-destroyed and title-changed on each of the app's existing accessibility windows.
- **observer-one-per-pid**: The observer MUST NOT create a second accessibility observer for a PID that already has one.
- **observer-create-failure**: When accessibility observer creation fails for an app, the observer MUST skip that app silently.
- **observer-registration-errors**: Every accessibility notification registration ignores its result code: an app whose registrations fail (for example with accessibility trust missing) is counted as monitored yet never reports window events.
- **observer-stop**: Stopping observation MUST do nothing when not observing; otherwise it MUST remove both app-lifecycle observers, remove every accessibility observer's run-loop source, clear all accessibility observers and clear the known-window snapshot.
- **observer-deinit**: Deallocating the observer MUST stop observation.
- **observer-refresh**: Refreshing known windows MUST replace the whole known-window snapshot with the ids from the full window list, grouped by PID.
- **observer-delegate-weak**: The delegate MUST be held weakly; events with no delegate are dropped.

### Observer events

- **app-launched**: On an app launch with a non-nil localized name, the observer MUST, 1.0 second later and only if still observing, create an accessibility observer for the PID, refresh the snapshot, then report the app as launched (with its name and PID).
- **app-launched-policy**: The launch path MUST NOT filter by activation policy or empty name, unlike starting observation.
- **app-terminated**: On an app termination with a non-nil localized name, the observer MUST remove that PID's accessibility observer and snapshot entry, then report the app as terminated (with its name and PID) synchronously.
- **window-created-baseline**: On a window-created notification the observer MUST subscribe the new window to destroyed and title-changed notifications and capture the baseline id set at once: the owning PID's known ids when the PID is readable, otherwise all known ids.
- **window-created-report**: 0.5 second later, only if still observing, the observer MUST list all windows, scope them to the PID when known, refresh the snapshot, and report each scoped window whose id is not in the baseline as created, in list order.
- **window-destroyed**: On an element-destroyed notification the observer MUST synchronously list all windows, refresh the snapshot, and report every previously known id no longer listed as destroyed, across all apps.
- **title-changed-match**: On a title-changed notification the observer MUST read the element's title, position and size, and report a title change (with the window id and new title) for the first listed window, scoped to the element's PID when readable, whose origin and size each lie within 2 points of the element's.
- **title-changed-drop**: When the title, position or size is unreadable, or no window matches, the title change MUST be dropped without a delegate call.
- **focused-window-changed**: On a focused-window-changed notification the observer MUST read the app's focused window and subscribe it to destroyed and title-changed notifications, relying on the platform's deduplication of repeated registrations.

### Concurrency

- **observer-main-confinement**: The window observer MUST be used only on the main thread: it relies on the documented invariant that accessibility event sources run on the main run loop, app-lifecycle observers use the main queue and delayed work hops through the main queue; callers of starting, stopping and refreshing observation MUST honor it.
- **manager-non-sendable**: The window manager MUST hold no stored state, so list operations MAY run off the main thread.
- **helpers-stateless**: The accessibility-element helper and the accessibility permission helper MUST hold no state; every call is independent.
- **no-timeouts**: Every operation MUST run synchronously with no messaging timeout of its own, no cancellation and no retry, so a call is bounded only by the system's default accessibility timeout.

### Side effects

- **side-effects**: Control operations MUST change only the targeted window's position, size, z-order and the owning app's activation; list operations and permission reads MUST have no side effect on other apps.
- **no-persistence**: The engine MUST NOT persist anything; the observer's snapshot lives only in memory.

