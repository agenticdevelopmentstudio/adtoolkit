
| State | Appearance change |
|-------|------------------|
| Default | Populated: header bar, divider, and a sectioned list of app groups and window rows. |
| Pressed | Not applicable — the view applies no custom pressed styling; toggle and button press feedback is the system's standard checkbox and button chrome. |
| Disabled | Refresh button disabled while `isLoading`; a section's select-all toggle disabled when it has no selectable windows; a row's toggle disabled, and its title colored with the secondary text color, when its window is not selectable. |
| Focused | Not applicable — no custom focus-ring styling appears in source; standard keyboard focus rendering on each toggle and button applies unmodified. |
| Loading | List content replaced by a centered progress indicator (scaled to 80% size) and the caption "Scanning windows...", in a frame with a minimum height of 200 points. |
| Empty | After a completed scan with no application groups: a centered generic-window icon, "No windows found", and the hint "Make sure Accessibility permission is granted.", in a frame with a minimum height of 200 points. |
| Accessibility banner shown | `needsAccessibility == true`: a warning-tinted banner is shown above whichever of Default, Loading, or Empty is otherwise active. |
| Section fully selected | Select-all toggle for that section shows checked. |
| Section partially or not selected | Select-all toggle for that section shows unchecked (covers both "some selected" and "none selected"). |
| Row's window owned by the active group | Toggle enabled, no context badge shown (the badge is suppressed when the owning context equals `activeGroupID`). |
| Row's window owned by a different context | Toggle disabled, title dimmed to the secondary text color, and a colored context-name badge is shown. |

