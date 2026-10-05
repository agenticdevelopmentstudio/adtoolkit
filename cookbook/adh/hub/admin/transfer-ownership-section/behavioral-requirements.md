
- **collapsed-by-default**: The section MUST render its disclosure
  collapsed on initial render.
- **root-section-labeled**: The component MUST render its root container
  with the accessible label "Transfer Ownership".
- **disclosure-labeled-transfer-ownership**: The disclosure trigger MUST
  show a bidirectional-transfer glyph followed by the text "Transfer
  Ownership".
- **describes-transfer-effect**: When the disclosure is open, the section MUST show text stating
  that the object's address changes, everything beneath it is re-addressed with it, and access
  granted in the current workspace does not follow.
- **trigger-button-labeled-distinctly**: The dropdown's trigger button MUST show "Transfer
  {entityNoun}" — a label distinct from the disclosure's "Transfer Ownership" trigger, so the two
  buttons do not share one accessible name.
- **renders-nested-targets-as-submenu**: A destination target whose `children` array is non-empty
  MUST render as a submenu labeled with the target's `name`, and its `children` MUST render
  recursively inside that submenu.
- **renders-leaf-targets-as-items**: A destination target with no `children` MUST render as a
  single menu item labeled with the target's `name`.
- **disables-current-target**: A destination target that matches `currentTarget` (by `slug`, and by
  `kind` when both sides define one) MUST render its menu item disabled and MUST append
  " (current)" to its label.
- **current-target-not-selectable**: Activating an item rendered as "(current)" MUST NOT invoke the
  choose operation — it MUST have no activation handler.
- **selecting-target-opens-dialog-and-runs-preview**: Activating a non-current, non-submenu target
  MUST close the dropdown menu, set it as the chosen target (which opens the confirmation dialog),
  clear any prior preview result/typed value/error, and invoke the preflight operation (`onPreview`)
  with that target.
- **preview-populates-dialog**: When the preflight operation resolves for the current selection, its
  transfer preview result MUST populate the confirmation dialog.
- **preview-error-shown-inline**: When the preflight operation rejects, the section MUST show an
  inline error — the rejection's `message` when it carries one, otherwise "Could not check this
  transfer." — and MUST leave the dialog open.
- **stale-preview-ignored**: A settled preflight result whose sequence number no longer matches
  the current selection (because the user cancelled or chose a different target while it was
  pending) MUST NOT update the preview result, error, or busy state.
- **dialog-title-names-destination**: The dialog title MUST read "Transfer this {entityNoun} to
  {chosen.name}?".
- **dialog-shows-checking-state**: While a request is pending and no preview result has arrived
  yet, the dialog body MUST show "Checking…".
- **shows-revoked-token-count**: When the resolved preview result's `tokens` is greater than zero, the
  dialog MUST show the count of API tokens that will be revoked, using the singular "token" only
  when the count is exactly 1.
- **lists-revoked-principals**: When the preview result's `revoking` is non-empty, the dialog MUST list each
  entry's `name`, followed by its `via` alone when `kind` is `"user"`, or `"{kind}, {via}"`
  otherwise.
- **shows-no-access-revoked**: When the preview result's `revoking` is empty, the dialog MUST show "No access is
  revoked.".
- **confirm-gate-hidden-until-preview**: The type-to-confirm label and input MUST NOT render until
  the preview result is populated.
- **confirm-target-is-trimmed-label**: The value the user must type to arm the Transfer button MUST
  be `entityLabel` with leading and trailing whitespace removed.
- **confirm-requires-nonempty-target**: The Transfer button MUST stay disabled whenever the trimmed
  `entityLabel` is empty, regardless of what is typed.
- **confirm-match-ignores-edge-whitespace**: The typed value MUST arm the Transfer button only when
  its own leading/trailing whitespace, once trimmed, equals the trimmed `entityLabel` exactly — an
  interior or case difference MUST NOT match.
- **transfer-button-disabled-until-armed**: The Transfer button MUST stay disabled while a request
  is in flight (busy), while no preview result has arrived, or while the typed value does not
  confirm.
- **transfer-button-not-destructive-styled**: The Transfer button MUST use the `"warning"` visual
  variant rather than a destructive one.
- **transfer-invokes-onconfirm-once**: Activating the enabled Transfer button MUST invoke the
  confirm operation (`onConfirm`) exactly once for that confirmation, passing the chosen target.
- **transfer-label-reflects-progress**: While the confirmed transfer is pending, the Transfer
  button MUST read "Transferring…"; otherwise it MUST read "Transfer".
- **dialog-locks-during-transfer**: While the confirmed transfer is pending, the
  dialog's close control MUST be hidden and the Cancel button MUST be disabled.
- **preview-does-not-lock-dialog**: While only the preflight is pending, the dialog's
  close control MUST remain shown, the Cancel button MUST remain enabled, and dismissing the dialog
  (Escape, outside click, close, or Cancel) MUST reset it.
- **transfer-error-shown-inline-dialog-stays-open**: When the confirm operation rejects, the section MUST
  show an inline error — the rejection's `message` when it carries one, otherwise "Failed to
  transfer {noun}." — clear the busy state, and MUST NOT close the dialog.
- **transfer-success-resets-state**: When the confirm operation resolves, the section MUST reset the
  chosen target, preview result, typed value, busy state, and error, which closes the dialog.
- **cancel-resets-and-closes**: Activating Cancel, or otherwise closing the dialog while not
  confirming, MUST reset the same state and close the dialog.
- **reset-orphans-inflight-preview**: Resetting MUST invalidate any in-flight preflight so its
  eventual resolution can no longer change state.
- **switching-target-clears-typed-and-error**: Choosing a new target MUST clear any previously
  typed confirmation text and inline error before starting the new target's preflight, regardless of
  what was already in flight or on screen for the prior target. This is a property of the choose
  operation itself, verified at the unit level: the open confirmation dialog currently covers the
  destination dropdown, so a second choose call cannot be reached through pointer interaction while
  the first target's dialog is still open.
- **wider-dialog-for-long-identifiers**: The dialog content MUST use a wider layout than the
  platform's default dialog width.

