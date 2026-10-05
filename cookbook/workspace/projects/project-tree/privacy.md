
- **Data collected**: Every tree node's path is an absolute filesystem
  path, and on a typical home directory that path embeds the user's
  account name for every node under the home directory; the folder names
  shown to the caller are themselves path components taken from that same
  path.
- **Storage**: None performed by this file — the returned forest is a
  plain in-memory structure with no persistence code of its own; whatever
  holds a reference to it controls its lifetime.
- **Transmission**: None — this file makes no network call.
- **Retention**: Not defined here; a returned forest's lifetime is
  entirely up to its caller, and nothing in this file caches or reuses a
  previous call's result.

