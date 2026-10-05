
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | collapse-by-default, accent-red-only-when-disclosed, keep-warning-glyph-gold | Initial render | Disclosure closed, neutral (no red); the ⚠ glyph is gold |
| T2 | accent-red-only-when-disclosed | Open the disclosure | Red border/tint appears and the title text turns red; the ⚠ glyph stays gold |
| T3 | open-warn-phase-first | Click "Delete {entityNoun}" | Dialog opens on the warn phase naming the `childEntities` cascade and asking to proceed |
| T4 | advance-to-confirm-on-yes | Click "Yes" on the warn phase | Dialog advances to type-to-confirm; `onConfirm` not yet called |
| T5 | require-exact-identifier | Type a near-match (wrong case / trailing space) | "Permanently Delete" stays disabled |
| T6 | require-exact-identifier, call-onconfirm-once-enabled | Type the exact `confirmValue`, click Permanently Delete | Button enables; `onConfirm` called once; label shows "Deleting…" |
| T7 | reject-empty-confirm-value | `confirmValue=""`, empty input, reach confirm phase | "Permanently Delete" stays disabled |
| T8 | lock-dialog-while-busy | While `onConfirm` pending, try Escape / close / outside | Dialog stays open; no close affordance is shown |
| T9 | surface-error-inline | `onConfirm` rejects | Error message shows inside the dialog; busy clears; dialog stays open for retry |
| T10 | reset-on-cancel-or-success | Cancel, or resolve `onConfirm` | Dialog closes and resets to empty, warn-phase state |
| T11 | avoid-permanence-claims-when-reversible | `actionVerb={{ imperative: "Archive", gerund: "Archiving", reversible: true }}` with a caller `description`; open, click Yes | Blurb, warn body, and confirm-phase copy all read "Archive"/"Archiving"; no "Permanently", "cannot be undone", or "deletion" anywhere in the flow |
| T12 | avoid-permanence-claims-when-reversible | Same reversible `actionVerb`, `entityNoun="organization"`, no `description` override | The built-in fallback blurb itself reads "Archive this organization. This can be undone later." — no "permanently" or "cannot be undone"; confirm phase shows "Type {confirmValue} to confirm" (no "deletion") |
| T13 | swap-trigger-glyph-when-reversible | Reversible `actionVerb`; open the disclosure | Trigger button renders the archive glyph; no trash glyph present |
| T14 | swap-trigger-glyph-when-reversible | Default (no `actionVerb`); open the disclosure | Trigger button renders the trash glyph; no archive glyph present |
| T15 | call-onconfirm-once-enabled | Reversible `actionVerb`; reach confirm phase, type the exact `confirmValue`, click the CTA while `onConfirm` is pending | Busy label reads "Archiving…" (from `actionVerb.gerund`), never "Deleting…" |
| T16 | surface-error-inline | Reversible `actionVerb`; `entityNoun="organization"`; `onConfirm` rejects a non-`Error` value | Inline error falls back to "Failed to archive organization." (lowercase `actionVerb.imperative`), since `e.message` never runs for a non-`Error` rejection |
| T17 | disable-actions-while-busy, call-onconfirm-once-enabled | Reach confirm phase with the exact `confirmValue` typed; double-click the confirm CTA in quick succession | `onConfirm` is called exactly once; once `busy` is true both the CTA and Cancel are disabled, so the second click has no enabled target to hit |
| T18 | select-article-from-first-letter | `entityNoun="Ecosystem"`, reach the warn phase | Warn body reads "an ecosystem" |
| T19 | select-article-from-first-letter | `entityNoun="Bucket"`, reach the warn phase | Warn body reads "a bucket" |

