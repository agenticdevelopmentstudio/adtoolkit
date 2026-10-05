
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| secure-text-edit-view-001 | masks-entry-with-secure-field | Construct the component with any view model | The field is a secure, masking field, not a plain text field |
| secure-text-edit-view-002 | initializes-from-view-model | View model's value is "abc" | After construction the secure field's string value is "abc", displayed masked |
| secure-text-edit-view-003 | commits-value-on-change | User types "s3cret" into the secure field and the field's action fires | The view model's setting observer value is "s3cret" |
| secure-text-edit-view-004 | skips-redundant-commits | The field's action fires while its string equals the view model's current value | The view model's setting observer is not written |
| secure-text-edit-view-005 | syncs-on-external-change | The view model's value changes externally and its change callback fires | The secure field's string value shows the new value |
| secure-text-edit-view-006 | exposes-constituent-views | Read the row's label and text field after construction | The label shows the view model's title and the text field is the secure, masking field |
| secure-text-edit-view-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

All other conformance test vectors — row layout, content-hugging, action
wiring, view-model sync, theme styling, placeholder restyling,
constituent-view exposure, the initializer traps, and UI-thread
confinement — are inherited unmodified from the text edit row; see
`adtoolkit://cookbook/ui/settings/rows/text-edit-view#conformance-test-vectors`.

