
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| etvc-001 | contributed-view-retained | Construct the pane with a contributed view named "Files" and display name "Acme" | The placeholder shows "Files"/"Acme"; the pane title before any resolution is "Files" |
| etvc-002 | explicit-construction-only | Attempt construction through the generic archive/coder-based path | Fails fast (the process traps rather than returning a usable instance) |
| etvc-003 | initial-placeholder-shown | Load the pane's view before resolution has delivered a data source | Displayed content is the placeholder |
| etvc-004 | container-background-tracks-theme | Switch the active theme after the pane loads | The container's background color updates to the new theme's `.surface` color |
| etvc-005 | resolve-requested-after-view-loads | Instrument view construction and the view-ready lifecycle point | Resolution is requested only after the view has finished being constructed |
| etvc-006 | first-resolve-shows-outline | Deliver a data source through resolution | Displayed content becomes a tree bound to that data source |
| etvc-007 | resolve-after-discard-ignored, outer-teardown-marks-discarding | Begin teardown, then deliver a resolution | Displayed content is unchanged; no tree is created — the discard flag teardown sets is what suppresses it |
| etvc-008 | duplicate-resolve-ignored | Deliver two resolutions, back to back, with two different data sources | Only the first data source's tree is shown; the second delivery has no effect |
| etvc-009 | provider-replacement-swaps-source | With a tree shown for source A, signal that A has been replaced by B | Displayed content becomes a new tree bound to B; B's provider-replacement signal is wired afterward |
| etvc-010 | swap-tears-down-previous-content | Swap from a placeholder that supports teardown to a tree | Teardown is invoked on the placeholder before it is removed from view |
| etvc-011 | swap-pins-new-content-to-edges | Swap in a new child | The child's view has four active constraints pinning it to the container's leading/trailing/top/bottom |
| etvc-012 | swap-notifies-title-change | Swap in a new child while the title-change notification is set | The notification fires exactly once as part of the swap |
| etvc-013 | outer-pane-title-delegates | Read the pane title while the placeholder is shown, then again once the tree (title "Explorer") is shown | First read is the contributed view's name; second read is "Explorer" |
| etvc-015 | outer-teardown-forwards-to-content | Content is a tree that supports teardown; invoke teardown on the outer pane | The tree's own teardown runs |
| etvc-016 | outline-single-column-no-header | Load the tree's view | The tree has exactly one column; its header is hidden |
| etvc-017 | outline-row-height | Read the tree's row height | Equals 22 |
| etvc-018 | outline-indentation-per-level | Read the tree's indentation per level | Equals 14 |
| etvc-019 | outline-inset-style | Read the tree's visual style | Equals the inset style |
| etvc-020 | outline-allows-empty-selection | Read whether the tree allows an empty selection | `true` |
| etvc-021 | message-banner-shown-conditionally | Set the data source's message to "No results", then clear it | Banner visible and tree offset below it in the first case; banner hidden and tree flush to the top in the second |
| etvc-022 | message-banner-inset | Banner shown | Its leading/trailing constraints use a 16pt constant; its top constraint uses 8pt; the tree's top-offset constraint uses 8pt from the banner's bottom |
| etvc-023 | message-banner-wraps | Set the data source's message to a string longer than the pane's width | The label renders on multiple lines rather than truncating to one |
| etvc-024 | accessibility-ids-assigned | The contributed view's registry id is "acme.files" | The tree's accessibility identifier is "acme.files.tree"; the message label's is "acme.files.message" |
| etvc-025 | initial-load-when-view-is-ready | Load the tree's view with a data source whose message is "Loading…" | A root children ask is issued; the banner shows "Loading…" immediately |
| etvc-026 | callback-ownership-transfers-to-latest-pane | Build a second tree component for the same data source | The data source's tree-data-change/chrome-change callbacks now point at the second tree component's handlers |
| etvc-027 | visibility-forwarded-only-by-owner | Pane B has superseded pane A per etvc-026; report pane A as having become visible | The data source's visibility callback is NOT invoked by pane A |
| etvc-028 | message-label-wrap-width-tracks-container | Resize the container to 250pt wide | The message label's preferred wrap width becomes 218 (250 − 32) |
| etvc-029 | multiple-selection-mirrors-source | The data source allows multiple selection; apply chrome | The tree allows multiple selection |
| etvc-030 | children-answered-from-cache | Ask for the children of an item whose branch is already cached | Returns the cached rows synchronously; no new ask is issued |
| etvc-031 | uncached-branch-triggers-load-and-empty-answer | Ask for the children of a branch never asked before | Returns an empty list immediately; a load for that handle begins |
| etvc-032 | load-skipped-while-in-flight | Ask for the same branch's children twice before the first ask's provider call returns | Exactly one children request reaches the data source |
| etvc-033 | load-marked-stale-when-busy | While a load for handle H is in flight, trigger a tree-data change for H | Once the in-flight load completes and adopts, a second load for H is issued automatically |
| etvc-034 | load-skipped-for-unreachable-handle | Request a load for a handle whose row was already forgotten | No children request reaches the data source |
| etvc-035 | disclosure-driven-by-declared-state | Item has `collapsibleState == .collapsed` and its load answers zero children | The row still reports itself expandable |
| etvc-036 | load-bounded-by-budget | Set `childrenBudget` to a short, injected value; provider never answers | No rows are adopted for that branch (see etvc-038's later, successful ask); the ask does not wait indefinitely |
| etvc-037 | timeout-logged | Trigger a timeout as in etvc-036 | An error is logged: "A tree provider did not answer getChildren in time; the branch stays unread" |
| etvc-038 | timeout-leaves-branch-askable | After a timeout on handle H, request H's children again | A fresh load for H is issued and can succeed |
| etvc-039 | late-answer-discarded-when-defunct | Begin teardown while a load is in flight, then let the provider answer | The answer is not adopted; the tree is not reloaded |
| etvc-040 | successful-load-updates-table-and-redraws | Handle H moves from parent P1 (already drawn) to parent P2 in a refresh | Both P1 and P2's branches redraw; H's row object is the same instance as before |
| etvc-041 | duplicate-child-id-deduplicated | A `getChildren` answer for parent P lists id "x" twice | P's children contain exactly one row for "x" |
| etvc-042 | moved-row-preserves-identity | P2's answer (claiming H) arrives before P1's answer (which no longer lists H), within the same settling refresh | H keeps the same row object and its loaded subtree under P2 |
| etvc-043 | orphan-return-by-same-parent-is-new-row | Parent P drops id "x" in refresh 1, then names "x" again in a later, separate refresh 2 | "x" is a new row in refresh 2; any subtree it had before refresh 1 is gone, and its default expansion (if `.expanded`) is re-applied |
| etvc-044 | prune-orphans-after-settling | Parent P drops id "x" and nothing claims it; wait for all in-flight loads to finish | Row "x" and its descendants are forgotten from the table |
| etvc-045 | forget-is-cycle-safe | An extension declares item "a" as its own descendant (a cycle) and it is later forgotten | Forgetting completes without hanging or crashing |
| etvc-046 | redraw-preserves-selection | Row H is selected; a redraw of H's parent branch runs and H is still present afterward | H remains selected after the redraw |
| etvc-047 | redraw-narrowing-selection-notifies-source | Rows H1 and H2 are selected; a redraw drops H2 | The data source's selection-changed callback is called with only H1's item |
| etvc-048 | redraw-suppresses-source-notifications | Trigger a reload as part of a redraw | The data source's selection/expand/collapse callbacks are not called for the notifications the reload itself generates |
| etvc-049 | default-expansion-applied-once | Row H has `collapsibleState == .expanded`; it is drawn, the user collapses it, then a refresh redraws it again | H auto-expands the first time only; it stays collapsed after the user's action and the later refresh |
| etvc-050 | expansion-request-triggers-load | User expands a row whose children were never loaded | A load for that row's handle begins |
| etvc-051 | expand-collapse-reported-to-source | User expands a row (not via auto-expand or redraw sync) | The data source's expand callback is called with that row's item |
| etvc-052 | targeted-change-reloads-one-branch | Data source fires a tree-data change for "h1" where h1 is a loaded row | Only h1's branch reloads |
| etvc-053 | untargeted-change-reloads-loaded-branches | Data source fires an untargeted tree-data change with branches "" and "h1" already loaded | Both "" and "h1" are re-asked |
| etvc-054 | untargeted-change-reasks-root-when-empty | Data source fires an untargeted tree-data change before the root has ever loaded | The root ("") is asked |
| etvc-055 | change-after-teardown-ignored | Begin teardown, then fire an untargeted tree-data change | No load is triggered |
| etvc-056 | row-view-recycled | Draw one screenful of rows, then scroll through 500 rows | Each newly-scrolled-in row reuses a previously-created row view instance rather than constructing a fresh view hierarchy |
| etvc-057 | row-icon-from-symbol-name | Item with `symbolName == "folder"`, and item with `symbolName == nil` | First row shows a tinted `.secondaryText` icon; second row's icon is hidden |
| etvc-058 | row-label-shows-item-label | Item label longer than the column width | Label truncates with a tail ellipsis |
| etvc-059 | row-caption-from-description | Item with `description == "3 items"`, and item with `description == nil` | First row's caption shows "3 items"; second row's caption is hidden |
| etvc-060 | row-tooltip-fallback | Item with `tooltip == nil`, `label == "README.md"` | The row's tooltip is "README.md" |
| etvc-061 | row-background-recycled | Draw one screenful of rows, then scroll through 500 rows | Each newly-scrolled-in row reuses a previously-created background view instance rather than constructing a fresh one |
| etvc-062 | double-click-activates | Double-click a row | The data source's activation callback is called with that row's item |
| etvc-063 | return-key-activates-selection | A row is selected; press Return | The data source's activation callback is called with the selected row's item |
| etvc-064 | other-keys-pass-through | Press a key that is neither Return nor keypad Enter (e.g. Space) | The key event passes through unhandled; no activation occurs |
| etvc-065 | outline-pane-title-source-or-fallback | The data source's title is empty, then "Explorer" | First read of the pane title is the manifest's fallback name; second read is "Explorer" |
| etvc-066 | outline-teardown-idempotent | Invoke teardown twice | The second call has no additional effect (e.g. the visibility-false notification is not sent twice) |
| etvc-067 | outline-teardown-releases-callbacks-only-if-owner | Tree component B has superseded tree component A for the same data source (etvc-026); invoke teardown on A | The data source's callbacks (still pointing at B) are left untouched; the visibility callback is not called by A |
| etvc-068 | alternate-return-path-activates-selection | A row is selected; deliver Return through the alternate text-editing-command path directly | The data source's activation callback is called with the selected row's item |
| etvc-069 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

