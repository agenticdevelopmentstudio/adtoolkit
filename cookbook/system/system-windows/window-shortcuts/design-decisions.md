
**Decision**: Raw values of the fourteen names are frozen as storage keys.
**Rationale**: The doc comment states the raw values are "stable `UserDefaults` storage keys for persisted user customizations — do not rename them"; renaming would silently drop every user's custom chords. (Swift/AppKit: the storage is `UserDefaults`.)
**Approved**: pending

**Decision**: Out-of-range switch-by-index is a silent no-op, and the index is resolved against the model's current context list at key-press time.
**Rationale**: The nine chords are fixed while the number of contexts varies at runtime; resolving late means the chords always track the current list order without re-registration, and a chord for a context that does not exist is harmless.
**Approved**: pending

**Decision**: Chords are reserved with `KeyCommandRegistry` under owner `"window contexts"`.
**Rationale**: The source comment: "So Settings › Key Commands refuses these chords instead of letting a second command fire on them too." Both handlers would otherwise fire on one key-down. (Swift/AppKit: `KeyCommandRegistry` is this toolkit's own reservation service.)
**Approved**: pending

**Decision**: Handlers capture the manager weakly and are never unregistered; the manager is expected to live for the app's lifetime.
**Rationale**: The class doc comment makes single construction and lifetime retention the caller's contract, so no teardown path exists; the weak capture only guards against a handler touching a freed manager. (Swift: implemented as a weak closure-capture list.)
**Approved**: pending

**Decision**: Add/remove results are ignored by the manager.
**Rationale**: The model already records the failure reason in `lastError` and logs thrown errors, so the dispatcher adds no second reporting path.
**Approved**: pending

**Decision**: Control+Option is the single modifier family for every default.
**Rationale**: The doc comment calls it "the standard keyboard-shortcut scheme"; the `CommandPaletteCoordinator` doc comment refers to it as the established global family, which other global chords follow. (Apple platforms: Control+Option; see the WinUI 3 Platform Notes entry for the Windows equivalent, Ctrl+Alt.)
**Approved**: pending

