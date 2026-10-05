
- **Data collected**: None by the client. It only displays error-issue summaries (`title`, `culprit`, `count`, `userCount`, `permalink`) and anonymous aggregate KPIs that the server provides.
- **Storage**: The latest `TelemetrySnapshot`, stored as JSON in browser localStorage under `adh-telemetry-v1`.
- **Transmission**: HTTP GETs to the status API through `StatusApiClient`. Nothing is sent upstream.
- **Retention**: The cached entry lasts until the next successful `save` overwrites it, or until the user clears site data. There is no expiry.

