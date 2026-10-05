
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| repository | a repository reference | none — required | The repository this project is; supplies the id, display name, and directory. |
| database | a database reference | none — required | The one shared database every persisted read/write in this file goes through, scoped by the repository's id. |
| layout | a layout reference (optional) | absent → the app-installed layout, or a placeholder-only layout otherwise | Which views this project may show and which arrangements of them are legal. |
| language services | a language-services reference (optional) | absent | This project's language servers; absent disables language-service support for the project. Lifecycle owned by the project window manager, not by this file. |
| git client | a git client reference | the shared git client | The git client the git-status-provider lookup builds every provider on. |

This file reads no environment variable and no settings key of its own;
the project-scoped setting/read-setting pair is a caller-defined
key/value bag this file only routes to the database, not a source of
configuration for the workspace itself.

