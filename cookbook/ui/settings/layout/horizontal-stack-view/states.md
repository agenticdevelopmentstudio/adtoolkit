
| State | Appearance change |
|-------|------------------|
| Default | Renders as an invisible layout container, arranging its arranged children horizontally with group-spacing between them (see **group-spacing**); there is no other state. |
| Pressed | Not applicable: the component sets no target/action, gesture recognizer, or tracking area on itself — it cannot receive or respond to a press. (An arranged child may itself be pressable; that is the child's own concern, not this wrapper's.) |
| Disabled | Not applicable: the source never reads or sets an enabled state or any dimmed appearance — the component has no enabled/disabled concept. |
| Focused | Not applicable: the component never accepts keyboard focus and participates in no focus/key-view loop — it cannot become focused or show a focus ring. |
| Loading | Not applicable: the component performs no asynchronous work and defines no loading indicator. |

