
This is one open project: the repository it is, the database rows keyed
to that repository, and the tab/split arrangement its window shows. Per
its own doc comment, it is "what a document object used to be here,
minus the document" — there is no file to read, write, autosave, revert
or name, because a project is a repository row plus the rows keyed to it,
so every edit is already saved and a repository can move on disk without
the project noticing. It owns the project's stored tab tree (reading
stored tabs, computing initial tabs, persisting tabs), an untyped
per-pane and per-project string bag (pane state, project settings), the
project's extra file-browser roots (the file-browser-directories lookup,
persisting project directories), and two directory-keyed object caches —
one for file-browser roots and one for git status — that hold their
values weakly so exactly one instance exists for as long as anything
still needs it. It is confined to the UI's main execution context, and
every property and method is confined there by that declaration alone.

