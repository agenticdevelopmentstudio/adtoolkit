
- **Data collected**: This file introduces no new data collection beyond the file path the user is already viewing in this window. No personal or sensitive data is read or written by this file itself.
- **Storage**: Local only, through the caller-supplied pane-state store, under the file-URL key. The concrete store's durability is opaque to this file: an ephemeral store (used in tests, and for a container with nothing to persist) forgets its values as soon as it is deallocated, while a project window's own store persists `pane_state` beyond app restarts. This file specifies only that it writes/reads that one key; the durability guarantee is the store's, not this file's.
- **Transmission**: None. No network call appears anywhere in this file.
- **Retention**: Tied to the given store's own retention policy; this file's only retention-relevant action is writing none for the file-URL key when the document is cleared or the stored file no longer exists (see **clear-document-preserves-pane**, **missing-file-restore**).

