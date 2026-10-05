
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-host-view-001 | replaces-content-on-set | Call the set-content operation with view A, then with view B | After the second call, view A is no longer a child of the content container; only view B is |
| panel-host-view-002 | clears-content-on-nil | Call the set-content operation with view A, then with no view | The content container has zero children after the second call |
| panel-host-view-003 | content-pinned-to-container-edges | Call the set-content operation with view A | View A's top/leading/trailing/bottom edges are each constrained equal to the content container's corresponding edge with zero constant |
| panel-host-view-004 | content-container-pinned-to-view-edges | Construct the component | The content container's top/leading/trailing/bottom edges are each constrained equal to the component's corresponding edge with zero constant |
| panel-host-view-005 | help-button-inset-from-content-container | Construct the component | The help button's top edge equals the content container's top edge + 12; its trailing edge equals the content container's trailing edge − 12 |
| panel-host-view-006 | help-button-above-content | Construct the component, then call the set-content operation with view A | The help button remains a child of the component (not of the content container) both before and after the call, and is not removed or reordered by it |
| panel-host-view-007 | help-button-visibility | Turn the show-help-button setting off with a help presenter assigned | The help button is hidden |
| panel-host-view-008 | help-button-visibility | Clear the help presenter with the show-help-button setting on | The help button is hidden |
| panel-host-view-009 | help-button-visibility | Turn the show-help-button setting on and assign a help presenter | The help button is visible |
| panel-host-view-010 | help-button-icon-reflects-visibility | Assign a presenter stub whose help-visible value is true | The help button's icon is the filled question-mark variant |
| panel-host-view-011 | help-button-icon-reflects-visibility | Assign a presenter whose help-visible value is false | The help button's icon is the outlined question-mark variant |
| panel-host-view-012 | help-button-symbol-configuration | Construct the component | The icon's rendering configuration reports point size 15 and weight regular |
| panel-host-view-013 | help-button-tint-reflects-visibility | Presenter reports help-visible as true while the active theme is "Solarized Dark" | The help button's tint color equals Solarized Dark's accent-color role |
| panel-host-view-014 | help-button-tint-reflects-visibility | Presenter reports help-visible as false while the active theme is "Solarized Dark" | The help button's tint color equals Solarized Dark's secondary-text-color role |
| panel-host-view-015 | help-button-tooltip-reflects-visibility | Presenter reports help-visible as true | The help button's tooltip reads "Hide Help" |
| panel-host-view-016 | help-button-tooltip-reflects-visibility | Presenter reports help-visible as false | The help button's tooltip reads "Show Help" |
| panel-host-view-017 | help-button-accessibility-label-fixed | Toggle help visible, then hidden | The help button's accessibility label reads "Help" in both states |
| panel-host-view-018 | help-button-borderless-image-only | Construct the component | The help button has no border, and shows only its icon, with no text label |
| panel-host-view-019 | help-button-momentary-type | Construct the component | The help button's activation model is momentary — it fires once per click and holds no on/off state |
| panel-host-view-020 | toggle-help-delegates-to-presenter | Assign a presenter, then invoke the toggle-help operation | The presenter's own toggle-help operation is invoked exactly once |
| panel-host-view-021 | toggle-help-delegates-to-presenter | With no help presenter assigned, invoke the toggle-help operation | No presenter method is invoked and no error occurs |
| panel-host-view-022 | help-anchor-claimed-when-button-shown | With the show-help-button setting on, assign a presenter | The presenter's anchor view is the help button |
| panel-host-view-023 | help-anchor-untouched-when-button-hidden | With the show-help-button setting off, assign a presenter whose anchor view was previously set to some other view | The presenter's anchor view is unchanged by the assignment |
| panel-host-view-024 | help-visibility-change-refreshes-button | With a presenter assigned, invoke the presenter's own visibility-change notification | The help button's icon/tint/tooltip are re-evaluated against the presenter's current help-visible value |
| panel-host-view-025 | help-visibility-change-notifies-external-observer | With an external visibility-change notification set, invoke the presenter's own visibility-change notification | The external notification is invoked exactly once, after the button refresh |
| panel-host-view-026 | presenter-reassignment | Call the set-help operation with content A, then assign a new help presenter | The new presenter receives the set-help operation with content A, its anchor view is claimed (if shown), and its visibility-change notification is this component's own callback |
| panel-host-view-027 | set-help-forwards-to-presenter | With a presenter assigned, call the set-help operation with no content | The presenter receives the set-help operation with no content and the help button is refreshed |
| panel-host-view-028 | is-help-visible-reflects-presenter-or-false | Query the help-visible value with no help presenter assigned | Returns false |
| panel-host-view-029 | is-help-visible-reflects-presenter-or-false | Query the help-visible value with a presenter whose own help-visible value is true | Returns true |
| panel-host-view-030 | shows-help-button-toggle | Toggle the show-help-button setting from off to on with a presenter assigned | The presenter's anchor view is claimed and the help button's hidden/icon/tint state is refreshed |
| panel-host-view-031 | theme-change-refreshes-button-tint | With help visible while the active theme is "Solarized Dark", switch the active theme to "Solarized Light" | The help button's tint color updates to Solarized Light's accent-color role without reconstructing the view |
| panel-host-view-032 | rejects-deserializing-construction | Attempt to construct the component via a deserializing/decoding-based construction path | The call traps or fails; no instance is returned |
| panel-host-view-033 | constraint-based-layout-only | Inspect the component, its content container, and its help button after construction | Each of the three relies solely on the layout-constraint system, with no manual frame assignment |
| panel-host-view-034 | help-button-keyboard-focusable | Construct the component, Tab focus to the visible help button, then press Space | The help button receives keyboard focus via Tab/Shift-Tab and its action fires on Space/Return, using the platform's own unmodified default focus and activation handling |
| panel-host-view-035 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

