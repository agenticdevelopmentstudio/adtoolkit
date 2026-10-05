
- Root element carries the accessible label "Transfer Ownership"; every interactive control is a
  native, focusable element via the shared button, dropdown-menu, and input components this section
  composes — no bespoke non-semantic clickable element is used.
- The disclosure trigger ("Transfer Ownership") and the dropdown trigger ("Transfer {entityNoun}")
  MUST carry distinct accessible names, per `trigger-button-labeled-distinctly`, so two buttons in
  the same section are not ambiguous to assistive technology.
- The type-to-confirm input is labeled by an explicit, programmatically associated label, not a
  placeholder alone.
- Keyboard and assistive-technology navigation for the disclosure trigger, the dropdown menu
  (including nested submenus), the dialog, and the input all come from the shared disclosure,
  dropdown-menu, dialog, and input/button primitives this section composes — no custom key handling
  appears in this component's own logic, so keyboard behavior is that primitive's own recipe's
  concern, not this one's.
- Minimum tap target sizing is likewise owned by the shared button, dropdown-menu-item, and
  input components this section composes (all using a small size or their defaults); no local
  min-width/min-height override is applied here.
- Contrast is governed by the semantic color theme roles this component consumes (text, muted
  text, gold); no raw color value or component-specific contrast override is applied here.
- The dialog body's transition from "Checking…" to the resolved preview content (or an inline
  error) carries no live-region announcement: neither this section nor the shared dialog primitive
  it composes establishes one, so an assistive-technology user who already opened the dialog gets no
  signal that the content changed without re-reading it.

