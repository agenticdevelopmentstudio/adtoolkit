
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Pane-state store | pane-state store (required at init) | required at init | Where the displayed file's path is read and written under the file-URL key. An ephemeral store forgets its values when deallocated; a project window supplies a store backed by durable local storage instead (see Privacy, Storage). |
| Document store | document store (required at init) | required at init | Passed through unchanged to the hosted file editor (out of scope). |
| Save scheduler | save scheduler (required at init) | required at init | Passed through unchanged to the hosted file editor (out of scope). |
| Language services | optional language services (required at init, may be absent) | required at init (may be absent) | Passed through unchanged to the hosted file editor (out of scope). |
| Project root | URL (required at init) | required at init | The project root the breadcrumb computes its crumbs relative to; handed to the breadcrumb at construction and never changed afterward. |
| Display-option overrides | per-pane override (created at init from the pane-state store) | created at init from the pane-state store | This pane's independent override of the three editor display toggles; publicly readable, not settable. |
| Displayed file | URL (optional) | none, or restored from the pane-state store at init | The file currently displayed. Setting it updates the selection, the breadcrumb, and the store, and fires the title-change callback. |
| Title-change callback | optional callback | none | Called after every change to the displayed file. |
| Pane title | string (read-only) | the displayed file's last path component, or `"Untitled"` | Read-only; see **pane-title-is-filename**, **pane-title-untitled-when-empty**. |
| Pane-title-change callback | optional callback | none | Getter/setter bridge onto the title-change callback; see **title-change-callback-bridge**. |
| Open-request callback | optional callback receiving a URL | none | Called with a URL the breadcrumb or the hosted editor resolved but did not open in place. |

### Methods

| Method | Description |
|--------|-------------|
| Clear document | Unsets the displayed file and persists that, without removing the pane; see **clear-document-preserves-pane**. |

