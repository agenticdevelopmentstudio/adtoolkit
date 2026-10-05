
- **Decision**: Render the fixed `<type>.<scope>.` prefix as inert static
  text rather than as an editable part of the input's value.
  **Rationale**: Mirrors the backend's own invariant that an rdid's type
  and inherited scope can never change after creation — the component's
  own doc comment states this explicitly — so the UI never offers an
  edit the backend would reject.
  **Approved**: pending
- **Decision**: Lowercase every keystroke inside the `onChange` handler,
  rather than leaving casing to the caller or flagging it only via
  `error`.
  **Rationale**: The rdid grammar (`SEGMENT_RE` in `rdid.ts`) only
  accepts lowercase segments; normalizing at input time keeps the
  `error` slot reserved for genuinely invalid characters or format
  rather than surprising the user with a case-mismatch error on an
  otherwise valid leaf.
  **Approved**: pending
- **Decision**: Share one footnote slot for `hint` and `error` (via
  `FieldFootnote`) instead of rendering both at once.
  **Rationale**: Matches `FieldFootnote`'s own designed precedence —
  error replaces hint, they are never shown together — so `RdidEditor`
  composes that component's contract rather than re-implementing or
  duplicating it.
  **Approved**: pending
- **Decision**: Leave `FieldFootnote`'s `errorId` unset, so the rendered
  error text is not linked to the input via `aria-describedby`.
  **Rationale**: `FieldFootnote` exposes `errorId` precisely so a caller
  can wire this link, but `RdidEditor` does not thread one through
  today; a screen-reader user hears `aria-invalid` on the input without
  a guaranteed programmatic path to the error text itself (see
  Accessibility).
  **Approved**: pending

**Decision**: the editor's input is a fixed 36px tall with no minimum-tap-target enforcement, and conformance to a 44x44 touch-target guideline has not been measured.

**Rationale**: meeting or being exempt from the guideline depends on the ecosystem's actual viewport and pointer usage; closing the gap takes measuring the rendered control against the platform guideline and raising the height if it falls short.

**Approved**: pending

**Decision**: the prefix's muted-text over field-background contrast is delegated to the active theme; the component does not verify a minimum contrast ratio.

**Rationale**: the colors resolve at runtime from semantic role variables, so conformance can only be checked against the resolved token values; closing the gap takes inspecting those tokens (or a theme-level contrast test) for small text.

**Approved**: pending

