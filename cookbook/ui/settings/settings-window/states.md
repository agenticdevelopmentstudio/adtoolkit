
| State | Appearance change |
|-------|------------------|
| Default | Window not yet loaded: no header bar, navigation control, panel-title item, or help control exist until the window is first shown. |
| Pressed | Not applicable at this layer — per-press visual feedback belongs to the underlying control widgets, not to this window. |
| Disabled | The navigation control's back segment is disabled when moving back is not possible; its forward segment is disabled when moving forward is not possible, each independently. |
| Focused | Not applicable — this file assigns no focus-management or focus-restoration behavior of its own; a panel's own focus handling belongs to that panel, a separate ingredient. |
| Loading | Not applicable — panel and header-bar installation are synchronous; no loading/spinner state exists in this file. |
| Help panel open | Help control shows the filled question-mark icon, accent tint, and tooltip "Hide Help". |
| Help panel closed | Help control shows the outline question-mark icon, secondary-text tint, and tooltip "Show Help". |
| Activation disabled | Showing the window performs only the base show behavior; this override itself neither activates the app nor makes the window key — whatever key/visible state results comes entirely from the inherited base behavior. |
| Quiet presentation enabled | Showing the window makes it key without activating the app or ordering it above other applications' windows. |

