
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Screen provider | The screen provider | The live screen provider | Source of live screens, passed to the frame manager. |
| Storage | The window-state storage protocol | The settings-store-backed storage backend, using the shared settings store | Persistence for frames and visibility. |
| Screen manager | The screen manager | none (resolved to the shared screen manager) | Owner of the screen-set list and screen-change observer. |
| State-key prefix | Text | `"WindowState_"` | Frame-state key prefix (both storage implementations). |
| Visibility-key prefix | Text | `"WindowVisible_"` | Visibility key prefix (both storage implementations). |
| Settings store | The settings store | none (required) | Store backing the settings-store-backed storage backend. |
| Recent-windows-count setting | An integer setting | 10 | Mirrored into the platform's recent-documents limit setting. |
| Reopen-on-launch-policy setting | A policy setting ("match the system setting" / "always" / "never") | "match the system setting" | Whether recent documents reopen at launch. |
| Platform reopen-windows-on-quit default | system default (boolean) | false when absent | System default consulted by "match the system setting". |
| Platform recent-documents limit | platform setting (integer) | written by the manager | The platform's recent-documents cap. |
| Window-state namespace | process-wide prefix | "" | Set by isolating to the running bundle or to a path, cleared by resetting. |
| Restorable factories | a map of id to factory callback | empty | Registered by the host via the restorable-registration operation. |

