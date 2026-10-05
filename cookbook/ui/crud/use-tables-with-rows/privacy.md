
- **Data handled**: Table keys, the filter and ecosystem scope (identifiers such as a workspace slug or ecosystem id), and the signed-in principal's id used as a cache key. Probe responses are inspected only for being an empty or non-empty array; row contents are not read or retained.
- **Storage**: The remembered answers are held in module memory only; nothing is written to disk or browser storage.
- **Transmission**: One authenticated list request per candidate table, through the shared authenticated client; no other destination.
- **Retention**: A remembered answer lasts until the page reloads or the signed-in principal changes.

