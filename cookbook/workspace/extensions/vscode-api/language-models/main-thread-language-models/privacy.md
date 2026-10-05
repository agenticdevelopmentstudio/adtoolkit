
- **Data collected**: this component collects no data of its own; it handles whatever `messages`, `justification`, tool-call arguments, and streamed response text an extension supplies to or receives from `sendRequest`, none of which this component logs.
- **Storage**: conversation messages and streamed response parts are held only in the injected request's in-memory buffer for the lifetime of that request; nothing here writes to disk, a database, or any persistent store.
- **Transmission**: this component makes no network call of its own; whatever transmission the provider's response-streaming call performs is the seam's responsibility, not this component's.
- **Retention**: per **dispose-retains-live-requests** and **check-completion-both-cursors**, a request's buffered parts (which may include conversation text and tool-call arguments) stay retained in the live-request set for the rest of this component's lifetime if the extension never fully iterates both `stream` and `text` — a deliberate memory-retention cost, not a leak the source treats as a bug.

