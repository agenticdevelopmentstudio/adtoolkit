
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| quick-look-preview-001 | wraps-native-preview-control | Embed the component, given a file location, in a view hierarchy | It renders as the platform's native file-preview control, wrapped inline in the tree |
| quick-look-preview-002 | requires-preview-url | Attempt to construct the component with no file-location argument | Construction fails; the file location has no default value and is not optional |
| quick-look-preview-003 | constructs-preview-view-with-normal-style | Construct the component in an environment where the native control's full-featured-style construction succeeds | The component returns a native preview control constructed at its full-featured ("normal") style |
| quick-look-preview-004 | falls-back-to-default-style-when-unavailable | Code inspection (not runtime-exercisable: nothing in this codebase lets a test make the full-featured-style construction fail) | Per source, if that construction failed, the component would construct the control at its default style instead, without crashing |
| quick-look-preview-005 | enables-autostart | Inspect the native preview control returned by the component | Its autostart setting is enabled |
| quick-look-preview-006 | sets-initial-preview-item | Construct the component with a given file location | The native preview control's preview target equals that file location immediately after construction |
| quick-look-preview-007 | skips-redundant-preview-item-updates | Update the component with the same file location the control's preview target already holds | The preview target is the same value after the update as before it (its setter is not invoked), verifiable via an identity comparison or a spy on the setter |
| quick-look-preview-008 | updates-preview-item-on-url-change | Update the component with a file location different from the control's current preview target | The preview target is reassigned to the new file location |
| quick-look-preview-009 | closes-preview-view-on-dismantle | The component is removed from the view hierarchy | The native preview control's preview-generation resources are released |

