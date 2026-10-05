
- **Data collected**: None collected by this component. It receives already-fetched
  rows — which include personal contact data (name, phone, email) — as inputs and
  renders them; it performs no data collection of its own.
- **Storage**: None persisted. This component holds only transient UI-selection
  state (the admin-notes target id, the send-modal and add-modal open flags, the
  send seed), which is discarded on unmount and never written to disk, browser
  storage, or a database by this component.
- **Transmission**: None initiated by this component. It calls no network API
  directly; the delete, send, and add callbacks are caller-supplied functions, so
  any transmission of the personal data it displays happens in the caller's
  implementation, not here.
- **Retention**: Not applicable — traced. This component retains no data beyond
  the current render's inputs and its own transient UI state.

