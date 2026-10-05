
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **coder-initialization-rejection**: The control MUST be constructible only in code. Constructing it from a serialized or archived representation (such as a nib or storyboard) MUST be refused as a programmer error that terminates, producing no instance.
- **click-focus**: Component MUST take focus in response to a click, for
  any click location within its bounds (no sub-region hit-testing is
  performed).
- **focus-recording-start**: Component MUST set `isRecording` to `true`
  when it gains focus and the underlying focus-gain succeeds.
- **resign-recording-stop**: Component MUST set `isRecording` to `false`
  when it loses focus and the underlying focus-loss succeeds.
- **redundant-recording-notification-suppression**: Component MUST NOT act
  on (re-render text, re-theme, or invoke `onRecordingChanged`) a write to
  `isRecording` that sets it to its current value.
- **recording-change-reporting**: Component MUST invoke `onRecordingChanged`
  with the new value exactly when `isRecording` actually changes.
- **manual-recording-stop**: Component MUST expose an operation that
  manually stops recording.
- **idle-end-recording-noop**: The manual recording-stop operation MUST be
  a no-op when `isRecording` is already `false`.
- **end-recording-resignation**: When the manual recording-stop operation
  runs while `isRecording` is `true` and this component currently holds
  focus, Component MUST clear the window's focus.
- **end-recording-force-stop**: When the manual recording-stop operation
  runs while `isRecording` is `true`, Component MUST set `isRecording` to
  `false` directly afterward, regardless of whether this component held
  focus and regardless of whether the focus-clearing above succeeded —
  this stops recording without depending on the focus-change notification
  path, which is what lets the hosting row end recording from code that
  itself committed or abandoned the edit.
- **recording-key-equivalent-interception**: While `isRecording` is
  `true`, Component MUST evaluate every event delivered through the
  platform's pre-dispatch key-handling path through its own chord-capture
  logic instead of deferring to the default pre-dispatch handling.
- **idle-key-equivalent-deferral**: While `isRecording` is `false`,
  Component MUST defer every event delivered through the pre-dispatch
  key-handling path to the default pre-dispatch handling, unevaluated by
  its own capture logic.
- **incidental-modifier-stripping**: Before classifying a key event as
  Escape, Return/Enter, or Tab, Component MUST compute a modifier set that
  excludes incidental state — Caps Lock, the Fn key, and numeric-keypad
  status — so that an event carrying one of those incidental bits is not
  misclassified as "modified."
- **bare-escape-cancel**: While recording, Component MUST invoke
  `onCancel` and consume the event when the pressed key is Escape and the
  stripped modifier set is empty.
- **bare-return-commit**: While recording, Component MUST invoke
  `onCommit` and consume the event when the pressed key is Return or the
  keypad Enter key and the stripped modifier set is empty.
- **unmodified-tab-passthrough**: While recording, Component MUST NOT
  capture Tab pressed with an empty stripped modifier set or with only
  Shift; it MUST decline to capture the event (not consuming it) so normal
  focus traversal continues.
- **modified-tab-capture**: While recording, Component MUST treat Tab
  combined with any modifier other than (or in addition to) Shift alone —
  for example Option-Tab or Control-Tab — as an ordinary capturable chord,
  not as a focus-navigation key.
- **captured-chord-reporting**: While recording, for any key event that is
  not the bare-Escape, bare-Return, or passthrough-Tab case, Component
  MUST attempt to construct a shortcut value from the raw event and, when
  construction succeeds, MUST invoke `onCapture` with that shortcut and
  consume the event. This MUST happen for every distinct chord captured
  while recording, not only the first.
- **unconstructible-chord-ignore**: While recording, when constructing a
  shortcut value from a key event that is not the bare-Escape, bare-Return,
  or passthrough-Tab case fails, Component MUST NOT invoke `onCapture`,
  `onCancel`, or `onCommit`, and MUST NOT consume the event (its capture
  logic declines to capture it).
- **uncaptured-key-down-passthrough**: Component MUST defer to the default
  key-handling behavior whenever `isRecording` is `false`, or whenever
  `isRecording` is `true` but its capture logic declines to capture that
  event.
- **recording-placeholder-display**: Component MUST display the literal text
  "Press keys…" in place of a shortcut description whenever it is recording
  and neither `pendingShortcut` nor `displayedShortcut` is set.
- **pending-shortcut-priority**: Whenever `pendingShortcut` is
  non-nil, Component MUST render `pendingShortcut`'s `description` instead of
  `displayedShortcut`'s, regardless of recording state. This MUST take effect
  immediately when either property is set.
- **prior-text-retention**: When recording starts while
  `displayedShortcut` is already non-nil and `pendingShortcut` is still nil,
  Component MUST continue displaying `displayedShortcut`'s description (MUST
  NOT switch to "Press keys…") until the caller sets `pendingShortcut` in
  response to a chord the component reported through `onCapture`.
- **idle-placeholder-display**: Component MUST display its
  `placeholder` string (default the literal "Click to record") when not
  recording and neither `pendingShortcut` nor `displayedShortcut` is set.
- **pointing-hand-cursor**: Component MUST register the pointing-hand
  cursor over its full bounds.
- **theme-change-repaint**: Component MUST re-derive its background
  color, border color, label font, and label text color from the current
  `SemanticPalette` every time the active theme changes, and once
  synchronously during initialization.
- **recording-state-border-color**: Component MUST draw its 1pt layer
  border in the palette's `accentColor` while recording and in the palette's
  `borderColor` otherwise.
- **shortcut-presence-text-color**: Component MUST draw its label text in
  the palette's `primaryTextColor` whenever `pendingShortcut ?? displayedShortcut`
  is non-nil, and in the palette's `placeholderTextColor` otherwise (covering
  both the "Press keys…" and `placeholder` text cases).

