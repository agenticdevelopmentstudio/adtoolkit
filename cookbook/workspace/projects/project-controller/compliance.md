
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | partial | Reliability |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |

Notes: separation-of-concerns passes because `ProjectController` owns exactly
the checkout list, the branch-controller lifecycle, and the tab-reconciliation
call sequence, while delegating every git read to `GitClient` through
`workspace.gitClient`, all tab-plan arithmetic to `ProjectTabReconciler`, all
persistence to `ProjectWorkspace`, and all rendering to `BranchController`'s
panes — per its own doc comment, it "knows nothing about views beyond vending
what a branch controller makes." unit-test-coverage is partial because
`ProjectControllerTests.swift` exercises the open/refresh serialization
ordering under a deliberately racing fake git executable, an unchanged
refresh's no-op path, a removed worktree dropping its tab and commands, tab
vending for both hosted and stray records, single- and multi-window command
registration and teardown, symlink-resolving lookup, and a transient git
failure preserving the last known checkouts — but has no test for a close
landing mid-`readCheckouts()` (**branch-refresh-close-race**
is one instance of this gap), for `shutdown()`'s own effect, for the
onTabItemsNeedRefresh-only path (checkouts changing without the tab plan
changing), or for the arrangement-copying branch of
**new-checkout-tabs-copy-arrangement-or-blueprint** (vectors -016, -018,
-019, and -020 above are synthesized to describe what such tests would
assert). explicit-error-handling is partial because `readCheckouts()`'s
`catch` does log the failure (unlike some sibling collaborators' silent
catches) but still answers with stale data without any signal a caller can
distinguish from a successful read that happened to see no change, and
because `reconcile()` cannot detect a swallowed `persistTabs` failure at all
(**persist-failure-signal**). graceful-degradation passes
because a failed git read keeps the last known checkouts and branch
controllers rather than collapsing the window to a single fallback tab.
error-recovery is partial because `ProjectController` performs no retry or
backoff of its own after a failed git read — recovery depends entirely on
some caller invoking `refreshCheckouts()` again. main-thread-freedom passes
because every git call and every branch-controller refresh reaches this
controller through `await`, an async suspension point that releases the main
actor while the subprocess runs.

