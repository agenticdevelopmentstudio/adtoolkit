
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| git client | a git client reference | the shared git client | The git client every project controller this manager builds is given, through the workspace. |
| command registry | a command registry reference (optional) | absent | Passed to every project controller this manager builds; absent disables command-palette integration for every project. |
| language-services factory | a function from a project's directory to language services (optional) | absent | Called with a project's directory each time opening a project builds a new workspace; absent, or a factory returning nothing, opens the project with no language services. |
| project-closed callback | a callback (optional) | absent | Fired once, synchronously, from the window-close handling, before the closing project's workspace is dropped from the open-controllers table. |
| open-projects-changed callback | a callback (optional) | absent | Fired after every mutation of the open-project set, from refreshing the open-workspace-ids list. |
| coordinator | a coordinator reference, held weakly (optional) | absent until attached | Supplies the database (required for opening a project to proceed) and the repository list (read by restoring open projects); set by attaching to a coordinator, which also registers the manager as that coordinator's opener. |
| app-activation call (internal, test-only seam) | a function with no arguments | asks the app to come forward, unless already active | How a newly or already-open project window asks the app to come forward; overridable so a test can count activations instead of driving real app state. |

This file reads no environment variable and no settings key of its own
beyond the single per-project setting row it reads and writes, keyed by
the setting key `"window.open"`.

