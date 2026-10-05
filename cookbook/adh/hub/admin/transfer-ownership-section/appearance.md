
- **Corner radius**: Not applicable at this component's own level — no rounding is applied to any
  element this file renders directly; corner treatment belongs to the composed disclosure, dialog,
  button, and input components, each out of scope for this recipe.
- **Padding**: The disclosed body is a column with 12px gaps; the dialog's status/preview area is a
  column with 8px gaps at 14px text size; the confirm-gate group is a column with 8px gaps. No
  independent padding value is set beyond these gaps — interior padding is the composed
  dialog/input/button components' own.
- **Font**: Body copy and dialog copy use 14px text; the object's identifier
  and the value the user must type back are rendered in a monospace font.
- **Background**: Not set at this component's own level — inherited from the disclosure and
  dialog containers, which are out of scope for this recipe.
- **Foreground/Text**: Muted-text theme role for descriptive copy, the "these will lose access"
  heading, and the parenthetical `via`/`kind` text; primary-text theme role for the object's
  identifier and each revoked-principal's name; gold theme role for the token-revocation warning
  icon.
- **Border**: Not applicable — no border is set on any element this file renders directly.
- **Shadow**: Not applicable — no shadow is set on any element this file renders directly.
- **Min/Max size**: The dialog is wider than the platform's default dialog width, because a
  mid-length identifier wraps confusingly inside itself at the default width.

