
| State | Appearance change |
|-------|------------------|
| Default | Before the show operation is called, the container is empty and the component has no background paint (empty-initial-state). After it, the view fully repaints as described in Overview/Behavioral Requirements; calling it again with a different (or the same) theme tears down and rebuilds every card from that theme. |
| Pressed | Not applicable: no interactive control, action-target wiring, or click-handling exists anywhere in the component; every element (boxes, pills, rows, badges, the caret) is a plain, non-interactive view. |
| Disabled | Not applicable: an enabled/disabled property is never referenced in source; the component has no notion of an enabled/disabled state. |
| Focused | Not applicable: the component overrides no focus-related property and contains no interactive control, so it never becomes focused or shows a focus ring. |
| Loading | Not applicable: the show operation and every sample-building helper it calls are synchronous, non-throwing property assignments and view constructions; there is no asynchronous operation and no loading indicator anywhere in source. |

