
- **Data collected**: the titles, pids and window numbers of every titled window owned by a regular app, plus each app's localized name and icon.
- **Storage**: in memory only, in `apps`; nothing is written to disk.
- **Transmission**: none; no data leaves the device.
- **Retention**: until the next discovery replaces `apps` or the model is released. The activation log line records the chosen window's title as public (unredacted) text in the unified log, where it is retained under the system's log policy.

