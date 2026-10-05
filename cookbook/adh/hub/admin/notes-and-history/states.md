
| State | Appearance change |
|-------|------------------|
| Notes: Loading (`notesLoading=true`) | Notes section shows only "Loading…" (dim-text theme role); no list is rendered regardless of `notes` contents |
| Notes: Empty (`notesLoading` false/omitted, `notes.length===0`) | Notes section shows "No admin notes." (dim-text theme role); no list is rendered |
| Notes: Populated (`notesLoading` false/omitted, `notes.length>0`) | Notes section renders a bordered/background card per note, in array order |
| History: Loading (`historyLoading=true`) | History section shows only "Loading…"; no list is rendered regardless of `history` contents |
| History: Empty (`historyLoading` false/omitted, `history.length===0`) | History section shows "No history."; no list is rendered |
| History: Populated (`historyLoading` false/omitted, `history.length>0`) | History section renders a plain text line per entry, in array order |
| Pressed | Not applicable: the component renders no button, link, or other pressable control. |
| Disabled | Not applicable: the component exposes no `disabled` parameter and no control capable of being disabled. |
| Focused | Not applicable: the component renders no focusable element — no interactive control appears anywhere in its design. |

