
| State | Appearance change |
|-------|------------------|
| Default | Title reads `"<label>: Any"`; no choice menu item is checked. |
| Choice selected | The corresponding menu item is checked (system checkmark glyph); the title updates per **formats-title-few-selected** / **formats-title-many-selected**. |
| Choice deselected / "Any" chosen | The corresponding menu item is unchecked; once no items remain checked, the title reverts to `"<label>: Any"`. |
| Pressed | Not styled by source: opening the pull-down and highlighting a hovered/pressed menu item is the platform's own native rendering for this control and its menu, not custom to this file. |
| Disabled | Not implemented in source; no enabled/disabled property is ever read or set on the component in its own source. A caller may set the inherited enabled property directly, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by source; any focus ring shown when the button is tabbed to is the platform's own native focus-ring appearance for this control. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

