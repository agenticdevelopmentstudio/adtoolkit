
Every user-facing string in these components is a hardcoded English literal with no string-catalog lookup: the description of both error types, the model's `lastError` prefixes, and the notification body.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `Failed to load state: <error>` | `lastError` when loading state fails |
| (none; literal) | `Failed to create <contextNoun>: <error>` | `lastError` on create; the noun comes from configuration |
| (none; literal) | `Failed to delete context: <error>` / `Failed to rename context: <error>` / `Failed to update context color: <error>` / `Failed to switch context: <error>` | `lastError` on those operations |
| (none; literal) | `Failed to add window: <error>` / `Failed to remove window: <error>` / `Failed to assign window: <error>` / `Failed to skip item: <error>` | `lastError` on window operations |
| (none; literal) | `Failed to add heuristic rule: <error>` / `Failed to update heuristic rule: <error>` / `Failed to delete heuristic rule: <error>` | `lastError` on rule operations |
| (none; literal) | `Re-matching failed: <error>` | `lastError` from launch reconciliation |
| (none; literal) | `Unmatched item not found.` | `lastError` from assigning a window |
| (none; literal) | `No active context. Switch to a context first.` | `lastError` from adding the frontmost window |
| (none; literal) | `No window found to add.` / `No window found to remove.` | `lastError` from the frontmost-window actions |
| (none; literal) | `This window is not assigned to any context.` | `lastError` from removing the frontmost window |
| (none; literal) | `<n> window needs assignment` / `<n> windows need assignment` | Notification body, pluralized by an English-only `count == 1` test |
| (none; literal) | `Context not found: <uuid>`, `Window <id> is already assigned to context '<name>'`, `Failed to persist state: <error>`, and the other error descriptions | Surfaced through `lastError` via the underlying error's description |

Only `contextNoun` is host-configurable; the other messages say "context" regardless of the configured noun.

