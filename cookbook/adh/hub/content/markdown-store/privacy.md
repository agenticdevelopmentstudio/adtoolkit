
- **Data collected**: Every row is scoped by a required customer id and ecosystem
  id, plus the document's own content and frontmatter text, which is arbitrary
  user-authored Markdown, not just metadata.
- **Storage**: Local only, in one database file under a per-token home directory;
  nothing in this component encrypts the file at rest.
- **Transmission**: None from within this component today — the remote-writer
  contract has no concrete implementation here, per its own documentation stating
  nothing implements it yet because this component holds no adh credentials;
  outbound activity is limited to maintaining the local outbox queue, never a
  network call this component makes itself.
- **Retention**: A deleted document is retained as a tombstoned row, not physically
  removed; only the truncate operation and the identity-state purge physically
  delete rows, and the latter is scoped to identity-tracking tables, never document
  content.

