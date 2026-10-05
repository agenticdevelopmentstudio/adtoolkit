
The form is a **metadata-driven** create/edit form for one generic-CRUD
table. From the table's metadata it builds one control per **writable**
column — skipping every server-managed column (ids, timestamps) — picking
the control by column type: enum → a select, boolean → a checkbox,
integer/number → numeric input, object/array/unknown → JSON textarea,
everything else → text input. Each non-boolean control is wrapped in a
shared field wrapper (label + optional "JSON" hint); booleans ride inline
beside their caption.

Absence of an `initial` row means **create**; a supplied `initial` means
**edit**. The form owns a text/boolean **draft** buffer seeded from
`initial` and, on submit, coerces the draft into a typed payload:
required-but-empty fields and malformed numbers/JSON **throw** a
field-named error shown inline; on create, untouched optional fields are
omitted so DB defaults apply; on edit, `createOnly` columns are disabled
and skipped (the backend strips them from the update). Submission runs
through a shared submission-state mechanism, which drives the busy/error
state and disables the buttons while saving.

It powers any surface that creates/edits one CRUD row without
hand-authored fields (see Platform Notes for its first consumer).

