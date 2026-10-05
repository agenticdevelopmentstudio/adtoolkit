
- **Null and empty input**: A successful worktree read that reports zero
  non-bare worktrees MUST fall back to the single synthetic main checkout
  at the project's own directory (**checkouts-from-worktrees**; see vector
  -021). A project with no stored tabs at all MUST always take the
  "changed" persistence path, because having no stored tabs short-circuits
  the unchanged-plan guard regardless of what the plan itself says (MUST).
- **Boundary values**: The checkout list may hold exactly one entry (a
  repository with no linked worktrees) or many; the loops over checkouts
  being added and over held branch controllers run zero, one, or many
  times with no special case for either end (MUST). The enabled edges
  default to the single top edge (**default-enabled-edge**) when nothing
  was stored, so a project's very first reconcile always creates exactly
  one tab per checkout rather than one per available edge.
- **Concurrent access**: Opening and refreshing checkouts MUST be safe to
  call concurrently because the serialized reconcile operation chains each
  call onto whatever reconcile is already running, so two overlapping
  calls' git reads and database writes land in call order rather than
  completion order (**reconcile-calls-chain-in-order**; see vector -014).
  Every mutation of the checkout list, the branch-controller map, and the
  closed flag is confined to a single execution context (see Platform
  Notes), so no interleaving can observe a torn write. The one place
  serialization does not fully cover is **branch-refresh-close-race**: the
  per-branch-controller refresh loop inside the serialized reconcile
  operation does not re-check the closed flag between iterations.
- **Error states**: A worktree-read failure (whether from a missing
  executable, a launch failure, a timeout, or a failed command) is not
  distinguished by reading checkouts — every case is caught by one
  unqualified handler, logged once without the git output, and answered
  with the last known checkouts or the synthetic fallback
  (**worktree-read-failure-keeps-last-known**, MUST). A failure inside
  persisting tabs is logged there and not detected by this file; see
  **persist-failure-signal**.
- **Offline or disconnected state**: Not applicable in the network sense —
  reading worktrees runs `git worktree list --porcelain` against the local
  working tree only; it makes no request to a remote. An unreadable or
  removed project directory is handled identically to any other
  worktree-read failure above.
- **Cancellation and timeouts**: The serialized reconcile operation awaits
  its internal operation to completion rather than racing it against a
  timeout of its own; a timeout failure reaches reading checkouts through
  the same generic handling as every other error (see Error states above).
  Neither opening nor refreshing checkouts checks for cooperative
  cancellation on its own; the calling context's own cancellation is the
  only cancellation path that reaches this controller (MUST, by absence).
- **Missing file or unreachable server**: A checkout directory removed out
  from under the project (a worktree removal racing a pending reconcile)
  is not distinguished from any other git failure inside reading
  checkouts; synchronizing branch controllers drops that checkout's branch
  controller and unregisters its commands on the *next* successful
  reconcile, not immediately (**branch-controllers-dropped-with-their-commands**;
  see vectors -004, -007).

