
| State | Appearance change |
|-------|------------------|
| Empty (no selected node, or a directory/package is selected) | Shows the placeholder: 48pt document icon in the tertiary-text role, "Select a file to view its contents" in the heading font / secondary-text role |
| Loading (a not-yet-cached file is being read) | Shows a centered progress indicator, filling the available space |
| Text (a cached document is active) | The active document's own cached text editor is shown; every other cached editor is mounted but hidden |
| System Preview (oversized or non-UTF-8 file) | Shows the platform's own document preview for that file; a format the preview has no renderer for draws its own "no preview available" (out of scope — the preview's own behavior) |
| Unavailable (the file could not be read) | Shows the placeholder: 48pt document icon in the tertiary-text role, "Cannot open this file" in the heading font / secondary-text role |
| Pressed | Not applicable: this component itself defines no button or tappable control; a mounted text editor's own pressed/click appearance is out of scope. |
| Disabled | Not applicable: the component has no enabled/disabled concept of its own; nothing it directly renders is conditionally interactive. |
| Focused | This component moves keyboard focus to the newly shown editor's text view when this pane already held focus or held none (see **focus-follows-shown-editor**, **focus-not-stolen-from-elsewhere**, **focus-released-when-empty**); the focus ring itself is drawn by the hosted editor, out of scope. |

