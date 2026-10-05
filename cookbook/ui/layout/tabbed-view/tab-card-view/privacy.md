
- **Data collected**: None by this component itself. It renders
  caller-supplied display strings (agent/model name, session name,
  working-directory path, branch name, summary) and caller-supplied status
  symbols; it does not capture, log, or forward any of it elsewhere.
- **Storage**: In-memory only, for the life of the view. Nothing in this
  component persists to disk.
- **Transmission**: Not applicable — no networking call appears anywhere in
  this component.
- **Retention**: None beyond the view's own lifetime.

