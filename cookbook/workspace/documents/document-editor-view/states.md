
| State | Appearance change |
|-------|------------------|
| Default | Editor shows the displayed file, or an empty editor state (delegated to the file editor, out of scope) when no file is displayed |
| Pressed | Not applicable: this component is a container. The reset button's and toggles' own pressed appearance is drawn by the platform and their own controls, out of scope for this recipe. |
| Disabled | Not applicable to the container itself; the reset button is individually enabled or disabled (see **reset-button-enabled-matches-override**) — not the whole editor. |
| Focused | Not applicable: this file sets no custom focus-ring drawing; keyboard focus on its buttons and toggles is the platform's own default rendering. |
| Loading | Not applicable: every method in this file is synchronous. Any asynchronous loading of file content belongs to the file editor / document store, out of scope. |
| File open | Breadcrumb shows the path from the project root to the displayed file; the pane title is the file's last path component. |
| No file (no file displayed) | Breadcrumb is empty; the pane title is `"Untitled"`. |
| An option overridden in this pane | The gear popover's reset button is enabled; the overridden toggle(s) reflect the pane-local value rather than the app-wide setting. |
| No option overridden in this pane | The reset button is disabled; every toggle reflects the app-wide setting. |

