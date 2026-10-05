
| State | Appearance change |
|-------|------------------|
| Default | Tree, separator, and footer laid out; add control enabled; remove control's enabled state follows the selected root (see Disabled). |
| Pressed | Not applicable: the add/remove controls use the platform's standard control styling with no custom pressed-state styling defined here — the platform supplies its default press feedback. |
| Disabled | Remove control is disabled whenever the selected root is none or is not a removable (user-added) root; its tooltip reads "Select an added directory to remove it". |
| Focused | Not applicable: this component sets no custom focus-ring appearance on the tree, the controls, or the container; whatever focus indicator the platform draws by default for a standard control/hosted tree is unmodified here. |
| Loading | Before the component's first appearance, nothing has loaded and no manager has been asked to scan; after the first appearance, every current manager has had its initial load performed once. |
| Watching | While the component is on screen — started at first appearance, stopped at whichever of disappearance or pane teardown comes first — every current manager has watching active; once stopped, every manager has watching stopped. |

