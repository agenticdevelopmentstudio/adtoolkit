
The Rdid Editor is the one control for editing a type-prefixed rdid
(`<type>.<scope>.<name>`). An rdid's type and inherited scope are fixed at
creation and can never change afterward — mirroring how the backend
rejects any type/scope change — so the control renders that fixed portion
as inert, non-interactive text and exposes only the editable leaf segment
as a real input field. When the prefix is the empty string there is
nothing fixed to protect (e.g. a brand-new, unsaved draft, or a top-level
rdid kind), so the whole value is edited as one full-width input instead.

The component is backend-agnostic by design: it does not compute the
prefix or validate the leaf itself. The caller computes the prefix
(typically derived from the rdid grammar) and any error (from leaf
validation) and passes them in as plain inputs, so the editor has no
dependency on the rdid grammar's validation rules — only on displaying
whatever the caller decides.

It composes two lower-tier shared components rather than building its own
field shell: a shared form-control shell (border, radius, focus/invalid
styling) for the editable leaf, and a shared hint/error footnote component
for the slot beneath it. The caption above the control uses a shared
"uppercase-mono caption" typography role rather than a bespoke label
style.

