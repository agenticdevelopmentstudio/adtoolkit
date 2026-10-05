
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `existing` (plan input) | list of repository records | none — required | The registry's current records, as read by the caller before scanning. |
| `scanned` (plan input) | list of scanned repository entries | none — required | What a directory walk just found. |
| `now` (plan input) | point in time | current time at the call | The timestamp written into every touched record's `lastSeen`, and into `firstSeen`/`lastSeen` for a new insert. |
| `isStillARepository` (plan input) | path-to-boolean check | the built-in repository-existence check | Consulted once per missing record to decide skip-versus-delete; injected so the plan operation itself never touches the filesystem. |
| `path` (repository-existence check input) | string | none — required | The candidate directory to check for a `.git` entry. |
| `path` (naming rule input) | string | none — required | The scanned repository's path to derive a display name from. |
| `taken` (naming rule input) | set of strings | none — required | Names already in use; the caller seeds it from every existing record's `name` and grows it across one plan call's insert pass. |

Nothing here reads an environment variable or a settings key; every input
arrives as an explicit parameter.

