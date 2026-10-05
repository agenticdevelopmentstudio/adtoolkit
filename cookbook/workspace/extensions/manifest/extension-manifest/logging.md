
Not applicable: no logging call of any kind appears anywhere in this
component. The recorded decoding failures are structured data this
component returns to its caller rather than logs — the source's own doc
comment states the failure reason is rendered verbatim by "the settings
panel's Decisions group," a separate component outside this component's
scope that may do its own logging or presentation; this component itself
writes no log line.

