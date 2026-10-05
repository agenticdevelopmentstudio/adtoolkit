
- **Data collected**: None collected or persisted by this view; it only
  displays a status value handed to it by the injected status checker.
- **Storage**: The most recently applied status is held in memory for the
  lifetime of the component instance only; nothing is written to disk by
  this component.
- **Transmission**: None. This component makes no network call; the status
  checker reads local system authorization state, which is not something
  this component itself performs.
- **Retention**: For the lifetime of the view instance; discarded on
  deallocation, with no persistence layer in this component.

