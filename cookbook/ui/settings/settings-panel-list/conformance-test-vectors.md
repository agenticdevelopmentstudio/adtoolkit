
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cts-panel-list-001 | panel-storage | Set the panel list to `[panelA, panelB]` | The sidebar shows exactly two rows, for `panelA` and `panelB`, in that order |
| cts-panel-list-002 | panel-set-rebuild | Set the panel list to `[panelA]`, then to `[panelA, panelB]` | The sidebar shows two rows after the second call, without a separate rebuild call being needed |
| cts-panel-list-003 | unchanged-query-guard | Construct a test subclass overriding the section-rebuild step to increment a counter; set the panel list to `[panelA, panelB]`; set the search query to `"x"`; record the counter; set the search query to `"x"` again (identical) | The counter after the second assignment equals the counter recorded after the first — the rebuild step was not called again |
| cts-panel-list-004 | query-change-rebuild | Same counter subclass as cts-panel-list-003; set the panel list to `[panelA, panelB]`; set the search query to `"a"`; record the counter; set the search query to `"b"` | The counter after the second assignment is one greater than after the first — the rebuild step was called again |
| cts-panel-list-005 | empty-query-inclusion | Set the panel list to `[panelA, panelB]`, then set the search query to `"   "` | Both rows remain visible |
| cts-panel-list-006 | all-terms-match | Set the panel list to `[panelA]` where `panelA`'s title is `"General"` and its section is `"App"`, then set the search query to `"app general"` | `panelA`'s row is visible; setting the search query to `"app missing"` then hides it |
| cts-panel-list-007 | panel-order-preservation | Set the panel list to `[panelB, panelA]`, search query `""` | Rows appear in the order `panelB`, `panelA` |
| cts-panel-list-008 | contiguous-section-grouping | Set the panel list to `[p1(section: "A"), p2(section: "B"), p3(section: "A")]` | Three sections render, in order A, B, A — not two sections of A merged |
| cts-panel-list-009 | descriptor-row-mapping | Set the panel list to `[panelA]` where `panelA`'s descriptor has a specific title, icon, and disabled flag set to true | The row shows that title and icon and renders in the disabled appearance |
| cts-panel-list-010 | original-index-row-id | Construct the component normally; set the panel list to `[panelA, panelB]`, search query set to a term matching only `panelB` (hides `panelA`); select the surviving row directly (not via the index-based selection method) | The visible-index query returns `[1]`, and the selection callback is invoked with `panelB` — proving the surviving row's id still resolves to index `1`, not re-indexed to `0` |
| cts-panel-list-011 | selection-callback-bridge | Construct the component normally, set the panel list to `[panelA]`, click `panelA`'s row | The selection callback is invoked once with `panelA` |
| cts-panel-list-012 | callback-free-selection | Set the selection callback to a spy closure, select the panel at index 0 by index | The row at index 0 becomes selected; the spy closure is not called |
| cts-panel-list-013 | out-of-range-select-guard | Set the panel list to `[panelA]`, select the panel at index 5 by index | No row's selection changes; no crash |
| cts-panel-list-014 | panel-visibility-report | Set the panel list to `[panelA, panelB]`, search query set to a term matching only `panelB` | Visibility for index 0 is false, for index 1 is true |
| cts-panel-list-015 | visible-index-report | Set the panel list to `[p0, p1, p2]`, search query set to a term matching only `p0` and `p2` | The visible-index query returns `[0, 2]` |
| cts-panel-list-016 | row-id-panel-resolution | Select a row whose underlying id is `"1"` for a panel list of `[panelA, panelB]` | The selection callback receives `panelB`; simulating a stale/malformed id (e.g. `"not-a-number"` or `"9"`) resolves to no panel |
| cts-panel-list-017 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

