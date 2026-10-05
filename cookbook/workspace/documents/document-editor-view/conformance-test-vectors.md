
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| devc-001 | file-url-key-constant | Read the file-URL storage key constant | Equals `"fileURL"` |
| devc-002 | own-file-selection | Construct two component instances with the same pane-state store; set the displayed file on the first only | The second instance's displayed file is unaffected |
| devc-003 | no-decoded-initialization | Attempt construction from a decoded/serialized representation | Fails fast (the process traps rather than returning) — verified by code inspection; a trapping call cannot be asserted by an automated test |
| devc-004 | restore-on-construction | The pane-state store has the file-URL key set to a path that exists on disk; construct the component | The displayed file equals that path immediately after construction |
| devc-005 | missing-file-restore | The pane-state store has the file-URL key set to a path with no file on disk; construct the component | The displayed file is unset; the stored value is now cleared; the pane title is `"Untitled"` |
| devc-006 | restore-omits-redundant-write | The pane-state store has the file-URL key set to an existing file's path; construct the component, spying on the store's write operation | No write to the store occurs during construction |
| devc-007 | file-url-reflects-selection | No selection set | The displayed file is unset |
| devc-008 | set-file-url-updates-selection | Set the displayed file to /tmp/a/Readme.md | The selection's node URL equals that path |
| devc-009 | set-file-url-persists | Set the displayed file to /tmp/example/Readme.md | The stored value equals `"/tmp/example/Readme.md"` |
| devc-010 | set-file-url-updates-breadcrumb | Set the displayed file to a value | The breadcrumb's displayed file equals the same URL |
| devc-011 | file-url-title-change | Install a callback on the title-change callback; set the displayed file | The callback is called |
| devc-012 | directory-detected-via-resource-value | Set the displayed file to a URL for an existing directory | The selection's node is marked as a directory |
| devc-013 | clear-document-preserves-pane | Set the displayed file, then clear the document | The displayed file is unset; the stored value is cleared; the pane/component itself still exists |
| devc-014 | pane-title-is-filename | Set the displayed file to /tmp/example/Readme.md | The pane title equals `"Readme.md"` |
| devc-015 | pane-title-untitled-when-empty | Construct the component with an empty pane-state store | The pane title equals `"Untitled"` |
| devc-016 | title-change-callback-bridge | Assign a callback to the pane-title-change callback | Reading the title-change callback returns the same callback |
| devc-017 | options-rows-order | Build the pane's option rows | Returns 4 views/rows: 3 toggles ("Show line numbers", "Show overview", "Show invisibles") then one button titled "Reset to Defaults", in that order |
| devc-018 | toggle-initial-state-resolved | The resolved "show overview" value is false at call time; build the option rows | The "Show overview" row's on/off state is false |
| devc-019 | toggle-change-writes-override | Toggle the "Show line numbers" checkbox | The "show line numbers" override is set to the checkbox's new value |
| devc-020 | reset-button-label-and-style | Build the option rows | The fourth row's title is `"Reset to Defaults"` and its style is rounded |
| devc-021 | reset-button-enabled-matches-override | No display option is overridden; build the option rows | The reset button's enabled state is false |
| devc-022 | reset-button-action | Click the reset button | Every display-option override in this pane is reset |
| devc-023 | reset-accessibility-identity | Inspect the reset button | Accessibility identifier is `document.options.reset`; accessibility label is `"Reset Editor Options to Defaults"` |
| devc-024 | toggle-accessibility-identifiers | Inspect the three toggle rows' checkboxes | Identifiers are `document.options.line-numbers`, `document.options.overview`, `document.options.invisibles` respectively |
| devc-025 | rows-refresh-on-options-change | Build the option rows, keeping references; then set the "show overview" override to true | The kept "Show overview" row's on/off state becomes true; the kept reset button's enabled state becomes true |
| devc-036 | rows-refresh-on-options-change | Build the option rows, keeping references, with no pane-local override present; then change the app-wide "show line numbers" setting | The kept "Show line numbers" row's on/off state updates to the new app-wide value |
| devc-037 | rows-refresh-on-options-change | Build the option rows, then let the popover close so the kept row references become unset; then set the "show overview" override to true | No crash occurs; the refresh operation's writes to the released rows are no-ops |
| devc-026 | pane-override-isolated | Two component instances, each with its own independent display-option overrides; toggle "Show line numbers" on the first via its row | The first's resolved "show line numbers" value flips and its overridden state becomes true; the second's resolved value and overridden state are unchanged |
| devc-027 | reset-does-not-affect-other-panes-or-global | Override "Show line numbers" on both of two instances, then click the first's reset button | The first's overridden state becomes false; the second's stays true; the app-wide "show line numbers" setting is unchanged |
| devc-028 | breadcrumb-above-content | Load the component's view | The root stack's child views are, in order, the breadcrumb then the hosted content; its orientation is vertical; its spacing is 0 |
| devc-029 | breadcrumb-fixed-height | Load the component's view | The breadcrumb's height constraint constant is `24` |
| devc-030 | content-spans-container-width | Load the component's view | Both the breadcrumb's and the hosted content's leading/trailing edges pin to the stack's leading/trailing edges |
| devc-031 | root-view-initial-frame | Load the component's view | The returned root view's initial position and size is `(0, 0, 520, 424)`; the stack's top/bottom/leading/trailing edges pin to the root view's edges |
| devc-032 | content-uses-themed-root | Inspect the hosted content's root-view wrapping | The shared theming root is applied — verified by code inspection; this wrapping cannot be introspected by an automated test |
| devc-033 | hosts-file-editor-view | Load the component's view with a selection present | The hosted content is a file editor receiving that selection, the display-option overrides, the document store, the save scheduler, and the language services |
| devc-034 | breadcrumb-selection-routes-out | Install a callback on the open-request callback; invoke the breadcrumb's selection callback with a URL | The open-request callback is called with that URL; the displayed file is unchanged |
| devc-035 | editor-open-request-routes-out | Install a callback on the open-request callback; invoke the hosted content's open-file callback with a URL | The open-request callback is called with that URL |
| devc-038 | construction-title-change | Install a callback on the title-change callback; construct the component whose pane-state store has the file-URL key set to an existing file's path | The callback is called during construction |
| devc-039 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

