
- **collapse-by-default**: The section MUST render its disclosure collapsed
  on first render, so the destructive affordance is opt-in rather than always
  present.
- **accent-red-only-when-disclosed**: The section MUST apply the red accent
  theme role (red title text and red border/background) only while the disclosure is
  open, and MUST stay neutral while it is closed.
- **keep-warning-glyph-gold**: The section MUST render the warning glyph in the gold
  accent theme role in both the closed and open states.
- **open-warn-phase-first**: Activating the Delete button MUST open the confirm
  dialog on the acknowledge ("warn") phase, describing the cascade through
  `childEntities` and asking whether to proceed.
- **select-article-from-first-letter**: The warn-phase body MUST prefix the
  lowercased `entityNoun` with "an" when `entityNoun`'s first character (after
  trimming) is a vowel, compared case-insensitively, and "a" otherwise —
  e.g. "an ecosystem", "a bucket". This is a literal first-letter check, not a
  phonetic one, so it also reads "an user" for `entityNoun="User"` and "a hour"
  for `entityNoun="Hour"`.
- **advance-to-confirm-on-yes**: Choosing "Yes" on the acknowledge phase MUST
  advance the dialog to the type-to-confirm phase and MUST NOT delete yet.
- **require-exact-identifier**: The final delete button MUST remain disabled
  until the typed text exactly equals `confirmValue` — case-sensitive and untrimmed.
- **reject-empty-confirm-value**: When `confirmValue` is empty the final delete
  button MUST stay disabled even with an empty input, so a blank identifier never
  arms the delete.
- **call-onconfirm-once-enabled**: Activating the enabled confirm button MUST
  call `onConfirm` exactly once and MUST show a busy state built from
  `actionVerb.gerund` followed by an ellipsis (e.g. "Deleting…", or "Archiving…" when
  `actionVerb.reversible` is `true`) while it is pending.
- **lock-dialog-while-busy**: While `onConfirm` is pending, the section MUST NOT
  allow the dialog to be dismissed (no close button, no Escape/outside close) until
  it settles.
- **disable-actions-while-busy**: While `onConfirm` is pending, the confirm-phase
  CTA and the Cancel button MUST both be disabled, so a double-click on the CTA
  cannot fire a second `onConfirm` call and Cancel cannot abandon an in-flight
  delete.
- **surface-error-inline**: If `onConfirm` rejects, the section MUST show the
  error message inside the dialog, clear the busy state, and keep the dialog open so
  the user can retry. When the rejection is not an `Error` instance (so no
  `.message` is available), the section MUST fall back to "Failed to {imperative}
  {noun}." built from `actionVerb.imperative` and `entityNoun`, both lowercased —
  e.g. "Failed to archive organization."
- **reset-on-cancel-or-success**: Cancelling, or a successful delete, MUST reset
  the dialog back to a closed, empty, warn-phase state. This reset is scoped to
  the dialog only — it MUST NOT collapse the `Disclosure`, whose `disclosed` state
  is independent of the dialog's outcome. A stale error from a previous failed
  attempt MUST persist while the user edits the confirm input; only the next
  `onConfirm` attempt clears it, per surface-error-inline.
- **avoid-permanence-claims-when-reversible**: When `actionVerb.reversible` is
  `true`, the blurb, the warn phase, and the confirm phase MUST NOT render
  "Permanently", "cannot be undone", or "deletion" anywhere — every phrase that
  otherwise asserts permanence or data destruction swaps to non-destructive wording
  built from `actionVerb.imperative`/`gerund` instead (e.g. "Archive this
  organization. This can be undone later."). This holds even when the caller passes
  no `description` override — the built-in fallback blurb must itself be
  reversible-safe, not merely the caller-supplied copy.
- **swap-trigger-glyph-when-reversible**: When `actionVerb.reversible` is
  `true`, the disclosed trigger button MUST render the archive glyph instead of
  the trash glyph. The Danger Zone's red palette (border, tint, title accent) does NOT
  change with reversibility — only the glyph and the copy do (see
  accent-red-only-when-disclosed, which is unconditional).

