
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-picker-view-001 | composes-theme-choice-popup | Construct the component with a given theme store | A choice control is among the component's descendant views, built from a theme-choice view model derived from that store |
| theme-picker-view-002 | composes-theme-preview | Construct the component | A theme preview is among the component's descendant views |
| theme-picker-view-003 | stacks-popup-above-preview | Construct the component | The choice control and the preview are arranged, in that order, top-to-bottom, inside one leading-aligned vertical stack with 10pt spacing |
| theme-picker-view-004 | pins-stack-to-view-edges | Construct the component | The stack's top/leading/trailing/bottom edges equal the component's own edges with a 0pt constant |
| theme-picker-view-005 | derives-choices-from-injected-store | Store's themes are `[{id: "a", name: "Alpha"}, {id: "b", name: "Beta"}]` | The control's choices are `[{label: "Alpha", value: "a"}, {label: "Beta", value: "b"}]` and its title is "Theme" |
| theme-picker-view-006 | defaults-to-the-persisted-theme-store | Construct the component with no theme-store argument | The control's choices equal the built-in themes followed by the persisted custom themes (in that order), each mapped to a label/value pair — the same composition the default theme store computes |
| theme-picker-view-007 | renders-initial-preview-synchronously | Construct the component | Immediately after construction, the preview's contents are already non-empty and reflect the current palette's theme — no further call is needed |
| theme-picker-view-008 | resyncs-preview-on-theme-change | Post the theme-change notification after construction | The preview is shown again with the newly current palette's theme |
| theme-picker-view-009 | resyncs-preview-on-matching-scope-change | Post a theme-scope change notification for the exact scope instance the view's own resolved scope returns | The preview is shown again |
| theme-picker-view-010 | ignores-non-matching-scope-change | Post a theme-scope change notification for a scope instance other than the one the view's resolved scope returns | The preview is NOT shown again as a result of that notification |
| theme-picker-view-011 | commits-selection-through-the-active-theme-setting | Select a different item in the choice control | The active-theme setting's value equals the selected item's represented theme id |
| theme-picker-view-012 | decouples-preview-refresh-from-selection-commit | Select a different item in the choice control | No call from the control's selection handler shows anything in the preview directly; the preview is refreshed only by a palette-observing subscription firing |
| theme-picker-view-013 | keeps-constituent-views-private | Attempt to access the choice control, the preview, or the observer from outside the component | Each access is rejected; no public API exposes any of the three |
| theme-picker-view-014 | retains-the-palette-observer-for-its-lifetime | Construct the component, retain it, then post the theme-change notification | The preview still re-renders (the subscription has not been released while the view is retained) |
| theme-picker-view-015 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

