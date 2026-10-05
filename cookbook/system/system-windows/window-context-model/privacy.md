
- **Data collected**: The types hold window metadata about other apps: owning app name, process ID, window title, frame and display. Window titles can contain document names, web page titles or message subjects, so they are potentially personal.
- **Storage**: The types store nothing themselves; in memory only. The context store persists contexts, including each snapshot's `title` and the fingerprint's `titlePattern`, as JSON files on local disk.
- **Transmission**: The types never transmit data; no operation performs network access.
- **Retention**: A snapshot's `title` and fingerprint stay in the context until the remove operation removes the snapshot; dormant snapshots are kept, not expired, and nothing in these types deletes data by age.

