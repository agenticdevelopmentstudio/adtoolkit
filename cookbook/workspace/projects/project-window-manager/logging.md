
This file makes five logging calls. Subsystem defaults to the app's own
bundle identifier; category is this component's name.

| Event | Level | Message |
|-------|-------|---------|
| The database is absent when opening a project | error | `Cannot open <repo.name>: no project database attached` |
| The language-services factory is absent, or returns nothing | info | `No language services for <repo.name>: no factory wired` |
| A flagged-open repository's folder is missing at restore | info | `Not reopening <repo.name>: its folder is gone` |
| Reading the window-open flag fails | error | `Could not read window state for <repoID>: <error>` |
| Writing the window-open flag fails | error | `Could not record window state for <repoID>: <error>` |

