
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| path-view-001 | renders-path-non-wrapping-single-line | Construct the view | The label does not wrap its text, is limited to one line, and honors its truncation mode during layout |
| path-view-002 | truncates-middle | Construct the view | The label's truncation mode is set to middle truncation |
| path-view-003 | retains-untruncated-path | Construct with path `"/very/long/path/that/does/not/fit"`, constrain the view to a narrow width, and lay it out | The label's displayed glyphs are visibly truncated (the rendered string differs from the label's full text, e.g. contains an ellipsis), while the view's path property and the label's tooltip remain the full, untruncated string `"/very/long/path/that/does/not/fit"` |
| path-view-004 | prefixes-optional-caption | Construct with path `"/tmp/x"` and caption `"Folder"` | The label's text == `"Folder: /tmp/x"` |
| path-view-005 | omits-caption-when-absent | Construct with path `"/tmp/x"` | The label's text == `"/tmp/x"` |
| path-view-006 | exposes-raw-path-as-tooltip | Construct with path `"/tmp/x"` | The label's tooltip == `"/tmp/x"` |
| path-view-007 | exposes-raw-path-as-tooltip | Construct with path `"/tmp/x"` and caption `"Folder"` | The label's tooltip == `"/tmp/x"` (not `"Folder: /tmp/x"`) |
| path-view-008 | exposes-raw-path-as-accessibility-value | Construct with path `"/tmp/x"` | The label's accessibility value == `"/tmp/x"` |
| path-view-009 | exposes-raw-path-as-accessibility-value | Construct with path `"/tmp/x"` and caption `"Folder"` | The label's accessibility value == `"/tmp/x"` (not `"Folder: /tmp/x"`) |
| path-view-010 | supports-text-selection | Construct the view, then inspect the label | The label is selectable; its text equals the full display string (the caption-prefixed string when a caption is supplied, the path alone otherwise) |
| path-view-011 | yields-width-to-container | Construct the view | The label is permitted to shrink below its natural width rather than forcing its container wider |
| path-view-012 | fills-container-bounds | Construct the view, then lay it out inside a fixed-size superview | The label's resolved frame has zero inset from the view's frame on all four edges |
| path-view-013 | exposes-label-property | Construct the view, then access the label property from outside the type | The property is accessible and returns the same label instance built during construction |
| path-view-014 | exposes-path-property | Construct the view, then access the path property from outside the type | The property is accessible and equals the string passed at construction |
| path-view-015 | styles-as-secondary-caption | Construct the view | The label's font equals the active theme's `.caption` font; the label's text color equals the active theme's `.secondaryText` color |
| path-view-016 | conforms-to-settings-view-protocol | Construct the view | The instance satisfies the settings row interface without a cast |
| path-view-019 | prefixes-optional-caption | Construct with path `"/tmp/x"` and caption `""` | The label's text == `": /tmp/x"` |
| path-view-020 | truncates-middle | Construct with path `"/tmp/x"` and caption `"AVeryLongCaptionThatAloneExceedsTheAvailableWidth"`, then constrain the view narrower than the caption's own rendered width | The displayed, truncated glyphs elide into the caption itself, not only the path portion; the label's truncation mode remains middle truncation |
| path-view-021 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

A UI-test note: verifying that selecting all and copying yields the full
label text on the system clipboard requires platform UI-automation access
and cannot be asserted deterministically in a unit test; cover it in a
UI/integration test suite instead of a conformance vector.

