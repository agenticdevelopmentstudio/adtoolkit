
- **build-fields-from-writable-columns**: The form MUST render one control per
  writable column and MUST NOT render any `serverManaged` column.
- **pick-control-by-type**: The form MUST pick each control from the column
  type — enum → a select, boolean → a checkbox, integer/number → numeric
  input, object/array/unknown → JSON textarea, otherwise text input.
- **wrap-nonboolean-in-field**: The form MUST wrap each non-boolean control in
  a field wrapper labeled with the column name, and MUST render a boolean
  inline beside its caption.
- **mark-required-and-json**: The form MUST append ` *` to a required column's
  label and MUST show a `JSON` hint on object/array/unknown columns.
- **seed-draft-from-initial**: The form MUST seed its draft from `initial` when
  editing (booleans as booleans, JSON columns pretty-printed, others as text) and
  MUST start create fields empty (booleans left unset).
- **reject-empty-required**: On submit, the form MUST block submission and show
  a "`<name>` is required" error when a required column is empty. A required
  **boolean** column is exempt from this check: an untouched one sends `false`
  instead of throwing (see **omit-untouched-optionals-on-create**).
- **validate-numbers**: On submit, a non-finite number MUST be rejected with
  "`<name>` must be a number", and a non-integer in an integer column with
  "`<name>` must be an integer".
- **validate-json**: On submit, an object/array/unknown column whose text is
  not valid JSON MUST be rejected with "`<name>` must be valid JSON".
- **omit-untouched-optionals-on-create**: On create, an empty/untouched
  optional field MUST be omitted from the payload so the backend column default
  applies; an untouched required boolean MUST send `false`.
- **disable-and-skip-create-only-on-edit**: On edit, a `createOnly` column MUST
  be rendered disabled and MUST be excluded from the update payload — stripped
  before required-field validation runs, so an empty, disabled `createOnly`
  column never blocks submission.
- **clear-field-by-type-on-edit**: On edit, clearing an optional field MUST
  send `null` for a nullable column, `''` for a plain (non-enum) string
  column, and MUST omit every other column type from the payload (its prior
  value survives the partial update).
- **run-submit-through-busy-state**: On submit the form MUST call the
  provided submit callback with the payload, disabling Cancel/Save and
  showing "Saving…" while the call is pending, and MUST surface a thrown
  error inline without losing the draft.
- **lock-form-when-read-only**: `canWrite` MUST be a required input with no
  default. When it is false the form MUST render every writable column
  disabled (showing the seeded value), MUST drop the Save control, and MUST
  render a single **Close** control in place of Cancel that invokes the
  cancel callback, because a Save the backend would refuse only leads to a 403.
- **gate-save-on-dirty-on-edit**: On edit, Save MUST be disabled until at least
  one field differs from the loaded row, and MUST disable again when an edit is
  reverted to the loaded value; on create Save MUST be enabled from the start,
  since there is no loaded baseline to diff against.

