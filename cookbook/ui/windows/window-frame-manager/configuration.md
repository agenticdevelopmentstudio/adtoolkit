
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Screen provider | The screen provider | The live screen provider | Source of live screens and the main screen. |
| Storage | The window-state storage protocol | The default storage backend | Persistence for per-window state and visibility. |
| Screen manager | The screen manager | none (required) | Supplies the current screen-set id, known set ids, maximum set age, the current time, a refresh operation, and screen-change events. |
| Window lister (internal) | A callback returning the live window list | The platform's own list of app windows | Source of live windows for screen-change repositioning; injectable in tests. |
| Minimum size / default size / default position (window spec) | Size / Size / window position preset | per spec | Sizing floor and default frame. |
| "Persists frame" (window spec behavior) | option bit | on (in the default behavior set) | Enables frame save/restore for the id. |
| "Persists visibility" (window spec behavior) | option bit | on (in the default behavior set) | Enables visibility save/load for the id. |
| State-key prefix (default storage backend) | Text | `"WindowState_"` | Key prefix for state blobs (namespaced by the window-state namespace). |
| Visibility-key prefix (default storage backend) | Text | `"WindowVisible_"` | Key prefix for visibility flags (namespaced by the window-state namespace). |
| Anchors (content-hugging frame calculation) | An optional pair of anchors | none | Anchors carried across steps of one resize gesture; none picks them by nearest edge. |

