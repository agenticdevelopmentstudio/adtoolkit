
| State | Appearance change |
|-------|------------------|
| Default | Renders the native preview control's live preview of the given file; if the file's type has no preview generator, the control itself draws its native "no preview available" state — this component contains no code for that fallback. |
| Pressed | Not applicable: the component wires no click or press handling of its own; any pointer interaction (zoom, scroll, page navigation) is the native preview control's own behavior. |
| Disabled | Not applicable: the component never reads or sets an enabled/dimmed-appearance property — it has no enabled/disabled concept. |
| Focused | Not applicable: the component never manages keyboard-focus status of its own; it cannot become focused through code in this file. |
| Loading | Not applicable in this component: autostart (see **enables-autostart**) tells the native preview control to begin generating a preview immediately, but any generation-in-progress indicator is the control's own native behavior, not code defined here. |

