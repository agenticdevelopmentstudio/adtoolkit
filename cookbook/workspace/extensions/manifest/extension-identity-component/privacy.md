
- **Data collected**: None — the safety check receives the manifest field
  value the caller already holds in memory and returns a true/false result;
  it stores nothing.
- **Storage**: Not applicable — no data is persisted by this component.
- **Transmission**: Not applicable — no data leaves the device; the check
  performs no network or inter-process operation.
- **Retention**: Not applicable — the input value is not retained beyond
  the single call; the component has no instance to hold it in.

