
| State | Appearance change |
|-------|------------------|
| Default | Newly initialized: the descriptor is the given value or a default (empty title); the sidebar title equals the descriptor's title; the detail-pane minimum-thickness floor is `200`; the content-sized-sidebar flag is true. |
| Inner panel selected, that panel offers help | Effective help content returns the selected inner panel's own effective help content (**falls-back-help-content-through-inner-selection**). |
| No inner selection, or the selected inner panel offers no help | Effective help content falls back to this panel's own help content (none unless a subclass overrides it). |
| Pressed | Not applicable — this component defines no pressable control of its own; it is a container, not a control. |
| Disabled | Not applicable in this component — the descriptor's disabled flag exists on the shared descriptor type but is never read anywhere in this component; whatever a disabled row does with it is the sidebar-row renderer's responsibility, outside this component. |
| Focused | Not applicable — this component adds no focus/first-responder handling of its own; the inherited settings split view's key-view loop and search field are unmodified by this component. |
| Loading | Not applicable — every member of this component is a synchronous initializer or computed property; there is no asynchronous operation. |

