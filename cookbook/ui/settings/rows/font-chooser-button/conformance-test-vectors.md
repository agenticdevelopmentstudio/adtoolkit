
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| font-chooser-button-001 | system-placeholder | Construct the button with no further calls | Title is `"System"`, no font is selected, and the drawn font's point size equals the sample size |
| font-chooser-button-002 | rounded-momentary-style | Construct the button | The button renders with rounded corners and reports a momentary-push control type |
| font-chooser-button-003 | title-alignment | Construct the button | Title text is left-aligned |
| font-chooser-button-004 | tail-truncation | Construct the button | Overflowing title text is truncated at the tail |
| font-chooser-button-005 | yields-width-under-compression | Construct the button | Horizontal compression priority is configured to give up width readily |
| font-chooser-button-006 | expands-to-fill-remaining-width | Construct the button | Horizontal hugging priority is configured to expand into available width |
| font-chooser-button-007 | fixed-width-constraint | Construct the button with an explicit width of 200, laid out | An active constraint pins width to exactly 200pt |
| font-chooser-button-008 | no-width-constraint | Construct the button with an explicit `nil` width, and separately with the plain default constructor | Neither instance has a width constraint added by the component itself |
| font-chooser-button-009 | coder-init | Attempt construction via a serialization/decoding-based construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| font-chooser-button-010 | sample-size | Give the button a Menlo font at 48pt, titled "Menlo — 48 pt" | The drawn font's point size equals the sample size and its family is Menlo |
| font-chooser-button-011 | system-font-fallback | Give the button a `nil` font, titled "System" | The drawn font's point size equals the sample size and it is the system font |
| font-chooser-button-012 | selected-font-size | Give the button a Menlo font at 48pt, titled "Menlo — 48 pt" | The recorded selected font's point size is 48 (unchanged by the sample-size drawing) |
| font-chooser-button-013 | caller-supplied-title | Give the button a `nil` font, titled "Custom Title" | Title is "Custom Title" |
| font-chooser-button-014 | font-persistence | Static/source review: search for any store write anywhere in the type | No such call exists anywhere in the type; giving the button a new font and title only assigns its own in-memory selected font, drawn font, and title |
| font-chooser-button-015 | opens-font-picker | Activate the button with no font selected yet | The platform's font-selection UI opens, seeded with the system default font, and is brought to the front |
| font-chooser-button-016 | opens-font-picker | Give the button a Menlo font at 48pt, then activate it | The platform's font-selection UI opens seeded with Menlo at 48pt (not the sample size) and is brought to the front |
| font-chooser-button-017 | panel-modes | Query the modes the font-selection UI restricts itself to | Result contains family, face, and size choices, and none of color, underline, strikethrough, or other text-effect choices |
| font-chooser-button-018 | font-change-forwarding | Give the button a Menlo font at 48pt, activate it, then simulate the platform reporting a size change to 60pt picked in the font-selection UI | The change callback is invoked with the button's own selected font (Menlo at 48pt) carrying the newly-picked 60pt size, not a value substituted directly from the platform's own picker state |
| font-chooser-button-019 | nil-sender | Set the change callback to a closure that flips a flag; simulate the platform reporting a font-selection change with no accompanying context | The flag remains unflipped; no crash |
| font-chooser-button-020 | releases-picker-registration-on-removal | Add the button to a window, register it as the active recipient of font-picker selections, then remove it from its window | It is no longer registered as the active recipient afterward |
| font-chooser-button-021 | confines-to-ui-thread | Attempt to construct or mutate the button from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged |
| font-chooser-button-022 | selected-font-access | Construct the button, give it a font and title, then read the selected font from outside the type | The property is externally readable and reflects the last font given to it; it has no externally-accessible setter |
| font-chooser-button-023 | change-callback-access | Assign a closure to the change callback from outside the type | The assignment succeeds and the closure is the one invoked in font-chooser-button-018 |

Vector font-chooser-button-021 is a static, code-inspection check (a
compile-/runtime-enforced thread confinement), not a vector observed by
running the program; a port lacking equivalent enforcement should document
the gap rather than fabricate a runtime trap.

