
- **Data collected**: None collected by this component itself. It only
  renders whatever lines the provider already holds, including each
  line's opaque `context` payload, which this component never reads
  itself — it only forwards the whole line to a column's click hooks.
- **Storage**: None. The component writes nothing to disk or to any
  settings store.
- **Transmission**: None. The component makes no network calls.
- **Retention**: Determined entirely by the provider. This component keeps
  no copy of the data beyond what it reads from `provider.lines` at render
  time; any row-count cap (`maxLines`) is the provider's own concern, not
  this component's.

