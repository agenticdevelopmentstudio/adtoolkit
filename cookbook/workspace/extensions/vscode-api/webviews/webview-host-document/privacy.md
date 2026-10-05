
- **Data collected**: This component collects nothing itself; it passes
  through whatever initial state (the JSON text of persisted pane state)
  and, once a page runs the generated bootstrap, whatever `postMessage`/
  `setState` bodies the extension supplies — content this component never
  inspects.
- **Storage**: Not applicable to this component. It performs no persistence
  of its own; the pane-state database is a separate component (the
  pane-state persistence layer) outside this component's scope.
- **Transmission**: The document this component produces is loaded into a
  webview in the same process; the injected bootstrap relays
  `postMessage`/`setState` bodies to the native host via the message
  channel, which is an in-process call, not a network transmission.
- **Retention**: Not applicable to this component — building the host
  document returns a document per call and retains nothing between calls.

