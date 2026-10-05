
This feature exposes a single shared logger for its own messages;
subsystem defaults to the app's own bundle identifier, category is this
feature's name.

| Event | Level | Message |
|-------|-------|---------|
| Renaming's database write failed | error | `Rename failed for <repo id>: <error>` |
| Opening a project's open-time write failed | error | `Could not record open time: <error>` |
| Scan-finishing insert failed | error | `Could not add <repo path>: <error>` |
| Scan-finishing update failed | error | `Could not update <repo path>: <error>` |
| Scan-finishing delete failed | error | `Could not remove <repo path>: <error>` |
| Scan-finishing completed | info | `Scan complete: <summary text>` |

Construction's and reloading's failed reads of all repositories, and
stopping's failed checkpoint, make no log call at all — see
**database-read-failure-unsignaled** and
**stop-checkpoint-failure-unsignaled**.

