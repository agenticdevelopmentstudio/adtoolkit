
| State | Appearance change |
|-------|------------------|
| Default (unselected, enabled item row) | Item font, primary text color label, accent-color-tinted icon; row background follows the window-background color. |
| Disabled item row | Item font, tertiary text color label, tertiary-text-color-tinted icon; identical selection/press behavior to an enabled row (see **disabled-item-selectability**). |
| Selected row | A 4pt-corner-radius rect, inset 2pt horizontally / 1pt vertically, filled with the theme's selection color, drawn behind the row. |
| Group header row | Header font, secondary text color, marked as a group row; not selectable; no disclosure control. |
| Pressed | Not applicable: this component defines no visual state distinct from Selected for a row's press - a click or an accessibility press both resolve directly to the same selection action, with no separate transient "pressed" appearance. |
| Focused | Not applicable beyond the platform's own default keyboard-focus-ring behavior on the list; source sets no custom focus-ring color, width, or override. |
| Loading | Not applicable: the flat and grouped setters apply their row model synchronously; source defines no async load and no loading/pending indicator. |

