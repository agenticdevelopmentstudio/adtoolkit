
This component is the project browser's single SQLite-backed registry: one
file, one connection, one append-only migration chain, holding every fact
about every git repository the app knows about — its `git_repo` row
(identity, path, name, remote, timestamps) and its per-project settings
key/value bag. Per its own design rationale, "there is no per-project file:
a project is a row and the rows that reference it," which is what lets a
repository move on disk without losing its settings, layout, or
user-assigned name (`optimize-for-change`). It owns exactly one SQLite
connection per instance, opens it and brings its schema current
synchronously as part of construction, and exposes CRUD for `git_repo` rows
and `project_setting` rows as its public surface. Its own migrations create
the tables a sibling extension (a separate source file, out of scope for
this recipe) later reads and writes for layout, tab, and pane-state data;
the note store that shares this same on-disk file keeps its own migration
bookkeeping under its own table name so the two chains cannot collide.

