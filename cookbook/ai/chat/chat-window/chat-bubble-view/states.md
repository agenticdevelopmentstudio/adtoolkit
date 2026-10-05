
| State | Appearance change |
|-------|------------------|
| Default | Themed fill/text/border per role and style — see **role-based-fill-and-text**, **terminal-style-role-fill-override** |
| Assistant work output | Text color forced to `secondaryText` — see **work-output-text-dimmed** |
| Truncated (collapsed, over limit) | Text cut to `lineLimit` lines ending in "…"; expand toggle shown with the "Show the whole message" chevron — see **line-limit-truncation**, **expand-toggle-icon-and-label** |
| Expanded (over limit, `isExpanded == true`) | Full text shown; expand toggle shown with the "Show less" chevron — see **truncation-suppressed-when-not-needed** |
| Not expandable (`lineLimit` is not set, or the laid-out line count does not exceed it — see **expand-toggle-visibility**) | Expand toggle hidden entirely; full text shown regardless of `isExpanded` |
| Toggle disabled | `onToggleExpanded` not set; toggle still visible when expandable, but disabled — see **expand-toggle-enablement** |
| Toggle pressed | The platform's standard pressed appearance for this kind of control; the component applies no custom pressed styling of its own (see Platform Notes) |
| Filled-width (wrapped) | Bubble is exactly `maxWidth` wide instead of sized to content — see **fills-width-when-wrapped** |
| Focused | Not applicable to the bubble itself — the bubble is never itself a key/focused view; the transcript's row-selection focus ring belongs to its host (see **Accessibility**) |
| Loading/streaming | Not applicable in this file. The chat message carries a streaming flag (used elsewhere for a composing caret) and a delivery state (settled / sending / failed, used elsewhere for a delivery-failure line), but the component reads neither — it renders only the message's text, role, timestamp, and work-output flag. Unlike a companion toolkit's own message-bubble component, this component never shows a composing caret or a failure indicator of its own. |

