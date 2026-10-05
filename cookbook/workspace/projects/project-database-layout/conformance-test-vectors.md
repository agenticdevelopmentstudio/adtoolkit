
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-client-projects-project-database-layout-001 | load-tabs-empty-default | Loading tabs on a repository id with no rows | no tabs, no active tab, the top edge alone |
| git-client-projects-project-database-layout-002 | save-tabs-whole-replace, load-tabs-order, load-tabs-tree-reconstruction | Writing two tabs, then loading tabs on the same repository id | tabs returned in the same order, each root tree structurally equal to what was saved |
| git-client-projects-project-database-layout-003 | save-tabs-active-tab-validated | Writing tabs with the active-tab id set to an identifier not present in the tab list | loading tabs returns no active tab |
| git-client-projects-project-database-layout-004 | load-tabs-group-id-fallback | Two tabs sharing one group id, saved and reloaded | both come back tagged with the same group id |
| git-client-projects-project-database-layout-005 | load-tabs-order | Writing tabs for repository A and, separately, for repository B | loading tabs for A is unaffected by B's arrangement |
| git-client-projects-project-database-layout-006 | pane-state-read, pane-state-write-upsert | Setting pane state with a thickness fraction, then reading pane state on the same triple | the same value round-trips, and an unset pane's thickness fraction stays absent rather than coercing to 0.0 |
| git-client-projects-project-database-layout-007 | pane-state-write-nil-deletes | Setting pane state to an absent value on a triple that previously had a value | a subsequent read for that triple returns nothing |
| git-client-projects-project-database-layout-008 | prune-nested-pane-state-scope | Closing a pane and pruning nested pane state with the surviving ids as the live-ids set | keys naming the closed pane's id are removed, keys with no identifier component are untouched |
| git-client-projects-project-database-layout-009 | project-directories-whole-replace, project-directories-empty-means-none | Saving project directories ["/a", "/b"] then loading them | ["/a", "/b"] in the same order; a second save with an empty list then reload → an empty list |
| git-client-projects-project-database-layout-010 | load-tabs-working-directory-is-directory-url | A working directory containing a space and a non-ASCII character, saved and reloaded | the exact same path string, constructed as a directory location |
| git-client-projects-project-database-layout-011 | save-tabs-atomic-rollback | A fresh database opened at the current schema version and a hand-built schema-version-3 fixture opened the same way | both migrate/open successfully and the working directory round-trips on the migrated database |

