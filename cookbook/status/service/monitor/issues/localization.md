
Not applicable: the only string literals this module constructs are the diagnostic log messages under `shadow-retirement-logged` and `write-failure-log-format`. These are operator-facing server log lines, never rendered to an end user and never sent in the alert-queueing payload — the alert's target/name/environment/state/detail fields are structured data this module copies from its inputs, not text it composes for display; the alert's rendered text is a separate module's concern.

