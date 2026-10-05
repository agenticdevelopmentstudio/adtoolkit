
- **Data handled**: A text-delta or tool-use event MAY carry conversation
  content or tool-call arguments the provider or model produced for one
  chat turn; this component itself defines no credential or token field —
  those live in the sibling provider-configuration and chat-context types,
  not here.
- **Storage**: This component performs no storage of its own — see
  no-persistence-or-caching above; a decoder's buffered bytes and any
  decoded events live only in memory for the duration of one response
  stream.
- **Transmission**: This component never transmits data; it only decodes
  bytes the host's transport has already received.
- **Retention**: None — a stream event is not retained past the
  event-sequence iteration that consumes it, and a decoder's internal
  buffer is discarded with the decoder instance once its one response
  stream ends.

