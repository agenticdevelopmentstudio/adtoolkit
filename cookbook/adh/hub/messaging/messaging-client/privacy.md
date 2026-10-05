
- **Data collected**: this component itself collects nothing new — it reads and forwards
  recipient contact information (an email address or phone number, via the send request's
  `recipient` field or the log entry's `recipient` field the log already contains) and message
  content (`subject`, `body`, `templateVars`) that the caller supplies or the backend has already
  recorded.
- **Storage**: this logic writes none of this to disk or to platform-managed credential/preference
  storage; the topic logic holds no mutable stored state at all, so nothing it handles outlives
  the current form's/detail's state.
- **Transmission**: the send operation transmits the assembled send request (recipient,
  subject/body or template selection and variables) to the injected data source; the log operation
  receives already-sent message content, including recipient and body, back from it. Actual
  network transport is the injected data source's concern, out of scope of this recipe.
- **Retention**: not controlled by this logic — the backend behind the data source owns how long a
  log entry (recipient, subject, body) persists; this logic only reads and displays whatever the
  backend currently returns.

