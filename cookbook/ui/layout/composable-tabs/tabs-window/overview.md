
The window is the top-level container for one project's workspace. Its
content hosts up to four docked tab bars — top, right, bottom, left — each
tab wrapping a split-pane tree rooted at a persisted layout. One
project-level "tab" is a *group*: one member tab per currently enabled edge,
all sharing a title and a working directory, so opening, closing, or
renaming a tab acts on the whole group at once rather than on a single
bar's button. The window also owns a unified toolbar (a search field, a
help toggle), two trailing title-bar accessory buttons (arrange mode,
project settings), a bottom status footer, and a per-project help drawer,
and it exposes a scripting-facing surface (a tab handle, pane/tab lookup,
search and tab-selection accessors) that an external automation bridge can
address directly.

