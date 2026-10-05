
- **Data collected**: This component collects nothing on its own; `message`, `detail`, and `itemTitles` are whatever text the calling extension supplied to a `vscode.window.show*Message` call, held only as the fields of one `ExtensionMessageRequest` value for the lifetime of a single `presentMessage(_:)` call.
- **Storage**: This component performs no storage of its own; nothing here persists a request beyond the call it was built for.
- **Transmission**: This component performs no network transmission; the request value is passed in-process, from whatever constructs it to whichever conformer presents it.
- **Retention**: No value defined here outlives the `presentMessage(_:)` call it was constructed for; the type keeps no cache, log, or history of past requests.

