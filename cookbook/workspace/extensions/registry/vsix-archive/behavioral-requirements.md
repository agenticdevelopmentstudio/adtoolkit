
- **payload-directory-name**: The archive's payload-directory name MUST
  equal `"extension"`.
- **payload-directory-path**: Resolving the payload directory within an
  expanded tree MUST return the expanded root with the payload-directory
  name appended as a path component.
- **sha256-hex-format**: Computing the SHA-256 digest of a byte sequence
  MUST return it as lowercase hexadecimal, MUST be deterministic for the
  same bytes, and MUST differ for different bytes.
- **digest-always-hashed**: Verification MUST compute the SHA-256 digest of
  the archive and return it as the verification result's digest value on
  every call, whether or not an expected digest is supplied.
- **digest-comparison-normalized**: When an expected digest is supplied,
  verification MUST trim it of leading and trailing whitespace and newline
  characters and lowercase it before comparing to the computed hash.
- **digest-mismatch**: Verification MUST fail with a digest-mismatch error,
  carrying the normalized expected digest and the computed digest, when the
  two do not match, and MUST NOT evaluate the signature in that case.
- **digest-match-result**: When the normalized expected digest equals the
  computed hash, verification's returned digest-status MUST be "matched."
- **digest-not-published-result**: When no expected digest is supplied,
  verification's returned digest-status MUST be "not published," distinct
  from "matched," even though the digest value is still filled in.
- **digest-checked-before-signature**: Verification MUST evaluate the
  digest before evaluating the signature, so a digest mismatch is reported
  as a digest-mismatch error even when a signature and key are also
  supplied and would otherwise verify.
- **signature-neither-published**: When neither a signature nor a public
  key is supplied, verification MUST succeed and return signature-status
  "not published" rather than failing.
- **signature-half-pair-refused**: When exactly one of the signature or the
  public key is supplied, verification MUST fail with a
  signature-incomplete error naming the missing half as `"publicKey"` or
  `"signature"` respectively, without attempting any cryptographic check.
- **signature-verified-with-real-key**: When both a signature and a public
  key are supplied, verification MUST extract the raw signature bytes from
  the signature archive and the Ed25519 public key from the PEM-encoded key
  text, and MUST check the signature against the archive's bytes, returning
  signature-status "registry attested" on success.
- **signature-invalid**: Verification MUST fail with a signature-invalid
  error when the extracted signature does not validate against the archive
  under the extracted key — whether because the bytes being verified were
  substituted or the signature bytes were corrupted.
- **signature-manifest-and-p7s-ignored**: Verification MUST verify the
  signature against the archive's bytes directly, using only the signature
  archive's `.signature.sig` entry; it MUST NOT read or verify a
  `.signature.manifest` or `.signature.p7s` entry, the other two entries the
  signature archive may carry.
- **signature-archive-extraction**: Extracting the signature bytes from the
  signature archive MUST write the signature archive's bytes to a scratch
  location, expand it, and read exactly the Ed25519 signature length (64)
  bytes from its `.signature.sig` entry, failing with a
  signature-archive-unreadable error carrying a diagnostic string when that
  entry is absent or is not exactly 64 bytes, or when writing or expanding
  the scratch archive itself fails.
- **signature-scratch-cleanup**: Extracting the signature bytes MUST remove
  its scratch location on every exit path, whether extraction succeeded or
  failed.
- **public-key-parsing**: Parsing the public key from PEM text MUST strip
  header/footer lines (lines starting `-----`) and newline characters,
  base64-decode the remainder, and require exactly the Ed25519 SPKI length
  (44) decoded bytes, taking the last Ed25519 key length (32) bytes as the
  raw key; anything that fails base64 decoding or is not exactly 44 bytes,
  or whose final 32 bytes are refused as an Ed25519 key, MUST fail with a
  public-key-unreadable error.
- **expand-destination-must-not-exist**: Expansion MUST fail with a
  destination-exists error, naming the destination, without creating any
  directory or launching any process, when the destination already exists.
- **expand-destination-created**: When the destination does not already
  exist, expansion MUST create it, with intermediate directories, before
  extraction begins.
- **expand-uses-ditto**: Expansion MUST delegate the actual unpacking to
  the platform's own archive-extraction utility, given the archive path and
  the destination path, rather than an implemented zip reader.
