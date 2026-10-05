
- **file-signature-shape**: The file signature MUST be an immutable,
  comparable value with exactly two stored properties, `size` (an integer
  byte count) and `modified` (a date/time), constructible directly from
  those two values.
- **file-signature-stat-source**: Deriving a file signature MUST read
  `size` and `modified` from a fresh, path-based attribute lookup, never
  from a URL's cached resource-value lookup, because a URL caches resource
  values it has already been asked for and a second signature taken from
  the same URL value would repeat the first one's numbers regardless of
  what changed on disk.
- **file-signature-absence-is-nil**: Deriving a file signature MUST answer
  nothing (no signature), not throw, when nothing can be stat'd at the
  given location — no such file, no permission, or a path that does not
  resolve to a file — leaving the caller to decide what absence means.
- **file-signature-equality-limit**: File signature equality MUST compare
  only `size` and `modified`; a rewrite that lands on the same byte count
  and the same modification date is indistinguishable from no change at
  all, and this is documented as the type's known limit rather than
  treated as a defect.
- **error-type-shape**: The file-system error outcome MUST be an error type
  carrying a localized description, and MUST NOT be required to support
  equality comparison or safe cross-thread sharing, because at least one
  outcome (no-permissions) carries an underlying cause a caller may need to
  branch on directly rather than through its description text.
- **error-cases-name-a-path**: Every file-system error outcome MUST carry
  the path (and, for the rename-failed outcome, also the destination path)
  that the failing operation was called with, so a caught error names the
  location it applies to.
- **error-description-fixed-strings**: The file-system error outcome's
  description text MUST return one hardcoded English sentence per outcome,
  built by string interpolation, with no localization lookup of any kind.
- **concurrent-call-safety**: The file system service MUST be safe to call
  concurrently from any thread or concurrent task with no additional
  synchronization at the call site.
- **serial-queue-backing**: The file system service MUST run every one of
  its seven operations' blocking file-system work on one private, serial
  background queue, created once at construction and never replaced.
- **continuation-bridge**: The service's internal call-bridging step MUST
  bridge the queue's synchronous, throwing work back into the caller's
  asynchronous call, so the calling task suspends rather than blocking a
  cooperative-pool thread while the work runs on the queue.
- **calls-serialize-on-the-queue**: Two or more calls into the same file
  system service instance MUST be served in the order their work is
  enqueued onto that instance's single background queue, never interleaved
  with each other at a sub-call granularity.
- **fresh-file-manager-per-call**: Every operation MUST use its own
  underlying file-manager instance for its queued work rather than sharing
  one across calls, because the underlying file-manager type is not safe to
  share across the boundary between the calling context and the background
  queue.
- **independent-instances**: Constructing the file system service MUST take
  no parameters and own no state beyond its own queue, so multiple
  instances may coexist, each with its own independent serial queue and no
  ordering guarantee between them.
- **read-file-follows-links**: The read-file operation MUST follow a
  symbolic link at the given path to its target's bytes, as reading a file
  always does.
- **read-file-not-found**: The read-file operation MUST throw a not-found
  outcome when nothing resolves at the given path, including a dangling
  symbolic link.
- **read-file-is-a-directory**: The read-file operation MUST throw an
  is-a-directory outcome when the given path resolves to a directory.
- **read-file-exact-bytes**: The read-file operation MUST answer exactly
  the bytes on disk at the given path, with no transformation.
- **read-directory-entry-shape**: The read-directory operation MUST answer
  one entry per child of the given path, where each entry carries the
  child's own last path component as its name and a type bitmask; the
  listing MUST NOT be recursive.
- **read-directory-follows-link**: The read-directory operation MUST follow
  a symbolic link at the given path and list the directory it points to
  before enumerating children.
- **read-directory-not-a-directory**: The read-directory operation MUST
  throw a not-a-directory outcome when the given path does not resolve to a
  directory.
