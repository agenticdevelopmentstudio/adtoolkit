
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | partial | Reliability |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |

Notes: separation-of-concerns passes because `BranchController` owns exactly
one checkout's status provider, branch, panes, and commands, delegates all
git work to the injected `GitClient`, delegates status broadcast entirely to
the injected `GitStatusProvider`, and — per its own doc comment — "never
touches the window"; command registration and unregistration with
`CommandRegistry` is `ProjectController`'s responsibility, not this file's.
unit-test-coverage is partial because `BranchControllerTests.swift` exercises
pane reuse and edge/tabID distinctness, a successful branch refresh reloading
panes, checkout-namespaced and cross-checkout-distinct command ids and
categories, and context-menu construction with target retention, but has no
test for `refresh()`'s failure path (see
**refresh-preserves-branch-on-failure**), for overlapping `refresh()` calls
(the pending decision on refresh-ordering), or for the
weak-pane-table eviction (**weak-pane-table**). explicit-error-handling is
partial because `refresh()`'s `catch` block does nothing beyond a comment
explaining why (the failure is recorded in `GitCommandLog` by `GitClient`,
not by this file) — the error is not silently lost system-wide, but this
file's own handling of it is a deliberate no-op rather than an explicit
mapping onto a result the caller can inspect. graceful-degradation passes
because a failed branch read leaves the last-known branch and still reloads
every pane, rather than crashing or blanking the display.
error-recovery is partial because `BranchController` performs no retry or
backoff of its own after a failed `refresh()` — recovery depends entirely on
some caller invoking `refresh()` again (a worktree rescan, another Refresh
Status command). main-thread-freedom passes because every git subprocess
call reaches this controller through `await gitClient.currentBranch(in:)`,
an async suspension point that does not block the main actor while the
subprocess runs.

