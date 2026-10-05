
- **Data collected**: this component collects nothing of its own; the
  request's message, detail, and item titles are whatever text the calling
  extension supplied to a `show*Message` call, held only as fields of the
  request value for the duration of one presentation call.
- **Storage**: this component performs no storage of its own; nothing here
  persists a request past the call it was built for.
- **Transmission**: this component performs no network transmission; the
  request is presented in-process to whatever window resolving the
  presentation window resolves.
- **Retention**: the one thing that outlives a single call is the
  dropped-message log line resolving the response writes when resolving
  the presentation window returns nothing; that line includes the alert's
  message text (i.e., the request's message), logged so that it is not
  redacted from the log, whatever text the calling extension put in that
  message; retention of that log entry itself is governed by the
  platform's own logging policy, not by this component.

