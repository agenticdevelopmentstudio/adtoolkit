
- **Data collected**: This file collects no data directly. It constructs a
  help panel presenter and assigns it as the hosted split view's help
  presenter; that presenter independently persists whether the settings
  help panel is visible — that persistence belongs to the help presenter, a
  separate ingredient, not to this file. This file's own state (activate-on-
  show, the assigned panel list) is held in memory only.
- **Storage**: Not decided in this file. Window-frame geometry for the
  `"settings"` window id is persisted locally by inherited
  window-lifecycle/window-management machinery; this file contains no
  storage call of its own.
- **Transmission**: None — no networking import or call appears in this
  file.
- **Retention**: Not decided in this file; see Storage and Data collected
  above for which components own the data this window causes to be
  persisted.

