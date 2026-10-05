
The plugin transport is the engine that drives one request specification to
completion and streams the decoded stream events back to the host, regardless
of whether the plugin that built the spec chose an HTTP request or a local
subprocess. It is the one place in the plugin kit that performs actual
networking or spawns a process; a plugin conformer only describes a request
(the request specification) and decodes the response bytes (its stream
decoder), and running a spec through the transport is the sole operation that
turns that description into an HTTP request or a subprocess-driven child
process. It enforces the spec's timeout as a true wall-clock budget over the
whole request, maps that budget's expiry into its own timed-out error, and,
for the command transport, delegates the actual child-process lifecycle to a
subprocess channel.

