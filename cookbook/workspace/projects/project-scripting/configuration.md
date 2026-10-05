
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `uniqueID` (lookup argument, shared by the window, tab, and pane lookups) | string | none — required | The id a script is asking for; compared by plain string equality against each wrapper's `uniqueID`, with no identifier-format validation of the argument itself. |
| `edgeName` (argument to the scriptable pane's `minimizePane(to:)`) | string | none — required | Parsed against the recognized edge names; any string that is not a recognized edge name is treated as a restore request, not an error. |
| the shared project window registry (ambient) | singleton | the shared registry | The sole registry this surface reads (the set of open windows, and each window's project controller); no dependency is injected into any operation here. |
| branch-resolution function (internal to the tab enumeration) | directory-to-branch-name function | resolves a tab's working directory through its window's project controller's branch controller | Not caller-configurable — this exact resolution is what this surface supplies to the tab-building step on every call. |

This surface reads no environment variable and no settings key of its own;
the underlying window/tab/pane state it enumerates is populated elsewhere,
by opening a project and by adopting a window for scripting, neither of
which is a concern of this recipe.

