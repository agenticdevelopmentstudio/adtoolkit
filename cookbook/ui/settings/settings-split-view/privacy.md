
- **Data collected**: None beyond the panels and search text the host
  supplies at runtime; the sidebar search query lives only in memory.
- **Storage**: When the content-sized-sidebar flag is `false` (the
  default), the sidebar's dragged width is persisted locally via the
  platform's own split-view width-persistence mechanism, keyed by the
  sidebar persistence key. No other state in this component is persisted;
  the search query and navigation history are in-memory only and are
  discarded when the panel list is replaced or cleared, or on app
  relaunch.
- **Transmission**: Not applicable — no networking call appears anywhere
  in this component.
- **Retention**: The persisted sidebar width remains under its key
  indefinitely, until the user drags it again or the underlying storage
  entry is cleared by the OS or the app; it is never written by this
  component when the content-sized-sidebar flag is `true`.

