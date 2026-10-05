
- **Data collected**: None by this component directly. It displays
  whatever connection state, error text, and rows the injected
  controller/log view provide; it captures no input beyond Pause and
  Clear button clicks.
- **Storage**: This component writes nothing to disk or to any settings
  store.
- **Transmission**: None. The component makes no network calls
  itself — any transport (SSE, HTTP, file-tail) belongs to the injected
  controller implementation, a separate component out of this recipe's
  scope.
- **Retention**: Not applicable. This component keeps no state of its own
  beyond the controller/view references it is constructed with.

