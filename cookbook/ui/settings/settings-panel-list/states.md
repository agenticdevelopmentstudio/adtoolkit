
| State | Appearance change |
|-------|------------------|
| Default | Row shows the panel's title/icon with the primary-text/accent color roles, unselected. |
| Selected | Row highlight comes entirely from the ancestor's native selection rendering; this component restyles nothing further on selection. |
| Disabled (panel) | The descriptor's disabled flag set: text and icon tint switch to the tertiary-text color role (inherited from the ancestor); the row remains selectable — selection is not gated on the disabled flag, so this component (and its ancestor) let a disabled row be clicked and selected like any other. |
| Filtered out | A panel the search query excludes contributes no row at all — it is absent from the sidebar entirely, not shown greyed out or struck through. |
| Pressed | Not applicable: a list row has no separate pressed/hover visual distinct from selection; this component adds no press styling of its own. |
| Focused | Not customized: standard list keyboard-focus ring, unchanged by this component or its ancestor. |
| Loading | Not applicable: setting the panel list and every rebuild it triggers are synchronous; no asynchronous load or spinner exists anywhere in this component. |

