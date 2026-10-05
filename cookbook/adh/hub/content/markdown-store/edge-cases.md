
- The document-list read path and the single-document read path deliberately
  disagree on how an unreadable timestamp is handled — the list skips and logs the
  row, the single fetch throws — so a caller reading the same corrupt row through
  the two paths sees different behavior by design.
- Reading a document from a raw row reads the tombstone-timestamp column through a
  lenient conversion that becomes empty on an unparseable value, unlike the required
  `created_at`/`updated_at` columns, which throw; every code path that reaches this
  conversion already filters to rows the write-time dual-flag invariant keeps
  non-tombstoned, so the lenient path has no reachable corrupt input in this
  component as given.
- The merge-then-write update path's merge closure may call back into the store
  without deadlocking, because the underlying database is reentrant, but a nested
  write's changes are silently overwritten by the enclosing whole-row write that
  follows it — this is documented as a hazard for the caller to avoid, not a defect
  in the method.
- The remote-writer contract has no implementation among these six responsibilities;
  nothing implements it yet, since this component holds no adh credentials to send
  with.
- Calling the delete operation twice for the same id, or once after the row has
  already been purged by the truncate operation, succeeds both times rather than
  throwing on the second call.
- Purging `notes`, `docs`, or `papers` alone succeeds when each has no rows; purging
  `content.markdown` alone while any marker table still has rows is refused
  regardless of whether that table is empty of *unrelated* rows.

