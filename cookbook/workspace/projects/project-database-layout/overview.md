
This is an extension of the project database that persists everything a
project window's tab-and-pane arrangement needs to survive a relaunch: the
tabs docked to each edge, the split tree of panes inside each tab, per-pane
UI state (sizes, expansion, selection — whatever a caller stores under a
string key), and the extra directories a project's file browser shows
beyond the repository root. The project database itself owns the SQLite
connection, the schema migrations that create the five tables this
extension reads and writes (`project_tabs`, `layout_nodes`,
`project_state`, `pane_state`, `project_directories`), and the low-level
execute/query helpers this extension calls; this extension adds no schema
and no connection state of its own — it is purely a set of operations
layered onto the base component.

Every row this extension touches is scoped to one `repo_id`, matching a
`git_repo.id` row owned by the project database's core methods; nothing
here reads or writes a row for any repository id other than the one a
caller passes in. The project database carries no concurrency-safety
guarantee of its own (see the sibling
`adtoolkit://cookbook/workspace/projects/project-database` recipe),
so this extension's operations carry no concurrency guarantee of their own
either — they run wherever the caller runs, synchronously, against one
shared SQLite connection.

