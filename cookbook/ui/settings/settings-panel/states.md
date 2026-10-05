
| State | Appearance change |
|-------|------------------|
| Default | — |
| Pressed | Not applicable: the component is a container, not a control; it registers no press handling and applies no pressed-state styling anywhere in source. |
| Disabled | Not applicable to this component's own view. The descriptor's disabled flag is read only by the sidebar row list (a different concept) to disable that row; this component never reads that flag itself and applies no disabled styling to its own view. |
| Focused | Not applicable: this component installs no key-view loop or focus-ring override of its own; whatever focus order exists belongs to the controls a subclass adds. |
| Loading | Not applicable: no asynchronous operation, spinner, or loading indicator appears anywhere in this component. |

