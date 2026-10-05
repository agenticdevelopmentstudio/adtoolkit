
This controller makes one logging call of its own: reading checkouts'
failure handler, on a failed worktree read. The logging category is the
project controller's own name.

| Event | Level | Message |
|-------|-------|---------|
| Worktree read failed | error | `Failed to read worktrees for <directory>; keeping last checkouts` |

