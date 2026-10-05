
This is the client-side contract for the Hub's "Messaging" product topic: a wire-type set
(a channel/status pair, a template, a log entry and a page of them, a send request and its
result) plus the data-source operation set every network call is delegated to; and the topic
logic that resolves the rail path into a "Send a message" compose form and a "Message log"
list/detail pair, using the injected data source for provider-connectivity status, template
listing, log paging, and the send call itself. Every thrown error from the template-listing,
log-listing, and send operations is normalized to a common error type before it reaches a caller;
a status-check failure is the one exception, deliberately swallowed to a degraded-but-usable
banner rather than propagated.

