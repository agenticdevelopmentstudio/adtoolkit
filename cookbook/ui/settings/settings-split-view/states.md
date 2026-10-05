
| State | Appearance change |
|-------|------------------|
| Default | Sidebar and detail items added; sidebar non-collapsible; window/detail background painted from the active theme; first panel auto-selected once panels exist. |
| Pressed | Not applicable — this component defines no control of its own; the search field is a stock text-search field, and the divider/rows it hosts belong to the outline component/panel list. |
| Disabled | Not applicable in this component — a disabled panel row is the panel list's concern (its descriptor's disabled flag); this component reads no disabled state. |
| Focused | While the sidebar search field holds focus, Down/Up move the sidebar selection instead of the text caret (**redirects-arrow-keys-to-selection**); every other command types normally. |
| Loading | Not applicable — every operation in this component is synchronous; there is no asynchronous load state. |
| Content-sized sidebar (content-sized-sidebar flag `true`) | Sidebar minimum thickness equals its maximum thickness, non-draggable, no persistence key set. |
| Draggable sidebar (content-sized-sidebar flag `false`, default) | Sidebar thickness ranges `160`–`360`pt, draggable, dragged width persisted under the sidebar persistence key. |
| Sidebar search shown (search enabled) | Search field installed as the sidebar's header accessory during the view's load step; typing narrows the sidebar and Down/Up steer the highlight. |
| Sidebar search hidden (search disabled, default) | Search field never built; no header accessory installed. |
| Nested split present (two or more hosted panels are themselves settings split views) | Every nested sibling's sidebar is pinned to one shared width; this instance's own detail floor is raised to accommodate the widest nested sibling's sidebar plus its own detail-minimum-thickness floor. |

