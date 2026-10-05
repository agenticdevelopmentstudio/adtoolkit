
| State | Appearance change |
|-------|--------------------|
| Closed | Nothing rendered (`open` is `false`); working list resets to the `notes` parameter. |
| Open, notes present | Note list shows Author/Added/Modified columns via the list-with-details pane. |
| Open, zero notes | List shows "No admin notes yet." instead of rows. |
| Row selected | Detail pane shows the note's content and an "Edit" action. |
| No row selected | Detail pane shows "Select a note to read it." |
| Note editor open, new | Editor titled "New note"; blank text field; editor Save disabled until non-blank input. |
| Note editor open, edit | Editor titled "Edit note"; text field pre-filled with the note's content. |
| Working list dirty | Outer Save enabled (unless `busy` is `true`). |
| Working list not dirty | Outer Save disabled. |
| `busy` is `true` | Outer Save disabled regardless of dirty state; Cancel, Escape, and close remain active. |

