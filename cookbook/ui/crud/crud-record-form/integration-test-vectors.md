
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | build-fields-from-writable-columns | meta with a `serverManaged` `id` column | No control for `id`; controls for every writable column |
| T2 | pick-control-by-type | columns of enum / boolean / integer / object type | A select / a checkbox / numeric input / JSON textarea respectively |
| T3 | wrap-nonboolean-in-field, mark-required-and-json | required string col + object col | String field labeled "`name` *"; object field wrapped in a Field with a `JSON` hint |
| T4 | seed-draft-from-initial | `initial = { name:"Ada", active:true }` (edit) | Name input pre-filled "Ada"; the active checkbox checked |
| T5 | reject-empty-required | submit with a required field blank | Submission blocked; "`<name>` is required" shown inline |
| T6 | validate-numbers | integer column = "1.5" | Blocked; "`<name>` must be an integer" |
| T7 | validate-numbers | number column = "abc" | Blocked; "`<name>` must be a number" |
| T8 | validate-json | object column = "{bad" | Blocked; "`<name>` must be valid JSON" |
| T9 | omit-untouched-optionals-on-create | create; leave an optional string empty | Payload omits that key (DB default applies) |
| T10 | disable-and-skip-create-only-on-edit | edit; a `createOnly` column holding a client-supplied `rdid` (a caller-chosen id, not server-generated) | Its control is disabled; payload excludes it |
| T11 | run-submit-through-busy-state | valid submit; submit callback pending | Cancel/Save disabled; Save shows "Saving…" until it completes |
| T12 | run-submit-through-busy-state | submit callback fails | Error shown inline; draft values retained |
| T13 | seed-draft-from-initial | edit; `initial` has an object/array column value | Draft is prefilled with the pretty-printed (2-space indented) JSON text |
| T14 | omit-untouched-optionals-on-create, reject-empty-required | create; leave a required boolean untouched | Payload sends `false` for that column |
| T15 | omit-untouched-optionals-on-create | create; leave an optional boolean untouched | Payload omits that key |
| T16 | validate-numbers | number column = "1e999" | Blocked; "`<name>` must be a number" (the value is not a finite number) |
| T17 | clear-field-by-type-on-edit | edit; clear a nullable optional column | Payload sends `null` for that column |
| T18 | clear-field-by-type-on-edit | edit; clear a plain (non-enum) optional string column | Payload sends `''` for that column |
| T19 | clear-field-by-type-on-edit | edit; clear an optional enum/integer/JSON column | Column omitted from the payload; its old value survives |
| T20 | disable-and-skip-create-only-on-edit | edit; a required, empty `createOnly` column | Submission succeeds — no "is required" error; column excluded from the payload |
| T21 | lock-form-when-read-only | `canWrite=false`, edit mode | Every control is disabled with its seeded value; no Save control; the footer shows one "Close" control that calls the cancel callback |
| T22 | gate-save-on-dirty-on-edit | edit; an untouched row | Save is disabled |
| T23 | gate-save-on-dirty-on-edit | edit; change a field, then change it back to the loaded value | Save enables after the change and disables again after the revert |
| T24 | gate-save-on-dirty-on-edit | create; untouched | Save is enabled |

