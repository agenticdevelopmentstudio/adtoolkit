
- **Null and empty input**: An archive of zero-length bytes passed to
  verification MUST still be hashed successfully — digest computation is a
  total function over any byte sequence; nothing in verification
  special-cases emptiness (**digest-always-hashed**). An archive file that
  is a zero-byte file is not a valid archive, so the extraction utility
  MUST exit non-zero and expansion MUST fail with an expansion-failed error
  with the destination removed, the same path exercised for any non-zip
  input (**expand-nonzero-status-cleanup**).
- **Boundary values**: A decompressed tree whose measured size is exactly
  equal to the byte ceiling MUST NOT abort the run — only a running total
  strictly greater than the ceiling triggers the watchdog; a public key
  that decodes to exactly the Ed25519 SPKI length (44) bytes MUST be
  accepted, and any other length MUST be refused (**public-key-parsing**);
  a signature-archive entry of exactly the Ed25519 signature length (64)
  bytes MUST be accepted, and any other length MUST be refused
  (**signature-archive-extraction**).
- **concurrent-access**: Two concurrent expansion calls given the same destination are not serialized against each other: the existence check and the directory creation are two separate steps with no lock or exclusive-create primitive between them, so both callers can pass the existence guard and run two extraction processes into the same directory with no defined outcome for which files survive. The only caller today always supplies a fresh, uniquely-named destination per install, so expansion relies on that caller contract rather than enforcing it.

  Calls to verification, and calls to expansion with distinct destination
  values, remain independent
  (**concurrent-calls-independent-when-destinations-differ**).
- **Error states (dependency unavailable)**: When the platform's extraction
  utility cannot be launched at all — for example if it were removed or
  unexecutable — expansion MUST report this as an expansion-unavailable
  error with the destination removed (**expand-launch-failure-cleanup**).
  This is the only form "a dependency is unavailable" takes for this
  component, since it performs no network I/O of its own.
- **Offline / disconnected state**: Not applicable — this concept performs
  no network I/O; it operates entirely on archive bytes or a local archive
  file the caller already has in hand. Connectivity is a concern for
  whichever caller downloaded the archive before calling verification or
  expansion.
- **Malformed input (not a zip)**: An archive file that is not a valid
  archive MUST cause the extraction utility to exit non-zero, reported as
  an expansion-failed error with the destination removed. A signature
  archive that is not a valid archive MUST be caught during signature-bytes
  extraction and reported as a signature-archive-unreadable error, since
  expansion is invoked on it internally and any failure it produces is
  caught there.
- **Malformed input (hostile archive entries)**: A relative-traversal
  entry name, an absolute entry name, and a symlink written through are
  each handled as their own requirement rather than left unvalidated
  (**expand-path-traversal-containment**, **expand-symlink-escape-failure**);
  the containment is the platform extraction utility's own, not logic in
  this concept, which is stated explicitly rather than claiming credit for
  a hand-rolled check.
- **Cancellation**: Verification and expansion are synchronous operations
  with no cooperative cancellation check anywhere; the only way expansion
  itself gives up early is its own timeout or byte ceiling, enforced by the
  polling loop (**synchronous-blocking-execution**,
  **expand-byte-ceiling-watchdog**). A caller that wraps either call in a
  cancellable unit of work and cancels it MUST wait for the underlying
  blocking call to return on its own before the cancellation is observed,
  since neither operation checks for cancellation itself.
- **Timeout**: An expansion run that exceeds its timeout MUST be
  terminated, reported as an expansion-timed-out error, and MUST leave no
  directory at the destination (**expand-timeout-cleanup**). An archive
  that decompresses past the byte ceiling faster than it exceeds the
  timeout is stopped by the byte ceiling first and reported as
  expansion-too-large, not as a timeout (**expand-abort-cleanup**) — the
  two limits guard different axes and either can fire without the other.

