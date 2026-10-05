
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| kccf-003 | click-focus | Click anywhere within an on-screen, unfocused field's bounds | The field becomes the window's focused control |
| kccf-004 | focus-recording-start | Give focus to an unfocused field, in a window that accepts it | `isRecording == true` after the call; `onRecordingChanged` fires with `true` |
| kccf-005 | resign-recording-stop | Remove focus from a recording field, with the window accepting the change | `isRecording == false` after the call; `onRecordingChanged` fires with `false` |
| kccf-006 | redundant-recording-notification-suppression | With `isRecording == true`, trigger another focus-gain success (the field is already focused) | `onRecordingChanged` is not invoked a second time; no additional text/theme refresh is observed |
| kccf-007 | recording-change-reporting | Toggle focus onto then off of the field | `onRecordingChanged` fires exactly twice: once with `true`, once with `false` |
| kccf-008 | idle-end-recording-noop | Call the manual recording-stop operation on a field where `isRecording == false` | No change to focus, `isRecording`, or `onRecordingChanged` invocation |
| kccf-009 | end-recording-resignation | Field is recording and currently holds focus; call the manual recording-stop operation | The window's focus is cleared |
| kccf-010 | end-recording-force-stop | Field is recording but is not currently focused (e.g. focus already moved); call the manual recording-stop operation | `isRecording == false` after the call, and the window's focus is not touched (the focus-check guard is skipped) |
| kccf-011 | recording-key-equivalent-interception | Field is recording; send an event for the primary modifier plus K | The field's own capture logic evaluates the event (it is not deferred to the default pre-dispatch handling); `onCapture` fires with the corresponding shortcut |
| kccf-012 | idle-key-equivalent-deferral | Field is not recording; send an event for the primary modifier plus K | The default pre-dispatch handling's return value is what the capture logic returns; `onCapture` does not fire |
| kccf-013 | incidental-modifier-stripping | Field is recording; send an Escape key event with Caps Lock active (physically on) but no other modifier held | `onCancel` fires (the event is still classified as "unmodified Escape" after stripping the incidental Caps Lock state) |
| kccf-014 | incidental-modifier-stripping | Field is recording; send a Return key event with Caps Lock active (physically on) but no other modifier held | `onCommit` fires (the event is still classified as "unmodified Return" after stripping the incidental Caps Lock state) |
| kccf-015 | bare-escape-cancel | Field is recording; send Escape with no modifiers | `onCancel` fires; the event is consumed (capture logic returns `true`) |
| kccf-016 | bare-return-commit | Field is recording; send Return with no modifiers | `onCommit` fires; the event is consumed |
| kccf-017 | bare-return-commit | Field is recording; send the keypad Enter key with no modifiers | `onCommit` fires; the event is consumed |
| kccf-018 | unmodified-tab-passthrough | Field is recording; send Tab with no modifiers | Capture logic declines to capture; `onCapture`/`onCancel`/`onCommit` do not fire; focus is free to advance |
| kccf-019 | unmodified-tab-passthrough | Field is recording; send Shift-Tab | Capture logic declines to capture; the event is not consumed |
| kccf-020 | modified-tab-capture | Field is recording; send Option-Tab | A shortcut value is constructed and `onCapture` fires with it; the event is consumed |
| kccf-021 | captured-chord-reporting | Field is recording; send the primary modifier plus Shift plus K, then Option plus the primary modifier plus P | `onCapture` fires twice, once per chord, each with the corresponding shortcut value |
| kccf-022 | unconstructible-chord-ignore | Field is recording; send a bare modifier-key-down event (e.g. the primary modifier pressed alone, with no other key) for which constructing a shortcut value fails | `onCapture`/`onCancel`/`onCommit` do not fire; the event is not consumed |
| kccf-023 | uncaptured-key-down-passthrough | Field is not recording; send a key press for any key | The default key-handling behavior is invoked |
| kccf-024 | recording-placeholder-display | Field has no `pendingShortcut` and no `displayedShortcut`; give it focus | Label text becomes "Press keys…" |
| kccf-025 | pending-shortcut-priority | `displayedShortcut` is set to shortcut A; set `pendingShortcut` to shortcut B | Label text immediately shows B's `description`, not A's |
| kccf-026 | prior-text-retention | `displayedShortcut` is set to shortcut A, `pendingShortcut` is nil; give the field focus | Label text remains A's `description` (does NOT change to "Press keys…") until a chord is captured |
| kccf-027 | idle-placeholder-display | `pendingShortcut` and `displayedShortcut` are both nil, `isRecording == false`, default `placeholder` | Label text reads "Click to record" |
| kccf-028 | pointing-hand-cursor | Query cursor rects for the field's bounds | A pointing-hand cursor rect covers the full bounds |
| kccf-029 | theme-change-repaint | Field is on screen with theme T1; switch the active theme to T2 | Background/border color and label font/text color are re-read from T2's `SemanticPalette` without further user action |
| kccf-030 | recording-state-border-color | Compare a non-recording field to the same field once it starts recording | Border color changes from `borderColor` to `accentColor` |
| kccf-031 | shortcut-presence-text-color | Compare a field with `displayedShortcut` set to one with none | Text color is `primaryTextColor` when a shortcut is shown, `placeholderTextColor` when none is |
| kccf-032 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| kccf-033 | coder-initialization-rejection | Attempt to construct the control from a serialized or archived representation | Construction is refused as a programmer error and terminates; no instance is produced. Verified by inspection only, since the refusal cannot be caught. |
| kccf-034 | minimum-contrast-ratio | Construct the field under a theme whose primary text and control background colors are close | Text color equals the theme's primary text color and background equals the theme's control background color; no contrast adjustment is applied. |

`confines-to-ui-thread` is vector kccf-032 and `coder-initialization-rejection` is vector kccf-033; both are verified by inspection only (see Platform Notes).

