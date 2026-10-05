
- **Null and empty input**: A `repoRoot` that does not exist, or is not
  inside a git repository, is not special-cased by this component; it is
  forwarded unchanged to the underlying status check, whose resulting error
  is caught by the generic branch and reported as the unavailable case
  (MUST, see `failure-yields-unavailable-never-empty`; confirmed by the
  provider's own test suite). Triggering a refresh while zero observers are
  registered still runs the underlying status check to completion — the
  delivery loop over the registered-observer collection simply iterates
  zero times — so the run's cost is paid with no observer ever told (MUST,
  matching `broadcast-to-all-observers`).
- **Boundary values**: `isQueued` is a single boolean, not a counter, so
  however many refresh calls arrive while a run is in flight, at most one
  follow-up run is owed; the boundary is exactly zero vs. one queued
  follow-up, never two or more (MUST, see `bounded-burst-cost`).
- **Concurrent access**: Registering an observer and triggering a refresh
  may be called concurrently from any thread; every read and write of
  `observers`, `isRunning`, and `isQueued` is serialized by the provider's
  guarding lock, so no interleaving can observe a torn state (MUST, see
  `thread-safe-mutable-state`). The order in which multiple observers
  registered on one provider are called for a given result is the
  iteration order over the registered-observer collection, which is not
  guaranteed to be insertion order or stable across calls (SHOULD NOT be
  relied upon by a consumer; the source makes no ordering promise across
  observers, only that every one of them is called).
- **Error states**: The distinct failure reasons the underlying git client
  can raise (executable not found, launch failed, timed out, command
  failed) are not distinguished from one another by this component; every
  one reaches the generic failure branch, is logged from a sanitized
  description of the error, and is reported as the unavailable case
  identically (MUST, see `failure-yields-unavailable-never-empty`,
  `error-log-omits-git-output`).
- **Offline or disconnected state**: Not applicable in the network sense —
  this component makes no network call; its only external dependency is
  the local status-check subprocess call, whose failure (including an
  unreachable or misconfigured git executable) is handled identically to
  the Error states above.
- **Cancellation and timeouts**: The refresh operation runs detached from
  its caller, so nothing external can cancel an in-flight refresh; the only
  cancellation path the refresh operation observes is a cancellation signal
  raised from within the underlying status check itself, which is reported
  as the unavailable case without an error log (MUST, see
  `cancellation-yields-unavailable`). A timeout — raised when git does not
  finish within the client's configured duration — is a distinct,
  non-cancellation case that falls to the generic failure branch instead,
  and is logged at error level like any other failure (MUST, see
  `failure-yields-unavailable-never-empty`).
- **Missing file or unreachable server**: A `repoRoot` that no longer exists
  on disk, or that points to a directory that is not a git repository,
  surfaces only as whatever error the underlying status check produces for
  that case; this component performs no existence or repository check of
  its own before calling it (MUST, handled identically to Error states
  above).

