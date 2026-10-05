
- **Null and empty input**: both the stored-record list and the checkout
  list being empty MUST cause building a plan to return a plan whose
  `keep`, `add`, and `drop` are all empty and whose `isUnchanged` is
  `true`, since neither the stored-record loop nor the `add` filter has
  anything to iterate. MUST. An empty enabled-edges list passed to
  building tab records for a checkout MUST cause it to return an empty
  list without invoking the layout-blueprint factory at all, since mapping
  over an empty list never calls its function. MUST.
- **Boundary values**: a stored record whose id equals the active-tab id
  MUST be preferred by layout selection over the first tab even when it is
  not the first element of the tab list; when no element matches, the
  boundary collapses to the first tab, and when the tab list itself is
  empty it collapses further to no result. MUST. A single stored
  tab-record group with more than one enabled edge — several records
  sharing one working directory — is evaluated independently per record by
  the plan-building loop, but since gone-ness and mounted-ness depend only
  on the shared directory, not on which record is being examined, every
  member of that group MUST reach the same keep-or-drop outcome; they can
  never be split between `keep` and `drop`. MUST.
- **Concurrent access**: building a plan, the mount-lookup function,
  selecting a layout, and building tab records hold all of their mutable
  state in local values, and this component itself declares no stored
  property of any kind, so independent concurrent calls with independent
  inputs cannot race against each other or against any state this file
  owns. MUST. The result they hand back is a different matter: neither
  the plan value nor the tab record is safe-to-share-across-concurrency-domains
  by declaration (see the concurrency note in Platform Notes), so a
  caller that shares one plan value, or the closures passed as the
  existence check or mount check, across concurrency domains without its
  own synchronization is not protected by this file's own guarantees.
  MUST.
- **Error states**: no operation in this file can throw. The volume
  lookup's only failure surface is swallowed internally, so a thrown error
  there always becomes a no-result rather than propagating; see
  **volume-lookup-failure-handling** for the case this swallowing makes
  ambiguous. MUST.
- **Offline or disconnected state**: not applicable — nothing in this file
  makes a network call; its only I/O is local filesystem existence and
  volume-identity lookups through the existence check and the default
  filesystem- and volume-backed implementations.
- **Missing file or unreachable directory**: a stored record's directory
  that no longer exists anywhere on a mounted volume causes it to be
  considered gone and its volume considered mounted, so the record
  proceeds into `drop` (verified by the vanished-directory test vector).
  MUST. The same missing directory on an unmounted or unreachable volume
  causes the volume to be considered not mounted, so the record is kept
  instead, deliberately trading a possibly stale tab for never silently
  deleting one the user can no longer get back (verified by the
  unmounted-volume test vector). MUST.
- **Cancellation and timeouts**: not applicable — building a plan, the
  mount-lookup function, selecting a layout, and building tab records are
  all synchronous computations with nothing to cancel and no operation
  that can run long enough to time out.
- **Duplicate checkout directories**: see
  **duplicate-checkout-directory-handling** above; the source neither
  rejects nor deduplicates two checkout entries that name the same
  directory.

