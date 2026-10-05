
- **Data collected**: Note text entered by the admin, staged only in the component's own
  in-memory state (the working list) while the dialog is open.
- **Storage**: The component itself persists nothing; it holds the working list in memory
  only. Durable storage is entirely the responsibility of the caller's `onSave` handler and
  backend, not observable in this file.
- **Transmission**: None performed by this component; `onSave` hands the `{id, content}`
  pairs to the caller, which decides whether/how to transmit them.
- **Retention**: The working list is discarded (reset to `notes`) whenever the dialog closes,
  whether via Cancel, Escape, close, or a caller-driven `open=false` after a successful save.

