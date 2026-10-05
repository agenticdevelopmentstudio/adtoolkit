
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-sync-001 | load-replaces-an-idle-field | A field showing `old` that nobody is editing; refresh with `new` | The field shows `new` |
| field-sync-002 | load-skips-a-field-being-edited | A field showing `typing` with an edit session open; refresh with `stored` | The field still shows `typing` |
| field-sync-003 | force-discards-an-edit-in-progress | A field showing `refused` with an edit session open; forced revert with `stored` | The field shows `stored` and has no open edit session |
| field-sync-004 | select-matches-by-represented-value | A pop-up with two items both titled `Acme`, representing `c1` and `c2`; select `c2` | The second item is selected |
| field-sync-005 | select-with-no-match-clears-selection | The same pop-up; select `gone` | No item is selected |
| field-sync-006 | load-skips-a-focused-multiline-view | A multi-line view holding focus with text `draft`; refresh with `stored` | The view still shows `draft` |
| field-sync-007 | force-replaces-a-multiline-view | A multi-line view holding focus with text `draft`; forced revert with `stored` | The view shows `stored` |
| field-sync-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

