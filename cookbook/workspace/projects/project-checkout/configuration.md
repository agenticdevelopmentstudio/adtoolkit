
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` (construction parameter) | location value | none — required | Directory this checkout represents; stored as the symlink-resolved form of the caller's value, never the caller's unresolved value. |
| `branch` (construction parameter) | string, optional | none — required, may be absent | The checkout's live branch name, or absent when the worktree is in a detached-HEAD state. |
| `isMain` (construction parameter) | boolean | none — required | Whether this checkout is the repository's main worktree, typically forwarded from the source worktree record's own `isMain` field. |
| `worktrees` (projection parameter) | list of worktree records | none — required | The full worktree list, typically parsed from `git worktree list --porcelain` output, projected into checkout values with bare entries removed. |

Creating a checkout reads no environment variable and no persisted settings
key; every value it holds is supplied directly by its caller.

