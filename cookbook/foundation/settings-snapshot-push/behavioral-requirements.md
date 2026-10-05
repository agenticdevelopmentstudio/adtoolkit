
- **caller-supplied-pieces**: The push MUST be built from a label naming the channel in log lines, a logger, a snapshot builder that returns the body or nothing, a sender that returns whether the receiver took the body, and a reconnect registrar; it MUST NOT decide what the snapshot holds, how it is encoded or how it travels.
- **start-observes-and-pushes**: Starting MUST begin observing the given settings, MUST push the snapshot immediately (observers fire only on change and the receiver may have restarted), and MUST re-push on every change of an observed setting.
- **mixed-type-start**: Starting MUST also accept a builder that is handed the change handler and returns the observers it created, for settings of mixed types, and MUST keep those observers alive until stop.
- **start-once**: A repeat start while observing MUST be ignored and MUST log a warning naming the label.
- **reconnect-registered-once**: The reconnect handler MUST be registered once per instance, on the first start, and MUST NOT be registered again by later starts.
- **reconnect-repushes**: On every reconnect while observing, the handler MUST push the current snapshot; while stopped, the handler MUST do nothing.
- **stop**: Stopping MUST stop observing, release the observers and cancel a push still retrying; the reconnect handler MUST stay registered but inert until the next start.
- **snapshot-failure-not-sent**: When the snapshot builder returns nothing, the push MUST log an error naming the label and MUST NOT send anything or cancel an in-flight push.
- **newest-supersedes**: A push MUST cancel any push still retrying before starting its own, so a stale body never lands after a fresh one.
- **bounded-retry**: A push MUST attempt delivery once per configured backoff, waiting that many nanoseconds before each attempt; the default MUST be at once, then after 0.5 seconds, then after 1.5 seconds. It MUST stop at the first success, and after the last failed attempt MUST log an error that the receiver keeps its prior state.
- **superseded-stops-attempts**: A push that was cancelled MUST stop before its next attempt, without sending.
- **failure-logged-per-attempt**: Each failed attempt MUST log a warning naming the label and the attempt number out of the total.
- **sorted-key-encoding**: The engine MUST offer a helper that encodes a value as JSON with sorted keys, giving a byte-stable body, and returning nothing when encoding fails.
- **await-pending**: The engine MUST offer a way to await the most recent push, intended for tests.
- **main-context**: The push MUST be confined to the main UI context, so observation and snapshots read settings from the context that owns them.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

