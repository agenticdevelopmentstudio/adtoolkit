
- **Data collected**: none in the device- or user-identifying telemetry sense. However, `declaredLocalResourceRoots`, and every location that resolving local resource roots returns, are absolute local file-system paths; when the default (undeclared) root list is used, those paths necessarily embed wherever the extension directory and each workspace folder happen to live on the local machine, which can include the local account's home-directory name.
- **Storage**: none performed by this component itself — it writes to no file and no database. Its serialization support exists so that a caller, specifically the pane-state persistence layer, can persist a value of this component verbatim into the app's own pane-state store as part of restoring a panel after a quit; this component never performs that write itself.
- **Transmission**: none — this component performs no networking of its own.
- **Retention**: for as long as the caller (or, downstream, the pane-state store a persisted value is written into) retains it; this component itself retains nothing once a call returns.

