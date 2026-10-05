
This is the project registry feature: one database, the in-memory list of
known git repositories, and the background scan that keeps that list true
to disk. Its own doc comment states the model directly — "a 'project'
here is a row, not a file," so a repository can be renamed or moved on
disk without losing its settings or window layout. It is a top-level app
feature: the host constructs it once during launch, and it registers two
commands and two menu contributions on the caller's command registry at
construction time so a palette, a shortcut, or an extension can reach
"Open Project…" and "Scan for Projects" by id. It owns none of the
scanning, reconciling, persisting, or window-presenting logic itself —
those are the scanner, the reconciler, the database, and the
project-opening interface and its chooser/progress windows, respectively
(see their own recipes) — this feature only sequences calls to them and
republishes the result through its repository list and its change
notification.

