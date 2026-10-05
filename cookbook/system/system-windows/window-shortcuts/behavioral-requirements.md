
### Shortcut names (data shape)

- **index-shortcut-count**: The scheme MUST declare exactly nine switch-by-index shortcuts, named `switchToContext1` through `switchToContext9`.
- **index-shortcut-order**: The switch-by-index list MUST hold the nine switch-by-index names in ascending order, so element 0 is `switchToContext1` and element 8 is `switchToContext9`.
- **action-shortcut-names**: The scheme MUST declare five further shortcuts named `addWindow`, `removeWindow`, `nextContext`, `previousContext` and `contextPicker`.
- **all-shortcuts-list**: The full shortcut list MUST contain exactly fourteen names: the nine switch-by-index names in order, followed by `addWindow`, `removeWindow`, `nextContext`, `previousContext`, `contextPicker`, in that order.
- **unique-names**: Every identifier in the full shortcut list MUST be unique.
- **stable-raw-values**: Each name's stored identifier MUST equal its name (for example `"addWindow"`) and MUST NOT be renamed, because that identifier is also the stable, persisted storage key for a user's customization of that chord.
- **default-index-chords**: Each `switchToContextN` name MUST default to the scheme's modifier pair plus the digit key N (N = 1…9).
- **default-add-chord**: `addWindow` MUST default to the scheme's modifier pair plus A.
- **default-remove-chord**: `removeWindow` MUST default to the scheme's modifier pair plus X.
- **default-next-chord**: `nextContext` MUST default to the scheme's modifier pair plus N.
- **default-previous-chord**: `previousContext` MUST default to the scheme's modifier pair plus P.
- **default-picker-chord**: `contextPicker` MUST default to the scheme's modifier pair plus Space.
- **every-name-has-default**: Every name in the full shortcut list MUST ship a non-nil default shortcut.
- **names-module-internal**: The fourteen names and both lists MUST NOT be exposed as part of the toolkit's public interface; code outside the toolkit reaches them only through the shortcut manager and the toolkit's own settings UI.

### Manager construction and registration

- **init-signature**: The manager MUST expose exactly one construction path, taking the window-contexts model as its only required input, and MUST retain a reference to that model for its own lifetime.
- **register-on-init**: Constructing the manager MUST register a key-down handler for all fourteen names before construction completes.
- **register-once**: Registration MUST happen only during construction; the manager MUST NOT expose any way to register, re-register or unregister handlers afterward.
- **no-unregister-on-release**: The manager MUST NOT remove its handlers or release its chord reservation when it is no longer referenced; it performs no explicit teardown.
- **weak-handler-capture**: Each handler MUST reference the manager in a way that does not by itself keep the manager alive, so a handler that fires after the manager is gone does nothing.
- **reserve-external**: After registering handlers, construction MUST reserve the full shortcut list with the key-command registry under owner `"window contexts"`.
- **init-log**: Construction MUST emit one info-level log message confirming that the manager was initialized and every handler registered, after registration completes.

### Dispatch (key-down → model action)

- **dispatch-index**: A key-down on the name at position `i` (0…8) of the switch-by-index list MUST call the model's context-switch action with the `id` of the context at index `i`.
- **index-out-of-range-noop**: When `i` is greater than or equal to the model's context count, a switch-by-index key-down MUST do nothing: no model call and no error.
- **index-read-at-fire-time**: The switch-by-index handler MUST read the model's context list when the key is pressed, not when the handler is registered, so it follows contexts added or removed after launch.
- **dispatch-add**: A key-down on `addWindow` MUST call the model's add-frontmost-window action.
- **dispatch-remove**: A key-down on `removeWindow` MUST call the model's remove-frontmost-window action.
- **dispatch-next**: A key-down on `nextContext` MUST call the model's switch-to-next-context action.
- **dispatch-previous**: A key-down on `previousContext` MUST call the model's switch-to-previous-context action.
- **dispatch-picker**: A key-down on `contextPicker` MUST call the model's toggle-context-picker action.
- **key-down-only**: Handlers MUST fire on key-down; the manager MUST NOT register key-up handlers.
- **result-ignored**: The manager MUST discard the success/failure result returned by the add-frontmost-window and remove-frontmost-window actions; failures surface only through the model's own error state and logging.

### Persistence and side effects

- **customization-persistence**: User customizations of any chord MUST persist in local, per-user settings storage, under a key derived from the name's stored identifier; the manager itself MUST NOT read or write that storage directly.
- **global-event-tap**: Handlers MUST fire system-wide, including when the host app is not frontmost; the underlying shortcut-recording layer installs and owns the global event tap.
- **reservation-follows-customization**: The reservation MUST refuse the chord each name currently holds (the registry compares against the name's live, possibly user-customized shortcut at check time), so a user-customized chord stays reserved and the old default is freed.

