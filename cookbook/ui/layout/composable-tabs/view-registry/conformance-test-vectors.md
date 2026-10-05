
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| CTVR-01 | placeholder-registration | A freshly constructed registry | Checking whether the `placeholder` view id is registered returns true |
| CTVR-02 | register-overwrite | Register a view id, then register it again with a different descriptor/factory | Resolving its descriptor reflects the second registration; the first factory is never invoked |
| CTVR-03 | placeholder-protection | Unregister the `placeholder` view id | Returns false; it remains registered; an error is logged |
| CTVR-04 | unregister-removal | Register a non-placeholder view id, then unregister it | Returns true; it is no longer registered afterward |
| CTVR-05 | unregister-absence | Unregister a view id that was never registered | Returns false |
| CTVR-06 | view-id-ordering | Register `"z.view"`, `"a.view"`, `"m.view"` | Listing registered view ids returns them in ascending order: a.view, m.view, placeholder, z.view — the placeholder id's underlying raw value is `"whippet.placeholder"`, which sorts between `"m.view"` and `"z.view"` |
| CTVR-07 | registration-presence | Query registration status for a registered and an unregistered id | Returns true and false respectively |
| CTVR-08 | descriptor-default | Resolve the descriptor for an unregistered view id | Returns the `unknown` descriptor (display name "Unknown") |
| CTVR-09 | factory-dispatch | Register a view id with a factory returning a distinguishable content object, then build content for it | The returned content is the one the factory produced |
| CTVR-10 | unregistered-fallback | Build content for an unregistered view id with pane number 3 | Returns a placeholder pane showing "Pane 3"; an error is logged |
| CTVR-11 | tree-id-default | Build content with no tree id given and a given node id | The factory's context tree id equals that node id |
| CTVR-12 | context-passthrough | Build content with distinct project, working-directory, pane-number, owner-node-id values | The factory's context carries each value unchanged |
| CTVR-13 | state-store-owner | Construct a state store on a context built with a non-empty owner node id | The returned state store's owner node id equals the context's owner node id |
| CTVR-14 | explicit-holding-priority | A descriptor with an explicit high holding-priority value and a preferred-thickness-fraction of 0.5 | Resolving holding priority returns the explicit high value |
| CTVR-15 | fractioned-priority-boost | A descriptor with no explicit holding-priority value and a preferred-thickness-fraction of 0.3 | Resolving holding priority returns a value 10 points above the platform's default-low resize-priority level |
| CTVR-16 | default-low-priority | A descriptor with neither an explicit holding-priority value nor a preferred-thickness-fraction | Resolving holding priority returns the platform's default-low resize-priority level |
| CTVR-17 | optional-teardown | A content type does not adopt the optional teardown capability | Attempting to use it as that capability yields nothing; nothing in this file requires or assumes it succeeds |
| CTVR-18 | optional-removal-confirmation | A content type adopts the optional removal-confirmation capability and returns nothing from its message, and separately a content type that does not adopt the capability at all | The message is empty in the adopting case; attempting to use the capability yields nothing in the non-adopting case — both mean "nothing would be lost" per this file's contract |
| CTVR-19 | placeholder-pane-number | Construct a placeholder pane with pane number 5 and load its view | The title label's displayed text is "Pane 5" |
| CTVR-20 | placeholder-series-tint | Load a placeholder for pane number 2 under a theme whose chart-series color list has at least 2 entries | The container's background equals series entry index 1 (0-indexed) at 15% opacity |
| CTVR-21 | empty-series-no-tint | Load a placeholder under a theme whose chart-series color list is empty | The container's background is unchanged from its default |
| CTVR-22 | placeholder-retint | Load a placeholder, then switch the active theme | The container's tint is recomputed against the new theme's chart-series color list |
| CTVR-23 | placeholder-title-centering | Load a placeholder's view and lay it out | The title's center point equals the container's center point |
| CTVR-25 | stale-tint-persistence | Load a placeholder under a theme with a non-empty chart-series color list, note the container's tint, then switch to a theme whose chart-series color list is empty | The container's background remains the tint set under the prior theme, unchanged |
| CTVR-26 | contrast | Placeholder pane under a theme whose chart-series color is close to its primary text color | The title is drawn in the primary-text color over the series tint; no contrast adjustment is applied. |
| CTVR-27 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

