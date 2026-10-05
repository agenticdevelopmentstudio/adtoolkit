
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Field | agenticdevelopertoolkit://recipes/field | Label + optional hint wrapper around each non-boolean control | yes | `label` = `name` (+ ` *` when required); `hint="JSON"` for object/array/unknown columns |

Composed shared primitives without their own recipe domains: the per-type
control picker (rendering a select, checkbox, textarea, or text input
depending on column type), a button pair (Cancel + Save), inline error
text, and the shared submission-state mechanism (busy/error orchestration).
The metadata→payload logic (selecting writable columns, seeding the draft,
and building the submit payload) is exported alongside the component. See
Platform Notes for the exact names of these pieces in the source
implementation.