- **read-directory-unreadable-child-is-unknown**: The read-directory
  operation MUST report a child whose own type cannot be determined with an
  unknown-type flag rather than aborting or throwing for that one child,
  while a failure to read the given path itself still throws.
- **read-directory-link-child-union-bits**: A child that is a symbolic link
  MUST be reported with the union of the symbolic-link flag and its
  resolved target's type bit where the target's type can be determined —
  raw value 65 for a link to a file, 66 for a link to a directory, the
  symbolic-link flag alone when the target is gone — never the
  symbolic-link flag alone for a resolvable target.
- **stat-does-not-follow-terminal-link**: The stat operation MUST NOT
  follow a terminal symbolic link at the given path; it MUST report the
  link's own type, timestamps, and size, not its target's.
- **stat-link-target-bit-union**: The stat operation MUST set the
  symbolic-link flag together with the resolved target's own type bit where
  that can be determined cheaply — raw value 65 for a link to a file, 66
  for a link to a directory — and the symbolic-link flag alone when the
  target does not exist.
- **stat-optional-timestamps**: A stat result's creation date and
  modification date MUST each be absent when the underlying lookup does not
  report that attribute, never coerced to a placeholder date.
- **stat-size-fallback**: A stat result's size MUST fall back to `0` when
  the underlying lookup does not report a size attribute.
- **stat-missing-path**: The stat operation MUST throw a not-found outcome
  when nothing is at the given path.
- **write-file-create-flag**: The write-file operation MUST throw a
  not-found outcome, writing nothing, when nothing exists at the given path
  and the create flag is false; it MUST write and create the path when the
  create flag is true.
- **write-file-overwrite-flag**: The write-file operation MUST throw an
  already-exists outcome, leaving the existing bytes untouched, when
  something already exists at the given path and the overwrite flag is
  false; it MUST replace the bytes when the overwrite flag is true.
- **write-file-onto-directory**: The write-file operation MUST throw an
  is-a-directory outcome when the given path resolves to a directory,
  regardless of the flags.
- **write-file-existence-at-the-link**: The write-file operation's
  existence check MUST be judged at the link, not through it, so a dangling
  symbolic link at the given path counts as something already there for the
  overwrite check.
- **write-file-not-atomic**: The write-file operation MUST write its
  contents in place, never via a temporary file renamed over the
  destination, so an existing file's identity and permissions are preserved
  and a write through a symbolic link lands on the link's target rather
  than replacing the link itself.
- **create-directory-with-parents**: The create-directory operation MUST
  create the given path and every missing intermediate parent directory in
  one call.
- **create-directory-idempotent**: The create-directory operation MUST
  succeed with no error when the given path already resolves to a
  directory.
- **create-directory-exists-error**: The create-directory operation MUST
  throw an already-exists outcome when something that is not a directory
  already exists at the given path.
- **delete-link-not-target**: The delete operation MUST delete a symbolic
  link at the given path as the link itself, leaving its target untouched.
- **delete-not-found**: The delete operation MUST throw a not-found outcome
  when nothing is at the given path.
- **delete-nonrecursive-emptiness-check**: The delete operation, with the
  recursive flag false, MUST throw a directory-not-empty outcome and delete
  nothing when the given path is a directory with any entries in it; it
  MUST succeed when the directory has none.
- **delete-recursive-flag-scope**: The recursive flag's only effect MUST be
  the emptiness check above — the underlying removal itself recurses
  unconditionally regardless of the flag, so the recursive flag set true
  against a populated directory MUST remove it and its contents in one
  call.
- **delete-trash-flag**: The delete operation, with the Trash option set,
  MUST move the item to the user's Trash instead of permanently removing
  it; with the Trash option unset, it MUST permanently remove the item.
- **delete-trash-location-not-surfaced**: The delete operation MUST NOT
  report where a trashed item landed, because the Trash may rename an item
  to avoid a collision and no member of this component answers that
  renamed location.
- **rename-is-one-move**: The rename operation MUST treat rename and move
  as the same single operation, backed by one move call on the
  non-conflicting path.
