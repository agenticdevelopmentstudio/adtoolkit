
- Null/empty input: `placeholder` is a non-optional string; an empty string
  assigned to it produces an empty label with no crash, and the component
  needs no additional nil-handling because none of its stored properties
  (`displayedShortcut`, `pendingShortcut` may be unset; `placeholder` is
  always set) admit an unhandled null case.
- Boundary values: Not applicable in the numeric-range sense — the two
  layout constants (22pt fixed height, 132pt minimum width) are fixed
  architectural constants, not user-adjustable inputs with a min/max to
  probe, and every key-code comparison in the component's capture logic is
  an exact equality check, not a range comparison that could be
  off-by-one.
- Concurrent access: Not applicable — this component is confined to a
  single thread of execution for its entire lifetime, so all construction,
  focus changes, and key handling are serialized to that thread. See Platform Notes for how that confinement is enforced.
- Error states: Not applicable in the thrown-error sense — no
  error-throwing call appears anywhere in this component's own source. The
  one call that can fail, constructing a shortcut value from an event, is
  a call that can return an absent result rather than throw, and its
  failure case is handled by unconstructible-chord-ignore rather than
  propagated or crashed on.
- Offline/disconnected: Not applicable — the component performs no
  networking of any kind.
- Uncaptured key falls to default key-handling behavior: when the
  component defers to the default key-handling behavior (idle, or
  recording with an unconstructible chord), the platform's own default
  handling applies, which for a plain, otherwise-unhandled view typically
  produces the system alert sound. This is standard, unmodified platform
  behavior triggered by this file's own fallback, not a custom sound the
  component plays.
- Re-clicking while already recording: a click unconditionally claims
  focus even if the field is already focused;
  redundant-recording-notification-suppression means this has no effect on
  `isRecording` or `onRecordingChanged`.
- The manual recording-stop operation called when the window has since
  been deallocated or has no focused control at all: the focus-check
  guard evaluates false, so the focus-clearing branch is skipped and only
  the unconditional `isRecording = false` runs (see
  end-recording-force-stop).

