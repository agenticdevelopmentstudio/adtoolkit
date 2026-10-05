
- **Data handled**: A request specification's headers, body, standard input,
  and environment MAY each carry a credential a plugin embedded into the
  request description (see the sibling request specification recipe's own
  Privacy section); this component itself has no knowledge of which values
  are secret — it forwards every one of them to the outgoing request or to
  the spawned subprocess exactly as given, and forwards every response byte
  and every standard-error byte to the plugin's decoder and
  error-description operation exactly as received, with no inspection of
  its own.
- **Storage**: This component performs no storage of its own — it holds
  request and response data only in memory, for the lifetime of one run
  invocation.
- **Transmission**: For an HTTP request, the transport transmits the headers
  and body to the given address; for a command request, it writes standard
  input and environment only to a locally spawned child process — no network
  transmission occurs for the command path itself, only whatever the spawned
  process independently performs.
- **Retention**: None. A response's bytes and any decoded stream events exist
  only for the duration of the stream a caller iterates; nothing is cached
  or retained past that iteration, except for the subprocess channel's own
  bounded (1 MB) standard-error buffer, which is released with the channel.

