
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| slider-view-001 | arranges-row-layout | Construct the component with any view model | The row's arranged elements are exactly the label, an inserted row-spacer, and the slider, in that order; that row container is the component's only child and is pinned to its edges; no other layout container appears |
| slider-view-002 | sets-slider-range | The view model's minValue = 0, maxValue = 1 | After construction, the slider's minimum is 0 and its maximum is 1 |
| slider-view-003 | slider-hugs-loosely | Construct the component | After construction, the slider's horizontal content-hugging priority is 1 |
| slider-view-004 | initializes-from-view-model | The view model's title = "Volume", value = 42 | After construction, the label reads "Volume" and the slider's value is 42 |
| slider-view-005 | commits-slider-value | The view model's value = 10; set the slider's value to 30 and trigger its change notification | The view model's value is 30 after the call |
| slider-view-006 | skips-redundant-commits | Substitute a counting observer test double whose value setter increments a write counter; set its value to 50, reset the counter to 0, then set the slider's value to 50 (same value) and trigger its change notification | The counting observer's write counter stays at 0 after the call |
| slider-view-007 | syncs-on-external-change | After construction, externally change the view model's title, minValue, maxValue, and value, then trigger the view model's change notification | The label and the slider's minimum, maximum, and value all update to reflect the new view-model state |
| slider-view-008 | exposes-constituent-views | Construct the component, then access its label and slider from outside the type | Both properties are accessible and return the same label/slider instances built during construction |
| slider-view-011 | syncs-on-external-change | Change the value on the backing setting that the view model observes (not by triggering the view model's change notification directly), then await one main-queue turn (the dispatch hop between the setting's storage and the view model's observer) | The label and the slider's minimum, maximum, and value are unchanged immediately after the setting write, and only update to reflect the new state after that main-queue turn elapses |
| slider-view-012 | sets-slider-range | Construct the component with the view model's minValue = 10, maxValue = 0 (an inverted range; a zero-width case such as minValue = maxValue = 5 is equivalent) | The slider's minimum is 10 and its maximum is 0 — assigned unchanged from the view model, with no clamping, swapping, or correction |
| slider-view-013 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

