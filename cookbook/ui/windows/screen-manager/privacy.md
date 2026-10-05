
- **Data collected**: Per screen set, the member displays' UUIDs, system localized names, frames, visible frames, scale factors and main-display flags, plus first-seen / last-seen timestamps.
- **Storage**: One JSON-encoded blob under the `ScreenSets` key in the settings store's non-secure provider (the platform's standard preferences store by default).
- **Transmission**: None; nothing leaves the device (the log line goes to the unified log).
- **Retention**: Each set is kept until it has gone unseen for the maximum age (180 days by default), then dropped at the next persist.

