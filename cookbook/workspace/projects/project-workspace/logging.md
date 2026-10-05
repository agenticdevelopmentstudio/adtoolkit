
Subsystem defaults to the app's own bundle identifier; category is this
component's name.

| Event | Level | Message |
|-------|-------|---------|
| Persisting tabs fails | error | `Failed to save project tabs: <error description>` |
| Reading pane state fails (logged as "load") | error | `Failed to load pane state (repo <repo id>, node <node id>, key <key>): <error description>` |
| Writing pane state fails (logged as "save") | error | `Failed to save pane state (repo <repo id>, node <node id>, key <key>): <error description>` |
| Pruning nested pane state fails (logged as "prune", key `"*"`) | error | `Failed to prune pane state (repo <repo id>, node <node id>, key *): <error description>` |
| Reading a project setting fails | error | `Failed to load project setting: <error description>` |
| Writing a project setting fails | error | `Failed to save project setting: <error description>` |
| Reading the project's extra directories fails | error | `Failed to load project directories: <error description>` |
| Writing the project's extra directories fails | error | `Failed to save project directories: <error description>` |

Loading tabs from the database throwing inside reading stored tabs
produces no log line at all — see the pending decision on stored-tabs-load-failure-signal.

