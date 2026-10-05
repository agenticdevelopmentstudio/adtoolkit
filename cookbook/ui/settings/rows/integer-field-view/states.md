
| State | Appearance change |
|-------|------------------|
| Default | The label shows the view model's title; the text field shows the current value's formatted string, right-aligned, in the code-role monospaced font. |
| Editing | The user's typed text is shown verbatim while focused; no formatter is attached to intercept keystrokes (deliberate — see Design Decisions), so intermediate/partial text (e.g. a leading `-`) is not rejected mid-edit. |
| Committed — valid | On end-of-editing (Return/Tab/click-away) or on the field's own action firing, a parseable value is clamped (unless bounds are contradictory) and written back to the text field and the view model. |
| Committed — invalid | An unparseable string reverts the text field and label to the view model's current value/title; the view model is left unchanged. |
| Pressed | Not applicable: neither file renders a button; there is no press/highlight state to define. |
| Disabled | Not implemented in source; an enabled flag is never read or set on the label or text field. A caller may set the text field's enabled state directly through the public text-field property, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by this component; any focus ring shown when the field becomes first responder is the platform's own native focus appearance for that control. |
| Loading | Not applicable: the component performs no asynchronous operation and shows no loading indicator in source. |

