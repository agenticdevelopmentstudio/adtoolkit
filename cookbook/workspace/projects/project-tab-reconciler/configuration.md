
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stored` (plan input) | list of tab records | none — required | The tabs the caller already persisted for this project. |
| `checkouts` (plan input) | list of checkouts | none — required | The checkouts a fresh worktree listing just reported. |
| `projectDirectory` (plan input) | directory reference | none — required | The project's own directory; a stored record with no working directory of its own is matched against this directory. |
| `existsOnDisk` (plan input) | directory-to-boolean function | the local filesystem's own existence check | Consulted once per stored record not already matched by a checkout, to tell "not reported" apart from "genuinely gone." |
| `volumeIsMounted` (plan input) | directory-to-boolean function, optional | the mount-lookup function described in **volume-is-mounted-contract** | Consulted once per record whose directory is gone, to decide whether dropping it is safe. |
| `directory` (mount-lookup input) | directory reference | none — required | The candidate directory whose mounted volume is in question. |
| `projectDirectory` (mount-lookup input) | directory reference | none — required | The project's directory, used as the volume of comparison. |
| `tabs` (layout-selection input) | list of tab records | none — required | The tabs to pick a representative layout from. |
| `activeTabID` (layout-selection input) | id, optional | none — required | The id of the tab whose layout should be preferred. |
| `checkout` (record-building input) | checkout | none — required | The checkout every returned record's `title` and `workingDirectory` are derived from. |
| `enabledEdges` (record-building input) | list of edges | none — required | One returned tab record per element, in the same order. |
| `blueprint` (record-building input) | layout factory | none — required | Called once per enabled edge so every returned record's `root` carries a distinct layout-node id. |

No function in this file reads an environment variable or a settings key;
every input arrives as an explicit parameter.

