
- **Null and empty input**: A checkout constructed with no branch recorded
  (a detached-HEAD or newly discovered worktree) leaves the current branch
  unset until the first successful refresh; the display name falls back to
  the checkout directory's last path component for exactly that period
  (MUST, see **initial-branch-from-checkout**, **display-name-derivation**).
  Requesting a tab pane before any pane exists always takes the "create"
  path — there is no null/empty case to special-case, since the known
  panes start empty and the scan simply finds nothing (MUST, see
  **pane-created-once-per-tab-per-edge**).
- **Boundary values**: The commands always number exactly three, never
  zero or a variable count — there is no configuration that adds or
  removes a command (MUST, see **commands-computed-per-access**). The
  known panes may hold zero entries (a checkout with no open tab yet);
  reloading zero panes on refresh is not an error, it simply reloads
  nothing (MUST, see **refresh-always-reloads-panes**).
- **Concurrent access**: Every mutation of the current branch and the
  known panes is confined to a single execution context (see Platform
  Notes), so no interleaving can observe a torn write. Refresh itself has
  no coalescing, generation counter, or in-flight guard of any kind —
  unlike its sibling git status provider (see
  `adtoolkit://cookbook/workspace/files/git-status-provider`), which
  explicitly coalesces overlapping calls into at most one queued follow-up
  and discards a stale response with a generation check. Two overlapping
  refresh calls (for example, two rapid Refresh Status invocations) each
  independently read the current branch and each independently assign it
  and reload every pane on completion; whichever call's read returns last
  wins, with no rule preferring the call that was *started* last over one
  that merely finished last; see the pending decision on refresh-ordering.
- **refresh-ordering**: overlapping refresh calls on one branch management component carry no ordering or coalescing rule; whichever call's branch read returns last sets the current branch and reloads the panes, even if it was started first (see Design Decisions).
- **Error states**: A missing git executable, a failed process launch, a
  timed-out git call, and a failed git command are not distinguished from
  one another by refresh; every one produces the same outcome — the
  current branch unchanged, every pane still reloaded (MUST, see
  **refresh-preserves-branch-on-failure**, **refresh-always-reloads-panes**).
  The caller of the Refresh Status command has no way to learn that the
  branch read specifically failed, as distinct from succeeding with an
  unchanged value; the failure's only record is the git command log kept
  by the injected git client (a collaborator, not this component — see
  `adtoolkit://cookbook/workspace/files/git-status-provider`'s sibling
  git client entry).
- **Offline or disconnected state**: Not applicable in the network sense —
  reading the current branch runs a local git command against the local
  working tree only; it makes no request to a remote and has no notion of
  connectivity. An unreadable or removed local checkout directory is
  handled identically to any other failure above.
- **Cancellation and timeouts**: The asynchronous refresh started by the
  Refresh Status command is independent of the invocation; once started,
  nothing can cancel it. If the branch management component has already
  been released by the time that work runs, the refresh is a no-op; if it
  is still alive, the reference is promoted for the duration of that one
  call, keeping the component alive just long enough to finish it (MUST,
  see **refresh-status-command-effect**). A timed-out git call reaches
  refresh through the same generic failure path as every other error (see
  Error states above); this component applies no timeout of its own.
- **Missing file or unreachable server**: A checkout directory that has
  been deleted (for example by a worktree removal running concurrently
  with a pending refresh) surfaces only as whatever failure reading the
  current branch produces for a missing directory, handled identically to
  Error states above (MUST). Neither **reveal-in-finder-command-effect**
  nor **copy-path-command-effect** checks that the directory still exists
  before acting on it; a stale Reveal in Finder or Copy Path invocation is
  forwarded to the platform's file browser or clipboard unchanged (MUST,
  see **captured-directory-outlives-controller**) — it is the owning
  project management component's job, not this one's, to unregister a
  checkout's commands once its directory is gone.

