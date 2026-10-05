
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| number-field-view-001 | builds-label-from-view-model-title | View model's title = `"Left Margin"` | Label text == `"Left Margin"` after construction |
| number-field-view-002 | right-aligns-field-text | Construct the field with any view model | The field's text is right-aligned |
| number-field-view-003 | omits-input-formatter | Construct the component | No input formatter/validator is attached to the field |
| number-field-view-006 | links-field-accessibility-title | Construct the component | The field's accessible name is associated with the label |
| number-field-view-007 | themes-field-live | Construct the field, then switch the active theme to one whose palette has a distinct code font/`.primaryText` color | The field's font and text color update to match the new palette, both immediately at construction and again after the change |
| number-field-view-008 | fixes-field-width | Construct with `fieldWidth: 90` | The field's width is 90 |
| number-field-view-009 | aligns-label-when-width-fixed | Construct with `labelWidth: 100` | The label is right-aligned and its width is 100 |
| number-field-view-010 | lays-out-content-width-row-when-label-fixed | Construct with `labelWidth: 100` | The row's top/leading/bottom are pinned to the container; its trailing edge is constrained to be no greater than the container's trailing edge |
| number-field-view-011 | lays-out-full-width-row-by-default | Construct with `labelWidth: none` | The row is pinned to all four edges of the container |
| number-field-view-012 | initializes-display-from-view-model | View model's title = `"Left Margin"`, value = `12` | After init, label text == `"Left Margin"` and field text == `"12"` |
| number-field-view-013 | syncs-on-external-change | After construction, externally change the view model's title and value, then invoke its change-notification callback | The label and field text both update to reflect the new view-model state |
| number-field-view-014 | exposes-constituent-properties | Construct the component with `minimum: 0, maximum: 10` | The label, field, `minimum` (0), and `maximum` (10) are all accessible from outside the component |
| number-field-view-017 | confines-to-ui-thread | Attempt to construct or mutate the component from a thread other than the UI thread | The platform rejects or prevents the attempt (statically or at runtime, depending on platform — see Platform Notes) |
| number-field-view-018 | commits-on-field-action | Type `"7"` into the field and trigger its change action directly | The view model's value == 7 after the call |
| number-field-view-019 | commits-on-editing-end | Type `"7"` into the field and end editing | The view model's value == 7 after the call |
| number-field-view-020 | parses-committed-text-via-value-type | Field text = `"42"`, then commit | The view model's value == 42 |
| number-field-view-021 | reverts-on-unparseable-text | View model's value = 5; set field text = `"abc"` and commit | The view model's value remains 5; the field text is reset to `"5"` |
| number-field-view-022 | clamps-to-bounds | `minimum = 0`, `maximum = 10`; set field text = `"99"` and commit | The view model's value == 10; the field text == `"10"` |
| number-field-view-023 | skips-clamp-on-contradictory-bounds | `minimum = 10`, `maximum = 1`; set field text = `"37"` and commit | The view model's value == 37 (stored unclamped) |
| number-field-view-024 | redisplays-committed-text | `minimum = 0`, `maximum = 10`; set field text = `"99"` and commit | The field text changes from `"99"` to `"10"` |
| number-field-view-025 | skips-redundant-commits | View model's value = 5; set field text = `"5"` (same value) and commit | The view model's value is not written a second time (e.g. no additional write/observer notification is recorded) |
| number-field-view-026 | defines-number-parsing-contract | Declare a type conforming to the number value contract that omits the float-allowance flag or the locale-aware parse operation | The declaration does not satisfy the contract, and is rejected wherever the platform enforces it (e.g. at compile time) |
| number-field-view-027 | provides-current-locale-parse | With the active locale set to German (`de_DE`), parse the text `"1.234"` as an integer with no locale argument | Returns `1234` — a result only produced under a German (thousands-grouped) locale reading, showing the omitted-locale form used the active locale rather than, say, `en_US` (under which the same call returns nothing) |
| number-field-view-028 | requires-whole-string-locale-parse | With locale `en_US` and the integer conformance's float-allowance flag false, parse the text `"12abc"` as an integer | Returns nothing (the parser consumes only `"12"`, leaving the range short of the whole string) |
| number-field-view-029 | trims-whitespace-before-parsing-int | Parse the text `" 12 "` as an integer | Returns `12` |
| number-field-view-030 | parses-posix-integer-first | Parse the text `"12"` as an integer with locale `de_DE` | Returns `12` |
| number-field-view-031 | falls-back-to-locale-decimal-for-int | With locale `de_DE`, parse the text `"1.234"` as an integer | The locale-invariant parse of `"1.234"` fails (not a valid integer literal because it contains a decimal point), the locale-aware branch reads it as German thousands-grouped `1234`, and the parse returns `1234` |
| number-field-view-032 | disallows-fractional-values-for-int | Parse the text `"1.0"` and `"1,5"` as integers with locale `de_DE` | Both return nothing |
| number-field-view-033 | rejects-inexact-magnitude-for-int | Parse the text `"99999999999999999999999999"` as an integer | Returns nothing rather than a saturated maximum integer value |
| number-field-view-034 | writes-plain-integer-text | Render the integer `1234` as field text | Returns `"1234"`, with no grouping separators |
| number-field-view-035 | trims-whitespace-before-parsing-double | Parse the text `" 1.5 "` as a floating-point value | Returns `1.5` |
| number-field-view-036 | parses-posix-double-first | Parse the text `"nan"` as a floating-point value | The locale-invariant parse succeeds syntactically but the result is not finite, so the parse returns nothing rather than a NaN value |
| number-field-view-037 | falls-back-to-locale-decimal-for-double | With locale `de_DE`, parse the text `"1,5"` as a floating-point value | The locale-invariant parse of `"1,5"` fails, the locale-aware branch reads it as `1.5`, and the parse returns `1.5` |
| number-field-view-038 | allows-fractional-values-for-double | Parse the text `"1.5"` as a floating-point value | Returns `1.5` |
| number-field-view-039 | writes-whole-doubles-without-fraction | Render the floating-point values `20.0` and `20.5` as field text | Return `"20"` and `"20.5"` respectively |

