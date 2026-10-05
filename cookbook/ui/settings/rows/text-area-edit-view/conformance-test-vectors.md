
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| text-area-edit-view-001 | initializer-parameters | Construct with only the view model supplied | The visible-line count defaults to 6 and monospaced defaults to false |
| text-area-edit-view-002 | row-label-text | View model's title is "Prompt" | The label's text is "Prompt" after construction |
| text-area-edit-view-003 | editor-font-role | Construct with monospaced set to true, then trigger a theme change | The editor's font equals the theme's code-role font both immediately after construction and after the theme change |
| text-area-edit-view-004 | initial-editor-text | View model's value is "hello" | The editor's text is "hello" after construction |
| text-area-edit-view-005 | editor-theme-colors | Construct the component, then trigger a theme change | The editor's text, background, caret, and selection colors all equal the theme's corresponding roles, both immediately after construction and after the change |
| text-area-edit-view-007 | plain-text-mode | Construct the component | The editor accepts only plain text; no rich-text formatting is applied or preserved |
| text-area-edit-view-008 | undo-support | Construct the component | Standard undo and redo are available for typed edits |
| text-area-edit-view-009 | automatic-substitution-suppression | Construct the component | Quote, dash, and text-replacement substitutions are all disabled |
| text-area-edit-view-010 | vertical-growth | Construct the component | The editor grows vertically without limit as text is typed and does not grow horizontally; its width follows its scrolling container |
| text-area-edit-view-011 | text-wrapping | Construct the component | Text wraps to the available width rather than scrolling horizontally |
| text-area-edit-view-012 | text-container-inset | Construct the component | The typed text is inset 4pt from the editor's edges on every side |
| text-area-edit-view-013 | scrolling-container | Construct the component | The editor is hosted in a container that scrolls vertically, with a visible scroll indicator and a bezeled border |
| text-area-edit-view-014 | scroll-view-theme-background | Construct the view, then trigger a theme change | The scrolling container's background is always drawn and equals the theme's control-background color both times |
| text-area-edit-view-015 | label-scroll-view-layout | Construct the component | The label precedes the scrolling container in a single vertical, leading-aligned layout with 8pt spacing, pinned to the component's edges |
| text-area-edit-view-016 | visible-height | Construct with a visible-line count of 6 and a known font | The scrolling container's height equals (line height × 6), rounded, plus 8; its width equals the surrounding layout's width |
| text-area-edit-view-017 | superview-width-claim | Add the component to a host view | A low-priority width preference equal to the host's width becomes active |
| text-area-edit-view-018 | label-resync | Trigger the view model's change notification with a new value | The label's text equals the view model's title after the call |
| text-area-edit-view-019 | self-inflicted-onchange-guard | Call commit while the editor's text differs from the committed value | During the resulting change notification, the editor's text is not overwritten and the caret is not moved |
| text-area-edit-view-020 | external-value-adoption | With no commit in progress, externally change the view model's value and trigger its change notification with a value that differs from the editor's current text | The editor's text equals the new value after the call |
| text-area-edit-view-021 | caret-position-on-external-change | Give the editor focus, then trigger an external change notification with a new value | The caret moves to the end of the new text |
| text-area-edit-view-022 | accessibility-label | Construct with the view model's title set to "Script" | The editor's accessibility label is "Script" |
| text-area-edit-view-023 | end-editing-commit | Set the editor's text to "new" where the committed value is "old", then end editing | The committed value becomes "new" |
| text-area-edit-view-024 | window-detachment-commit | With the editor's text differing from the committed value, detach the component from its window | The committed value equals the editor's text after the move |
| text-area-edit-view-025 | teardown-notification-observers | Attach the component to a window, diverge the editor's text from the committed value, then close that window | The committed value equals the editor's text after the window closes |
| text-area-edit-view-026 | stale-observer-deregistration | Move the component from window A to window B, then close window A | Closing window A no longer triggers a commit for the component |
| text-area-edit-view-027 | redundant-commit-guard | With a write-counting observer on the committed value, set the committed value and the editor's text to the same value, then call commit | Zero additional writes are recorded; the committed value is unchanged |
| text-area-edit-view-028 | commit-echo-guard | With a write-counting observer on the committed value, set the editor's text to a value different from the committed value, then call commit | Exactly one write is recorded, carrying the new value |
| text-area-edit-view-032 | constituent-view-exposure | Construct the component, then access its label and its editor externally | Both are accessible and return the instances built during construction |
| text-area-edit-view-033 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

