
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `repos` (build input) | list of repositories | none — required | The flat registry rows to arrange into a tree; order within this list determines which node is created first at a shared ancestor path (see Edge Cases). |
| `homeDirectory` (build input) | directory reference | the current user's home directory | The directory whose own path components are omitted from the display, per `trail-under-home-truncation`. |

This file reads no environment variable, settings key, or injected
dependency beyond these two parameters.

