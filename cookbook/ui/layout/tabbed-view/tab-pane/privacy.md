
- **Data collected**: None of its own. The component displays agent name,
  model name, session name, working directory, branch, and summary that the
  data source supplies; it never gathers, derives, or forwards data beyond
  what it is handed to render.
- **Storage**: None - displayed values live only as in-memory state for as
  long as the view controller exists; nothing is written to disk or
  persisted settings.
- **Transmission**: None - the component performs no networking; it never
  sends any of the data it displays anywhere.
- **Retention**: None beyond the pane's own lifetime - display state is
  replaced wholesale on the next reload and discarded when the view
  controller is deallocated.

