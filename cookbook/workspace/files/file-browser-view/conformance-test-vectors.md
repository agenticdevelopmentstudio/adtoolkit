
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| file-browser-001 | tree-divider-footer-layout | Load the component. | Tree, then a 1pt separator, then the footer, stacked top to bottom and each pinned leading/trailing to the container. |
| file-browser-002 | window-background-fill | Load the component, inspect the root container's background. | Background color equals the current theme's window-background role color. |
| file-browser-003 | footer-surface-fill | Load the component, inspect the footer's background. | Background color equals the current theme's surface role color. |
| file-browser-004 | one-manager-per-root | Construct with a primary root and two additional directories. | Exactly one manager backs each of the 3 roots (primary and both additional) — each root loads and can be watched independently (see file-browser-006 and file-browser-009), never sharing a manager with another root or going without one. |
| file-browser-005 | primary-root-always-managed | Look up the primary root's manager immediately after construction. | Returns a valid manager for the primary root, never absent and never a crash. |
| file-browser-006 | start-watching-on-appear | Trigger the component's appearance while it is not currently watching. | Every manager for a current root has watching started. |
| file-browser-007 | stop-watching-on-disappear | Trigger the component's disappearance while watching. | Every manager has watching stopped. |
| file-browser-008 | stop-watching-on-pane-teardown | Trigger pane teardown while watching, without a prior disappearance event. | Every manager has watching stopped. |
| file-browser-009 | load-initial-once | Trigger the component's appearance twice in a row. | The initial load runs on each manager exactly once (only on the first appearance). |
| file-browser-010 | add-directory-opens-panel | Invoke the add-directory action. | A system directory picker is shown configured to choose directories only (not files), allowing multiple selections. |
| file-browser-011 | add-directory-cancel-noop | Invoke the add-directory action, dismiss the picker without choosing. | The additional roots are unchanged before and after the call. |
| file-browser-012 | add-directory-skips-duplicates | Invoke the add-directory action, choose a directory already among the browsed roots. | The additional roots are unchanged; no error is presented. |
| file-browser-013 | add-directory-selects-last-added | Invoke the add-directory action, choose one new directory and confirm. | The selected root equals the chosen directory. |
| file-browser-014 | remove-directory-requires-selected-root | Clear the selected root, then invoke the remove-directory action. | Refusal feedback is triggered; the browsed roots are unchanged. |
| file-browser-015 | remove-directory-requires-removable-root | Set the selected root to the primary root, then invoke the remove-directory action. | Refusal feedback is triggered; the browsed roots are unchanged. |
| file-browser-016 | remove-directory-clears-selection | Set the selected root to a user-added root, then invoke the remove-directory action. | The root is removed from the additional roots; the selected root becomes none. |
| file-browser-017 | remove-button-enablement | Set the selected root to a user-added root, then to none. | The remove control is enabled, then disabled. |
| file-browser-018 | remove-button-tooltip | Set the selected root to a user-added directory named `Notes`. | The remove control's tooltip reads `Remove "Notes" from this project`. |
| file-browser-019 | footer-buttons-identified | Load the component, inspect the footer controls. | The add control's accessibility identifier is `file-browser.add-directory`; the remove control's is `file-browser.remove-directory`. |
| file-browser-020 | teardown-clears-orphaned-node-selection | Select a file under a user-added root, then remove that root from the browsed roots. | The selected node becomes none. |
| file-browser-021 | teardown-clears-orphaned-root-selection | Set the selected root to a user-added root, then remove that same root. | The selected root becomes none. |
| file-browser-022 | late-added-root-loads-if-visible | After the browser has completed its initial load, add a new directory. | The new root's manager has its initial load performed. |
| file-browser-023 | late-added-root-watches-if-visible | While the browser is actively watching, add a new directory. | The new root's manager has watching started. |
| file-browser-024 | git-status-provider-reuse | Inject a git status provider whose repository root (symlink-resolved) matches the primary root; construct the browser. | The primary root's manager is built with that provider. |
| file-browser-024b | git-status-provider-reuse | Inject a git status provider whose repository root does not match any root. | Every manager is built with no git status provider. |
| file-browser-025 | open-request-forwarding | Set the component's open-request callback to one that records its arguments, then have the hosted tree fire its own open-request callback (e.g. by triggering an open from the tree). | The recorded arguments match what the tree fired — the component's callback reads/writes the tree's callback directly, with no second copy (see **open-request-forwarding**). |
| file-browser-026 | reveal-forwarding | Invoke the component's reveal operation for a given location. | The hosted tree's own reveal operation is invoked for that location. |
| file-browser-027 | pane-selection-change-notification | Install the pane-selection-change callback, then change the selected node to a new value, then set it again to the same value. | The callback fires once, for the first change only. Because the notification is delivered asynchronously, the test must wait a turn (or await) after each change before asserting, rather than checking synchronously. |
| file-browser-028 | pane-selection-description | Select a node whose location is `/a/b/File.swift`. | The pane's selection description returns `"File.swift"`, not the full path. |
| file-browser-029 | reuse-managers-across-rebuild | Add a directory, capture the primary root's manager instance, then add a second directory. | The primary root's manager instance after the second add is the same instance as before (identity-equal). |
| file-browser-030 | single-root-convenience-init | Construct with the single-root convenience form. | The primary root equals the given location and the additional roots are empty. |
| file-browser-031 | add-directory-preserves-panel-order | Invoke the add-directory action, choose three new directories in a specific order (none yet among the browsed roots). | The additional roots gain all three, in the same order the picker returned them. |
| file-browser-032 | multi-pane-consistency | Construct two instances of the component sharing one directories/selection state; select a node under a user-added root in the first, then remove that root from the second. | The first component's selected node (and its selected root, if it equaled the removed root) become none, since both instances observe the same shared state. |
| file-browser-033 | reveal-forwarding | Invoke the component's reveal-nothing operation. | The hosted tree's own reveal-nothing operation is invoked. |
| file-browser-034 | remove-button-tooltip | Set the selected root to none. | The remove control's tooltip reads `Select an added directory to remove it`. |
| file-browser-035 | add-directory-selects-last-added | Invoke the add-directory action, choose three new directories in a single picker response and confirm. | The selected root equals only the last of the three chosen directories, not the first two. |
| file-browser-036 | git-status-provider-reuse | Inject a git status provider whose repository root (symlink-resolved) matches an *additional* root added via the add-directory action, not the primary root. | That additional root's manager is built with that provider, matched by resolving symlinks rather than a lexical comparison. |
| file-browser-037 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

