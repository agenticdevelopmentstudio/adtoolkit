
### Identity & Construction

- **file-url-key-constant**: The storage key used to persist the displayed file's URL MUST equal the literal string `"fileURL"`.
- **own-file-selection**: The component MUST hold its own file-browser selection state, distinct from any other instance of this component's selection, so that two editors can display two different files at once.
- **no-decoded-initialization**: The component MUST NOT support construction from a serialized/decoded representation (such as a saved interface file), and MUST fail fast if such construction is attempted.
- **restore-on-construction**: During initialization, the component MUST read the stored file URL from the pane-state store and, when a value is present and its file exists on disk, MUST display that file.
- **missing-file-restore**: When the stored path's file does not exist on disk, the component MUST clear the stored value and leave the displayed file unset, rather than displaying or erroring on a missing file.
- **restore-omits-redundant-write**: Restoring a stored file during initialization MUST NOT write that same value back to the store; only a subsequent call that changes the displayed file MUST write to the store.
- **construction-title-change**: Restoring a stored file during initialization MUST also invoke the title-change callback afterward, the same as any other call that changes the displayed file.

### Displaying and Changing the File

- **file-url-reflects-selection**: The displayed-file property MUST return the URL of the currently selected file-browser node, or none when no node is selected.
- **set-file-url-updates-selection**: Setting the displayed file to a value MUST set the selection to a node for that URL; clearing it MUST clear the selection.
- **set-file-url-persists**: Setting the displayed file MUST write the new value — the URL's path, or none — to the pane-state store under the file-URL storage key.
- **set-file-url-updates-breadcrumb**: Setting the displayed file MUST set the breadcrumb's displayed file to the same value.
- **file-url-title-change**: Setting the displayed file MUST invoke the title-change callback afterward.
- **directory-detected-via-resource-value**: The component MUST determine whether a URL being shown is a directory by querying the URL's own directory-resource metadata, defaulting to "not a directory" when that query fails, rather than assuming the URL is a file because of how it was obtained.
- **clear-document-preserves-pane**: Clearing the document MUST unset the displayed file and persist that clearing, and MUST NOT remove the pane or otherwise affect anything beyond the displayed file.

### Pane Title

- **pane-title-is-filename**: The pane title MUST equal the displayed file's last path component when a file is displayed.
- **pane-title-untitled-when-empty**: The pane title MUST equal the literal string `"Untitled"` when no file is displayed.
- **title-change-callback-bridge**: The pane-title-change callback's getter and setter MUST read and write the same underlying callback as the title-change callback.

### Editor Options Popover

- **options-rows-order**: Building the pane's option rows MUST return exactly four views/rows, in order: the "Show line numbers" toggle, the "Show overview" toggle, the "Show invisibles" toggle, then the reset button.
- **toggle-initial-state-resolved**: Each toggle's on/off state at the moment the option rows are built MUST equal the corresponding resolved display-option value (show line numbers, show overview, show invisibles).
- **toggle-change-writes-override**: Changing a toggle's value MUST write the new value to the matching display-option override (show line numbers, show overview, or show invisibles).
- **reset-button-label-and-style**: The fourth row MUST be a button titled `"Reset to Defaults"` with a rounded button style.
- **reset-button-enabled-matches-override**: The reset button's enabled state at the moment the option rows are built MUST equal whether any display option is currently overridden in this pane.
- **reset-button-action**: Activating the reset button MUST reset every display-option override in this pane.
- **reset-accessibility-identity**: The reset button MUST carry the accessibility identifier `document.options.reset` and the accessibility label `"Reset Editor Options to Defaults"`.
- **toggle-accessibility-identifiers**: The line-numbers, overview, and invisibles toggles' checkboxes MUST carry the accessibility identifiers `document.options.line-numbers`, `document.options.overview`, and `document.options.invisibles`, respectively.
- **rows-refresh-on-options-change**: Whenever a display-option value changes (a pane-local edit, a reset, or a change to the corresponding app-wide setting) while a popover built from the most recently built option rows is still open, the component MUST update that popover's three toggles' on/off state and its reset button's enabled state to the newly resolved values.
- **pane-override-isolated**: Two instances of this component constructed with independent per-pane display-option overrides MUST NOT let a change made through one instance's option rows affect the other instance's resolved option values or overridden state.
- **reset-does-not-affect-other-panes-or-global**: Activating one instance's reset button MUST NOT change another instance's overridden state, resolved option values, or the underlying app-wide setting.

### Layout & Content Hosting

- **breadcrumb-above-content**: The component's view MUST arrange the breadcrumb directly above the hosted editor content in a vertical stack with 0 spacing between them and a fill distribution.
- **breadcrumb-fixed-height**: The breadcrumb MUST be constrained to a fixed height of `24` points.
- **content-spans-container-width**: The breadcrumb and the hosted editor content MUST each have their leading and trailing edges pinned to the containing stack's leading and trailing edges.
- **root-view-initial-frame**: The component's root view MUST be created with an initial size of `520`×`424` points, with the stack pinned to all four of the root view's edges.
- **content-uses-themed-root**: The hosted content MUST be wrapped with the shared theming root so it reads the app's theme palette and paints the theme's window background.
- **hosts-file-editor-view**: The component MUST host a file editor, supplying it the current selection, the display-option overrides, the document store, the save scheduler, the language services, and an open-file callback that forwards its URL to the open-request callback.

### Open-Request Routing

- **breadcrumb-selection-routes-out**: A URL chosen through the breadcrumb (a crumb, or a file from its popover) MUST be reported through the open-request callback, not opened directly in this editor.
- **editor-open-request-routes-out**: A URL the hosted file editor resolves and reports through its open-file callback MUST be reported through the open-request callback, not opened directly in this editor.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

