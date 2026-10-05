
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `notes-and-history.admin-notes-heading` | Admin notes | Heading above the notes section |
| `notes-and-history.loading` | Loading… | Shown in place of either section's list/empty message while that section's loading flag is `true` |
| `notes-and-history.no-admin-notes` | No admin notes. | Shown when `notesLoading` is not `true` and `notes` is empty |
| `notes-and-history.history-heading` | History | Heading above the history section |
| `notes-and-history.no-history` | No history. | Shown when `historyLoading` is not `true` and `history` is empty |

These five strings are hardcoded as literal English text with no
translation call in the current implementation; the keys above are what an
implementation would externalize them to.