- **expand-default-parameters**: Expansion's timeout, byte-ceiling, and
  check-interval parameters MUST default to 120 seconds, 2,147,483,648
  bytes, and 0.5 seconds respectively.
- **expand-byte-ceiling-watchdog**: Expansion MUST poll the destination's
  measured expanded size every check-interval and abort the run as soon as
  that measurement exceeds the byte ceiling.
- **expand-timeout-cleanup**: When the run times out, expansion MUST
  attempt to remove the destination and MUST fail with an
  expansion-timed-out error naming the configured timeout.
- **expand-abort-cleanup**: When the run is aborted for exceeding the byte
  ceiling, expansion MUST attempt to remove the destination and MUST fail
  with an expansion-too-large error naming the configured byte ceiling.
- **expand-nonzero-status-cleanup**: When the run neither times out nor is
  aborted but exits with a non-zero status, expansion MUST attempt to
  remove the destination and MUST fail with an expansion-failed error
  carrying that status and the extraction process's trimmed diagnostic
  output.
- **expand-launch-failure-cleanup**: When the extraction process itself
  cannot be launched, expansion MUST attempt to remove the destination and
  MUST fail with an expansion-unavailable error describing the failure.
- **expand-cleanup-is-best-effort**: Every removal of the destination on a
  failure path MUST be attempted without propagating a secondary error, so
  a failure to delete the partially written tree is discarded silently and
  never masks or replaces the original failure.
- **expand-success-preserves-destination**: When the run exits with a zero
  status and neither times out nor is aborted, expansion MUST leave the
  fully expanded tree in place at the destination and MUST NOT remove it.
- **expand-path-traversal-containment**: Expansion MUST NOT allow an
  archive entry named with a relative traversal (for example
  `../escaped.txt`) or an absolute path (for example `/tmp/x`) to write
  outside the destination; both forms MUST land inside the destination,
  flattened or re-rooted, because the platform's own extraction utility
  provides this containment and expansion neither disables nor duplicates
  it.
- **expand-symlink-escape-failure**: When an archive entry is a symbolic
  link pointing outside the destination, followed by an entry written
  through that link, expansion MUST fail the whole run with a non-zero
  exit status — reported as an expansion-failed error — rather than
  complete with the write silently redirected outside the destination.
- **expanded-size-measurement**: Measuring the expanded size of a directory
  tree MUST sum each item's allocated size (falling back to logical size
  when allocated size is unavailable), walking a directory bundle as
  ordinary files rather than skipping it as an opaque package, and MUST
  return as soon as the running total exceeds the supplied ceiling without
  continuing to walk the rest of the tree.
- **byte-ceiling-exceeds-artifact-cap**: The expansion byte ceiling MUST be
  greater than the registry client's maximum download size, so the
  decompressed-size ceiling this concept enforces is never tighter than the
  compressed-size ceiling the archive was already downloaded under.
- **stateless-namespace**: This concept MUST be a stateless collection of
  operations with no instance, holding only fixed constants and functions
  and no stored instance state of any kind — it can never be instantiated,
  so it carries no per-call or shared mutable state and requires no
  explicit concurrency-safety declaration to be safe to call from any
  concurrent context.
- **synchronous-blocking-execution**: Verification and expansion MUST both
  run synchronously to completion with no suspension point; verification
  performs its digest and signature work, and expansion waits for the
  extraction process to finish for up to the configured timeout plus grace
  periods, entirely on the calling thread.
- **concurrent-calls-independent-when-destinations-differ**: Concurrent
  calls to verification, or to expansion with distinct destination values,
  MUST run independently with no shared state between them: verification
  reads only its arguments, and each expansion or signature-extraction call
  creates its own process and, for signature extraction, its own
  uniquely-named scratch location.
- **logging-conformance-declared-unused**: This concept MUST participate
  in the host's logging convention, declaring a logger scoped to its own
  category, but no operation in it actually calls that logger — every
  failure surfaces to the caller as a distinct error case instead of a log
  line.
- **error-cases-carry-diagnostic-data**: Every archive-expansion error case
  except destination-exists MUST carry data identifying why the run was
  stopped — a message, a byte count, or a duration — rather than a bare
  case with no payload, so a report against a failed install names what
  happened.

