
- **Data collected**: window owner names and titles are read in memory from the live window records the caller passes; titles can contain document names, page titles and hostnames.
- **Storage**: only user-authored custom heuristic rules are persisted, as plain JSON in `<root directory>/heuristics.json`; fingerprints are persisted by the caller's context store, not by this component.
- **Transmission**: nothing leaves the device.
- **Retention**: `heuristics.json` persists until overwritten by a save or deleted by clearing all rules.
- **Logs**: invalid-regex errors log the pattern with `privacy: .public`; the window title is not logged.

