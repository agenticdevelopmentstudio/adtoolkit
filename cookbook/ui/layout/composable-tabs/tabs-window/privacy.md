
- **Data collected**: the window's frame (position and size) keyed by
  project id; the project's full tab layout (split tree, titles, working
  directories, focused-leaf id, active-tab id, enabled edges); the help
  drawer's per-project preferences (`drawer.open`, `drawer.tab`,
  `drawer.width`, stored under `project_setting`).
- **Storage**: window frame is stored locally, keyed by the window's
  derived identifier; tab layout and drawer preferences are stored locally
  in the project's own settings/database. No networked store is used
  anywhere in this file.
- **Transmission**: none. No networking import or call appears in this
  file; everything persisted here stays on the local device.
- **Retention**: the window frame persists until the project's saved window
  state is explicitly cleared. Tab layout and drawer preferences persist
  until overwritten or the project is deleted. Drawer tab/width are written
  only after help has been disclosed at least once; a project whose help
  was never opened stores none of that preference.

