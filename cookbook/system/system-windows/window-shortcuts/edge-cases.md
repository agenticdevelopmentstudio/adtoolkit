
- **Fewer contexts than the index**: A switch-by-index key-down whose index is at or beyond the model's context count MUST be a no-op; this is the documented behavior of the underlying switch-by-index action ("Out-of-range indices (fewer contexts exist) are a no-op.").
- **Empty context list**: With zero contexts every switch-by-index key MUST be a no-op; next/previous/add/remove still dispatch, and the model decides the outcome (for example the switch-to-next-context action does nothing below two contexts).
- **More than nine contexts**: Contexts at index 9 and above MUST have no switch-by-index shortcut; they are reachable only through next/previous or the picker.
- **Negative index**: Cannot occur; indices come from enumerating a fixed nine-element list, so the handler MUST only ever see 0…8.
- **No frontmost eligible window / no active context**: The add and remove shortcuts MUST still call the model; the model reports failure and records the reason, and the manager MUST NOT react to that result.
- **Model switch failure**: If the context-switch action fails inside the model, the model logs it and records the failure; the manager MUST NOT observe or retry it.
- **Manager discarded**: Handlers remain registered and the chords remain reserved, but each handler MUST do nothing because its reference to the manager no longer resolves. Lifetime retention is a caller precondition ("Instantiate once at app launch and retain it for the app's lifetime").
- **Manager constructed twice**: Each instance registers its own handlers, so one key-down MUST call the model once per live instance; the reservation is replaced, not duplicated, because reserving the list removes an existing entry with the same identifier before adding. Single construction is the documented caller precondition.
- **User clears a chord**: A name whose shortcut the user removed MUST NOT fire; its handler stays registered and fires again if a chord is re-assigned.
- **User resets to defaults**: Resetting the full shortcut list (as the toolkit's shortcuts settings tab does) MUST restore the defaults listed in Behavioral Requirements; handlers need no re-registration.
- **Chord taken by the OS or another app**: The manager MUST NOT detect or report a conflict with a system or third-party global hotkey; whether the chord fires is decided by the underlying shortcut-recording layer and the OS.
- **Concurrent access**: Not applicable as a race: the manager is confined to one designated thread, handlers run on that same thread, and key-downs are delivered serially, so dispatches MUST execute one at a time in key-press order. See Platform Notes for how that confinement is enforced.
- **Network / offline**: Not applicable — the component performs no network I/O.
- **Timeouts and cancellation**: Not applicable — every dispatch is a synchronous call with no timeout and nothing to cancel.

