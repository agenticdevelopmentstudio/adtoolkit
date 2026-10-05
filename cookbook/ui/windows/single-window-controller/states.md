
| State | Behavior | Source |
|---|---|---|
| Not yet built (window never accessed) | No window exists; the visibility flag returns false; the registry already has an entry for the window ID from construction | window building is lazy; the visibility flag; **registry-registration** |
| Built, hidden | Window exists, but not on screen | default post-build state before showing |
| Built, visible | Window on screen; frame/visibility persisted on further move/resize/close when opted in | showing the window; the delegate callbacks |
| Built, HUD-configured | Translucent, optionally floating, chrome applied once via the HUD-configuration operation | the HUD-configuration operation |
| Applying a content fit | Concurrent resize-driven refit suppressed | the fit-to-content operation, the resize callback, **reentrant-fit-guard** |
| Awaiting move-settle | A debounced refit is pending; refit deferred while mouse button held | **move-refit-debounce**, **refit-drag-deferral** |
| Pressed | Not applicable — this class manages a window shell, not a pressable control; press-state feedback belongs to whatever control the hosted content renders. | this class has no control-rendering code |
| Disabled | Not applicable — a window controller has no enabled/disabled state of its own; if the app wants to disable interaction it disables specific controls in the content. | same |
| Focused | Not applicable at this layer beyond ordinary platform key-window handling, which this class does not customize. | this class overrides no key-window/first-responder logic |
| Loading | Not applicable — window construction is synchronous; there is no asynchronous loading state to represent. | the build step |

