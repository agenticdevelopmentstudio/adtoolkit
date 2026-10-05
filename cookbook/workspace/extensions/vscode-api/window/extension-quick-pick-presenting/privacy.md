
- **Data collected**: This component collects no data of its own; `ExtensionQuickPickItem` and `ExtensionQuickPickRequest` hold only values the calling extension already supplied for that one presentation.
- **Storage**: Not applicable — this component performs no storage; a value exists only for the duration of one `presentQuickPick` call.
- **Transmission**: Not applicable — this component transmits nothing itself; it is presented on-device by whatever conformer is in use.
- **Retention**: This component retains nothing beyond the lifetime of one `presentQuickPick` call's local state.

