
- **Data collected**: None beyond the in-memory selections the user makes
  while the sheet is open.
- **Storage**: None — selections live only in the two choices' selection
  state for the sheet's lifetime; nothing is written to disk, persistent
  settings storage, or any other store by this file.
- **Transmission**: None — the selection is handed directly to the caller
  in-process; this file makes no network or IPC call.
- **Retention**: None beyond the sheet's lifetime; the selection is
  discarded once the sheet is dismissed, whether via Cancel, OK, or an
  invalid-selection confirm.

