
- **Decision**: The row, not `KeyCommandCaptureField`, owns the pending-edit
  state (`isEditing`, `pendingShortcut`) and the confirm/cancel pair's
  visibility.
  **Rationale**: Per the source's own doc comment, "a captured chord is
  pending until the user commits it, and focus can leave in the middle of
  that (they click the checkmark, after all), so the state that decides
  whether ✓ and ✗ are on screen cannot live in the thing that loses focus."
  **Approved**: pending
- **Decision**: `commitEdit()` sets the committed binding's enabled flag to
  `true` whenever the command has no authored binding or its current
  shortcut is `nil`, but preserves the existing enabled flag when
  re-recording an already-authored, already-bound command.
  **Rationale**: Per the source's own comment, "recording a chord is
  unambiguous intent to use it, so the command comes on — unless the user
  themselves switched it off, in which case the switch stays where they
  put it. A shipped 'off' is not the user's choice: the suggested global
  chords ship off, and recording over one must not save a chord that
  silently never fires."
  **Approved**: pending
- **Decision**: `toggleChanged()` snaps the switch back to off and shows a
  refusal message, rather than silently ignoring the attempt, when turning
  a command on would collide with another command's chord.
  **Rationale**: Per the source's own comments, "switching on puts the chord
  back in play, so it has to be free: a chord two commands hold fires
  both," and "the switch snapping back by itself would otherwise read as a
  control that is broken rather than one that said no."
  **Approved**: pending
- **Decision**: The readout row's visibility is driven by `isEditing ||
  refusal != nil`, not by `isEditing` alone.
  **Rationale**: `toggleChanged()`'s refusal path never sets `isEditing`, so
  without this the toggle's refusal message would have nowhere visible to
  appear; the refusal persists on screen until the next edit begins,
  because `isEditing`'s `didSet` is what clears `refusal`.
  **Approved**: pending
- **Decision**: `onRecordingChanged(false)` clears the mid-edit state only
  when no chord is pending; when a chord is pending, the mid-edit state is
  left untouched.
  **Rationale**: Per the source's own comment, "clicked in and straight
  back out without pressing anything: there is nothing to confirm, so the
  pair should not linger" — but when a chord *is* pending, the mid-edit
  state must survive the field resigning first responder, since clicking
  the confirm/cancel pair itself moves focus off the capture field before
  the commit or cancel runs.
  **Approved**: pending