- **rename-source-not-found**: The rename operation MUST throw a not-found
  outcome naming the source path, leaving the destination path untouched,
  when nothing is at the source path.
- **rename-destination-not-precchecked**: The rename operation MUST NOT
  pre-check whether the destination path is occupied before attempting the
  move; it MUST attempt the move first and act on the overwrite flag only
  after that move fails in a way classified as an already-exists outcome.
- **rename-case-only-and-self-renames-succeed**: A rename that only changes
  the case of a name on a case-insensitive volume, and a rename where the
  source and destination path are identical, MUST succeed regardless of the
  overwrite flag, because the underlying move succeeds outright and the
  overwrite flag is never consulted on that path.
- **rename-overwrite-refusal**: The rename operation, with the overwrite
  flag false, MUST throw an already-exists outcome naming the destination
  path and move nothing when the move fails because a distinct item already
  occupies the destination path.
- **rename-overwrite-guards**: The rename operation, with the overwrite
  flag true, before removing an occupied destination path, MUST reproduce
  the underlying move operation's own three refusals: an is-a-directory
  outcome for a non-directory source onto a directory destination, a
  not-a-directory outcome for the reverse, and a directory-not-empty
  outcome for a directory destination that has entries in it.
- **rename-overwrite-sequence**: The rename operation, with the overwrite
  flag true, onto a genuinely occupied destination, MUST proceed as move,
  remove, move again — attempt the move, remove the occupying item once the
  guards above clear it, then retry the move — never a single atomic
  replace, because no available operation atomically replaces a
  destination spanning files and directories alike.
- **rename-overwrite-failure-window**: If the removal step of the
  overwrite sequence succeeds but the retried move then fails, the
  destination path's former contents MUST be gone with nothing put back,
  the source path MUST still be in place, and the caller MUST receive a
  rename-failed outcome naming both paths — this window is a documented,
  accepted risk of the sequence, not a defect this component attempts to
  close.
- **rename-hard-link-and-inode-identity**: The rename operation MUST rely
  on the underlying move and remove operations to distinguish a hard link
  from a case-only alias, rather than comparing paths, folded case, or
  low-level file identity itself, because either of those comparisons is
  indistinguishable from a legitimate rename the caller is entitled to
  make.
- **servicing-interface-mirrors-service**: The substitution interface MUST
  declare exactly the seven operations the file system service exposes,
  with identical signatures, and MUST itself be safe to share across
  concurrent callers.
- **servicing-conformance-is-free**: The file system service MUST satisfy
  the substitution interface with no additional code, because every
  operation the interface requires is already implemented with a matching
  signature.
- **error-classification-posix-first**: Classifying a thrown error into a
  file-system error outcome MUST check the error's low-level
  operating-system error code before consulting its higher-level framework
  error code, because the two independently-observed routes to a move
  failure surface the low-level code first.
- **error-classification-chain-depth-bound**: Searching a thrown error's
  chain of nested underlying errors for a low-level operating-system error
  code MUST stop after 4 levels, as a guard against a cyclic chain rather
  than a claim about how deep that chain nests errors.
- **error-classification-fallback**: When classification recognizes
  nothing in a thrown error, every operation MUST fall back to its own
  operation-shaped error outcome carrying the original error.
- **permission-detection-best-effort**: Detecting a no-permissions outcome
  MUST be best-effort — it fires only when a higher-level framework error
  names a permission-specific code or a permission-denied/operation-not-
  permitted code is reachable in the error's chain; a permission failure
  surfaced any other way MUST arrive as the calling operation's own
  operation-shaped fallback outcome instead.
- **concurrent-instance-ordering**: No lock, isolation mechanism, or
  ordering rule spans two independently-constructed file system service
  instances, or an external process, operating against the same path
  concurrently; each instance's own serial queue orders only its own calls,
  so the write-file operation's existence check and write, the
  create-directory operation's existence check and create, and the delete
  operation's emptiness check and removal are each atomic only relative to
  that one instance's queue, never relative to a second instance or process
  racing the same path in between.

