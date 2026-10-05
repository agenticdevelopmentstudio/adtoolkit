
None of the strings below are passed through a localization mechanism
anywhere in this component; every user-facing string is a hardcoded English
literal, or a fixed mapping from a status/permission value to a literal
string.

Every string below reaches the UI unlocalized; a port should decide whether
to route them through its own string catalog, since the source gives no
keys to carry over.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded, unlocalized) | `Checking…` | Initial status label text, before the first refresh completes. |
| (none — hardcoded, unlocalized) | `Granted` | Status label text when the status checker returns granted. |
| (none — hardcoded, unlocalized) | `Not Granted` | Status label text when the status checker returns denied. |
| (none — hardcoded, unlocalized) | `Unknown` | Status label text when the status checker returns undetermined. |
| (none — hardcoded, unlocalized) | `Open Settings` | Action button title when granted, or when the permission has a settings pane and is not yet granted. |
| (none — hardcoded, unlocalized) | `Allow…` | Action button title for a permission with no settings pane (Keychain) and not yet granted. |
| (none — hardcoded, unlocalized) | The permission's display-name values, e.g. `Accessibility`, `Notifications`, `Automation`, `Location`, `Microphone`, `Screen Capture`, `Keychain` | Row title, from the permission's display name. |
| (none — hardcoded, unlocalized) | The permission's explanation sentences | Row description text. |

