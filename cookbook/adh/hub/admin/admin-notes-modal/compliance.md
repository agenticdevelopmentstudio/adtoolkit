
| Check | Status | Category |
|-------|--------|----------|
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The source shows no override of `Dialog`'s default focus-trap/dismissal
handling on either dialog (no custom keydown handling, no manual `.focus()`
calls), so `focus-management` passes on the strength of `Dialog`'s
own unmodified behavior.

`separation-of-concerns` passes: `admin-notes-modal.tsx` imports only shared UI primitives (`Dialog`, `Textarea`, `Button`, `ListWithDetailsPane`) and the `AdminNote` type, performs no fetching, and receives its notes and an `onSave` callback from the caller. `unit-test-coverage` passes: `adminNotesModal.test.tsx` covers the staged working copy discarded on Cancel, the dirty-gated outer Save button, adoption of refetched notes after a save, and a refetch landing while the dialog is open (adopted when nothing is staged, never clobbering staged edits).

