
| State | Appearance change |
|-------|------------------|
| Default | The label shows the view model's title; the field shows the current value's field-string representation, right-aligned, in the code-role monospaced font. |
| Editing | The user's typed text is shown verbatim in the field while focused; no live input formatting or validation is attached (deliberate — see Design Decisions), so intermediate/partial text (e.g. a leading `-`) is not rejected mid-edit. |
| Committed — valid | On commit (editing ending, or the field's own change action firing), a parseable value is clamped (unless bounds are contradictory) and written back to the field and the view model. |
| Committed — invalid | An unparseable string reverts the field and label text to the view model's current value/title; the view model's value is left unchanged. |
| Pressed | Not applicable: the component renders no button; there is no press/highlight state to define. |
| Disabled | Not implemented in source; the enabled state is never read or set on either control. A caller may set the field's enabled state directly, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by this component; any focus indication shown when the field becomes focused is the field's own native focus appearance. |
| Loading | Not applicable: the component performs no asynchronous operation and shows no loading indicator. |

