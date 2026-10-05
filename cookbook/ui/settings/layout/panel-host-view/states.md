
| State | Appearance change |
|-------|------------------|
| Help hidden (default) | Help button, if shown, displays the outlined question-mark icon tinted with the secondary-text-color role, tooltip "Show Help". |
| Help visible | Help button displays the filled question-mark icon tinted with the accent-color role, tooltip "Hide Help". |
| No presenter / button disabled | Help button is hidden entirely — see **help-button-visibility**. |
| Pressed | Not applicable: the source defines no custom pressed-state styling for the help button; a momentary-type button supplies the platform's own built-in momentary highlight, which this source does not override. |
| Disabled | Not applicable: the source never sets an enabled/disabled state on the help button or on the component itself; there is no disabled-state path in this file. |
| Focused | Not applicable: the source configures no custom focus ring or focused-state appearance; the platform's default focus ring applies unmodified. |
| Loading | Not applicable: every operation in the source (content swap, help toggling, theme repaint) is synchronous; the source defines no loading flag, spinner, or placeholder state. |

