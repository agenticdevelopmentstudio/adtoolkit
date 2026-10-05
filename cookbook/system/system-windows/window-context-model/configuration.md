
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Window context: `id` | unique identifier | freshly generated | Context identity; supply one to rebuild a known context. |
| Window context: `name` | string | required | User-visible context name. |
| Window context: `color` | string | `"#007AFF"` | `#`-prefixed hex color shown in the menu bar and context list. |
| Window context: `windowSnapshots` | list of window snapshots | empty | Initial snapshots, stored as given. |
| Window context: `lastFocusedWindowID` | optional identifier | absent | Snapshot ID to refocus when the context is switched back to. |
| Window context: `createdAt` | timestamp | current date and time | Creation timestamp; injectable for tests. |
| Window snapshot: `id` | unique identifier | freshly generated | Stable snapshot identity across restarts. |
| Window snapshot: `windowID` | optional window identifier | absent | Current live window identifier; absent means dormant. |
| Window snapshot: `lastSeen` | timestamp | current date and time | Last time the snapshot had a live window; injectable for tests. |
| Window snapshot: `fingerprint`, `savedFrame`, `display`, `app`, `title` | various | required | Identity and restore data, stored verbatim. |
| Window fingerprint: all fields | various | required | No defaults. |
| Window info: all fields | various | required | No defaults. |
| Serialization date format | encoder/decoder configuration | caller's choice | The types impose none; the context store uses ISO-8601. |

