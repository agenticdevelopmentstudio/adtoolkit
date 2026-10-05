
- **Data collected**: None by the component itself. It holds the query
  text, result list, loading flag, and error message in transient local
  state.
- **Storage**: In-memory only, for the lifetime of the mounted component;
  cleared back to initial values whenever it closes (resets-on-close).
  No persistent storage is used.
- **Transmission**: The component makes no network call itself; any
  transmission happens inside the caller-supplied search function, which
  is outside this component's own logic.
- **Retention**: None — state does not survive a close, and nothing is
  written to durable storage.

