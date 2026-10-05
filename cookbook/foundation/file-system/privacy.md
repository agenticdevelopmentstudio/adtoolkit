
- **Data collected**: This component collects nothing beyond the path
  strings and byte contents a caller already supplies as arguments; it
  reads no attribute beyond what each operation's own contract needs (type,
  timestamps, and size for stat; a directory listing's names and types for
  read-directory). The file signature reads only a file's size and
  modification date, never its contents.
- **Storage**: Every write, rename, and directory creation lands as
  ordinary, unencrypted files or directories at whatever path the caller
  names — this component applies no encryption, sandboxing, or
  access-control policy of its own, and relies entirely on the OS and the
  calling application's own sandbox entitlements for what paths are
  actually reachable.
- **Transmission**: Not applicable — nothing in this component makes a
  network call of any kind; every operation is local-disk-only.
- **Retention**: This component sets no retention or expiry policy of its
  own; a written or renamed item persists until a caller deletes it, and a
  delete call with the Trash option set moves an item to the user's Trash
  rather than erasing it immediately, extending its retention under the
  OS's own Trash lifecycle rather than this component's.
- **Path strings may be sensitive**: Every file-system error outcome
  interpolates the caller-supplied path verbatim into its description text
  (**error-description-fixed-strings**); on a typical desktop install that
  path routinely contains the user's account name (for example, under a
  per-user home directory), so a caller that logs or displays a caught
  error's description unfiltered is exposing that path segment wherever the
  error surfaces.

