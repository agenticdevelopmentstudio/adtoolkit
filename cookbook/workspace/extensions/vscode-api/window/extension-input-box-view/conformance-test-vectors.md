
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| extension-input-box-view-controller-001 | optional-title-label | `model.request.title = "Enter API Key"` | The title is displayed, in the `primaryText` role and `heading` text role, with text `"Enter API Key"` |
| extension-input-box-view-controller-002 | optional-title-label | `model.request.title = nil` (and, separately, `= ""`) | No title is displayed |
| extension-input-box-view-controller-003 | optional-prompt-label | `model.request.prompt = "Used only for this session."` | The prompt is displayed, in the `secondaryText` role and `caption` text role, with matching text |
| extension-input-box-view-controller-004 | optional-prompt-label | `model.request.prompt = nil` | No prompt is displayed |
| extension-input-box-view-controller-005 | secure-field-selection | Construct with `model.request.isPassword = true` | The field is constructed as a secure (masked) field |
| extension-input-box-view-controller-006 | secure-field-selection | Construct with `model.request.isPassword = false` | The field is constructed as a plain (unmasked) field |
| extension-input-box-view-controller-007 | field-placeholder-seed | `model.request.placeHolder = "org/repo"` | The field's placeholder text is `"org/repo"` once the view loads |
| extension-input-box-view-controller-008 | field-placeholder-seed | `model.request.placeHolder = nil` | The field's placeholder text is empty once the view loads |
| extension-input-box-view-controller-009 | initial-field-value | `model.value = "prefilled"` | Once the view loads, the field's text is `"prefilled"` |
| extension-input-box-view-controller-010 | prefill-validation-once | The view appears twice in succession on a fresh component instance | `model.beginValidating()`/`onValueChanged(model.value)` fire exactly once, on the first appearance only |
| extension-input-box-view-controller-011 | value-commit-and-revalidation | Set the field's text to `"abc"` | `model.value == "abc"`; `model.isValidating == true`; `onValueChanged` is invoked once with `"abc"` |
| extension-input-box-view-controller-012 | pending-acceptance-reset, acceptance-deferral | `model.isValidating == true`; press Return (deferring acceptance); then change the field's text (an edit); then supply a validation that makes `model.canAccept == true` | `onAccept` is not invoked — the edit discarded the held Return before validation landed |
| extension-input-box-view-controller-013 | model-gated-acceptance | `model.canAccept == true`; press Return | `onAccept` is invoked exactly once, with `model.value` |
| extension-input-box-view-controller-014 | model-gated-acceptance | `model.canAccept == false`; press Return | `onAccept` is not invoked |
| extension-input-box-view-controller-015 | acceptance-deferral | `model.isValidating == true`; press Return; then supply a `nil` validation result, which clears `model.isValidating` and makes `model.canAccept == true` | `onAccept(model.value)` is not invoked on the Return press itself; it fires exactly once, once that validation result lands |
| extension-input-box-view-controller-016 | return-drop-under-error | `model.isValidating == false`, `model.canAccept == false` (standing error); press Return | `onAccept` is not invoked, and a validation that subsequently lands with `model.canAccept == true` does not retroactively invoke it either — the Return was dropped, not deferred |
| extension-input-box-view-controller-017 | escape-cancellation | With the component on screen and its window active, press Escape in that window | `onCancel()` is invoked exactly once |
| extension-input-box-view-controller-018 | validation-message-shown | Supply a validation of message `"Required"`, severity error | The validation message is shown, with text `"Required"` and color role `danger` |
| extension-input-box-view-controller-019 | validation-message-shown | Supply a validation of message `"Heads up"`, severity warning (and, separately, information) | Color role is `warning` for warning severity (and `secondaryText` for information severity) |
| extension-input-box-view-controller-020 | validation-message-hidden | Supply a `nil` validation result | The validation message is hidden |
| extension-input-box-view-controller-021 | focus-then-initial-selection | Call `focusField()` with `model.initialSelectionUTF16Range()` resolving to a selection starting at position 2, length 3 | The field has keyboard focus, and its text selection starts at position 2, length 3 |
| extension-input-box-view-controller-022 | panel-size-from-fitted-layout | Load the view with content whose fitted content height is 40pt (below the 72pt floor) | The panel's preferred size is 480×72 |
| extension-input-box-view-controller-023 | panel-size-from-fitted-layout | Load the view with content whose fitted content height is 160pt | The panel's preferred size is 480×160 |
| extension-input-box-view-controller-024 | model-gated-acceptance | `model.value == ""`, `model.canAccept == true`; press Return | `onAccept("")` is invoked exactly once — an empty value is still accepted, not treated as nothing entered |
| extension-input-box-view-controller-025 | escape-cancellation | With the component on screen, press Escape in a window that is not the component's window | `onCancel()` is not invoked |
| extension-input-box-view-controller-026 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

