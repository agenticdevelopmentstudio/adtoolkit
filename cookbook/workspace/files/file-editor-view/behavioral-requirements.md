
### Selection & Display Routing

- **onappear-shows-selection**: The component MUST show the current selection's content when the view first appears.
- **selection-change-shows-selection**: The component MUST re-evaluate and show the selection's content whenever the selected node changes.
- **openable-node-excludes-directories**: A selected node that is a directory MUST NOT be treated as an openable file.
- **openable-node-excludes-packages**: A selected node that is a package MUST NOT be treated as an openable file, even when it is also a directory.
- **openable-node-loads**: An openable selected node MUST be loaded from its location.
- **non-openable-selection-clears-editor**: No selected node, or one that is not openable, MUST clear the currently displayed file.
- **same-url-reselection-is-noop**: Loading a location that is already the one currently shown MUST leave the display and every cached editor unchanged — it MUST NOT cancel or restart the current read.

### Content Classification

- **cached-uri-shown-without-reread**: A location already present in the document cache MUST be shown immediately, without re-reading the file from disk and without rebuilding its editor.
- **new-uri-shows-loading**: A location not yet cached MUST show a loading indicator while its content is being read from disk.
- **oversize-file-uses-system-preview**: A file larger than 8,388,608 bytes (8 MiB) MUST be shown via a system-provided document preview rather than opened in the text editor.
- **undecodable-utf8-uses-system-preview**: A file at or under that size threshold whose bytes cannot be decoded as UTF-8 MUST be shown via the system-provided document preview, not marked unavailable.
- **unreadable-file-is-unavailable**: A file whose bytes cannot be read at all (permission denied, the file no longer exists, or any other read failure) MUST be shown as unavailable, not passed to the system preview.
- **text-file-opens-editor**: A file at or under the size threshold whose bytes decode as UTF-8 MUST be opened as a cached document in the text editor.

### Caching, Eviction, and Undo Preservation

- **cache-bound-is-eight**: The component MUST keep at most 8 documents live in its cache at one time.
- **eviction-is-least-recently-selected**: When opening a document would exceed the cache bound, the least-recently-selected cached document other than the one just opened MUST be evicted.
- **evicted-document-flushes-and-closes**: Evicting a cached document MUST flush its pending autosave and release its reference on the shared document store.
- **editor-never-rebuilt-while-cached**: A document's text editor MUST NOT be rebuilt or remounted for as long as that document's location remains in the cache.
- **exactly-one-editor-visible**: Of every mounted cached editor, at most one — the active document's, when one is active — MUST be visible at a time, and exactly one MUST be visible when a text document is active; every other mounted editor MUST be hidden by removing it from hit-testing and keyboard-focus eligibility, not by making it transparent.
- **container-hides-when-nothing-visible**: The editor container itself MUST be hidden when no cached editor is currently the active one, so it does not intercept clicks or scrolling meant for whatever is drawn beneath it (e.g., a system-provided document preview).
- **focus-follows-shown-editor**: When the active document changes and this pane, or nothing, already held keyboard focus, focus MUST move to the newly shown editor.
- **focus-not-stolen-from-elsewhere**: Focus MUST NOT be moved to the newly shown editor when a view outside this pane currently holds keyboard focus.
- **focus-released-when-empty**: When no document is being shown and this pane held keyboard focus, that focus MUST be given up rather than left on a hidden editor.

### Autosave & Persistence

The debounce window is the injected autosave scheduler's own setting, 1 second by default; this component neither sets nor reads that value, it only asks the scheduler to schedule a save.

- **dirty-edit-schedules-save**: Every edit to a cached document MUST schedule that document for a debounced autosave.
- **clean-document-not-scheduled**: A document with no unsaved changes MUST NOT be scheduled for autosave when its change notification fires.
- **outgoing-edits-precede-incoming-read**: Switching away from a document to a different, not-yet-cached document MUST cause the outgoing document's pending autosave to be written before the new document's bytes are read from disk.
- **teardown-flushes-every-cached-document**: When this component is torn down, every document still in its cache MUST have its pending autosave flushed and be closed on the shared document store.

### Language Services

- **language-features-require-services**: Code completion, jump-to-definition, semantic highlighting, and diagnostic annotations for a cached document MUST all be absent when no project language services were supplied.
- **jump-to-definition-requires-openfile-callback**: The jump-to-definition feature for a cached document MUST be absent when no callback for opening another file was supplied, even when project language services are present.
- **semantic-highlight-takes-priority**: When a cached document has a semantic highlight provider, it MUST take priority over the tree-sitter provider for any overlapping styled range.
- **trigger-characters-reresolved-on-session-change**: A cached document's code-completion trigger characters MUST be re-resolved whenever the language-server registry's set of sessions or any session's state changes.

### Theming & Live Configuration

- **editor-follows-environment-theme**: The text editor's chrome and syntax colors MUST be derived from the semantic theme palette in the environment, not from a fixed, hardcoded palette.
- **editor-config-reflects-live-options**: A change to the pane's line-numbers, minimap ("overview"), or invisible-characters display option MUST reach an already-mounted editor without reopening the file.
- **wrap-lines-disabled**: The text editor MUST be configured with line wrapping disabled.

### Error Handling

- **read-failure-shows-placeholder-only**: A file the component cannot read MUST show the "Cannot open this file" placeholder; the component MUST NOT present any additional error dialog, alert, or retry control.
- **autosave-failure-has-no-visible-indicator**: A failed autosave write MUST NOT be surfaced to the user by this component; the affected document remains marked dirty and MUST NOT be discarded. Retrying the write is the injected autosave scheduler's own responsibility, not this component's — see that component's own documentation for its retry behavior.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

