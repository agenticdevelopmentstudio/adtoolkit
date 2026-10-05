
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| multi-choice-filter-button-001 | builds-fixed-menu-structure | Construct with `label: "Good for"`, `choices: [a, b]` | Menu has exactly 4 items in order: `label` (no action), "Any", a separator, then items titled `a.title` and `b.title` |
| multi-choice-filter-button-002 | sets-choice-tooltip | Choice `a` has `detail: "Runs code"`; choice `b` has `detail: ""` | `a`'s menu item has tooltip "Runs code"; `b`'s menu item has no tooltip set |
| multi-choice-filter-button-003 | clears-selection-on-any | `selection == ["a"]`; invoke the "Any" item's action | `selection == []` |
| multi-choice-filter-button-004 | toggles-choice-on-select | `selection == []`; invoke choice `a`'s item action | `selection == ["a"]` |
| multi-choice-filter-button-005 | toggles-choice-on-select | `selection == ["a"]`; invoke choice `a`'s item action again | `selection == []` |
| multi-choice-filter-button-006 | restricts-selection-to-known-ids | `choices` ids are `["a","b"]`; call the selection-setting operation with `["a","z"]` | `selection == ["a"]`; `"z"` is discarded |
| multi-choice-filter-button-007 | reflects-checkmarks | `selection == []`; invoke choice `a`'s item action | `a`'s menu item is checked; every other choice item is unchecked |
| multi-choice-filter-button-008 | reflects-checkmarks | `selection == ["a"]`; manually set `a`'s menu item to unchecked (simulating drift), then call the selection-setting operation with `["a"]` (no-op value) | `a`'s menu item is resynchronized back to checked by the call |
| multi-choice-filter-button-009 | fires-on-change-on-actual-change | `onChange` recorder attached; `selection == []`; invoke choice `a`'s item action | `onChange` is invoked exactly once with `["a"]` |
| multi-choice-filter-button-010 | fires-on-change-on-actual-change | `onChange` recorder attached; `selection == []`; invoke the "Any" item's action | `onChange` is not invoked |
| multi-choice-filter-button-011 | formats-title-none-selected | `label: "Good for"`, `selection == []` | Button title == `"Good for: Any"` |
| multi-choice-filter-button-012 | formats-title-few-selected | `label: "Good for"`, `choices` titled `["Coding","Writing"]`, both selected | Button title == `"Good for: Coding, Writing"` |
| multi-choice-filter-button-013 | formats-title-many-selected | `label: "Good for"`, 4 of the choices selected | Button title == `"Good for: 4 selected"` |
| multi-choice-filter-button-014 | refreshes-title-synchronously | Invoke choice `a`'s item action | The button's displayed title already matches `"<label>: a.title"` immediately after the call returns, with no further user action needed to refresh it |
| multi-choice-filter-button-015 | resizes-for-longer-titles | Selection goes from 0 choices ("Any") to 2 choices with long titles | The button's measured width after the change is wide enough to display the new title without truncation, and is greater than it was before the change |
| multi-choice-filter-button-016 | exposes-readonly-selection | From outside the type, attempt to assign to `selection` directly | Rejected — `selection` has no externally accessible setter; only the selection-setting operation may change it (enforced at compile time where the language supports it; see Platform Notes) |
| multi-choice-filter-button-017 | themes-text-appearance | Construct the button, then post a theme-change notification with a new theme | The foreground tint color and font update to the new theme's corresponding values without re-constructing the button |
| multi-choice-filter-button-021 | label-and-any-never-checked | Construct with `choices: [a, b]`; invoke choice `a`'s item action | Item 0 and the "Any" item remain unchecked; only `a`'s item is checked |
| multi-choice-filter-button-022 | initializes-selection-empty | Construct the button; check `selection` immediately, before any interaction | `selection == []` |
| multi-choice-filter-button-023 | rejects-coder-initialization | Attempt to construct the control from a serialized or archived representation | Construction is refused as a programmer error and terminates; no instance is produced. Verified by inspection only, since the refusal cannot be caught. |
| multi-choice-filter-button-024 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| multi-choice-filter-button-025 | disables-autoresizing-mask-translation | Inspect the control's implicit frame-to-constraint translation after construction | Translation is disabled, so only explicit constraints position the control. |
| multi-choice-filter-button-026 | contrast | Construct the button under a theme whose primary text color is close to its bezel color | The foreground tint equals the theme's primary text color; no contrast adjustment is applied. |

`rejects-coder-initialization`, `confines-to-ui-thread` and `disables-autoresizing-mask-translation` are vectors 023, 024 and 025; the first two are verified by inspection only (see Platform Notes).

