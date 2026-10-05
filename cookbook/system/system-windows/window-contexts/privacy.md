
- **Data collected**: application names, window titles, window frames, and display IDs of other applications' windows, plus user-chosen context names and colors and custom rule definitions.
- **Storage**: plain, unencrypted, pretty-printed JSON files under the caller-supplied root (`state.json`, `contexts/<uuid>.json`, `heuristics.json`), written with mode defaults except the `.lock` file (`0644`); settings go to persisted user settings under `settingsKey`.
- **Transmission**: nothing leaves the device; the only outbound effect is a local user notification whose body carries a count, not titles.
- **Retention**: files persist until the context is deleted (its file is removed), everything is removed, or the user deletes the directory; skipped or orphaned context files are never cleaned up automatically.
- **Logs**: log messages interpolate context names, app names, and window IDs (for example "Created context '<name>'"); logged values are private by default, so those values are redacted in release logs unless marked public.

