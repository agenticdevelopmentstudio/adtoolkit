
| State | Appearance change |
|-------|------------------|
| Default | — |
| Loading | Renders "Loading…" instead of the list |
| Populated | Renders the list-with-details layout with the pane's rows and columns |
| 0 rows selected | "Admin notes" (and, on Pending Users, "Send invitation") stay disabled, per the list-with-details layout's own selection-required contract |
| Notes modal open | The notes modal is shown open only while the admin-notes target id still names a row present in the pane's rows |
| Send modal open (Pending Users only) | The send-invitation modal opens, seeded with emails/phones, and is treated as a fresh instance on a new seed |
| Add modal open (Pending Users only) | The add-users modal opens |
| Pressed | Not applicable — traced. This component renders no button, link, or input directly; every pressable control belongs to a composed component. |
| Focused | Not applicable — traced, for the same reason: no focusable element originates in this component. |
| Disabled | Not applicable — traced. None of the three panes accepts a whole-component disabled state; per-action disabling (the selection requirement) is configuration handed to the list-with-details layout, not a state this component enters itself. |

