
- **Data collected**: Other apps' names, PIDs, window ids, titles (which often name documents, pages or paths), frames, displays and on-screen state.
- **Storage**: In memory only; the observer keeps window ids per PID, and nothing is written to disk.
- **Transmission**: None; data goes to the caller and the delegate. Log lines go to the system log.
- **Retention**: For the life of the returned values and, for the observer snapshot, until the next refresh or observation stops.

