
- **Data collected**: None collected by this component itself. It holds
  the permissions list it was constructed with (which privacy permissions
  to display) and forwards status/request calls to the injected checker;
  it inspects no personal data itself.
- **Storage**: None. The component writes nothing to disk or to any
  persisted store. (Recording a remembered keychain grant is the status
  checker's own concern, a different component's responsibility.)
- **Transmission**: None directly. Any cross-process communication a
  status read or grant request needs (a system event, a system consent
  dialog, a location-service round trip, etc.) happens inside the injected
  checker, not in the component itself.
- **Retention**: None beyond the life of the instance. The panel keeps its
  permissions list and its live rows in memory only; it persists nothing
  across launches.

