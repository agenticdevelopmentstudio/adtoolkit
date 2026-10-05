
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| spvc-003 | descriptor | Attempt to assign a new descriptor to an existing instance after construction | Rejected — the descriptor is immutable after construction |
| spvc-004 | default-descriptor | Construct the component with no descriptor argument | Its descriptor is a freshly constructed default descriptor with an empty title |
| spvc-005 | descriptor-retention | Construct the component with a given descriptor | The component's descriptor is that exact same instance, not a copy |
| spvc-007 | root-view | Trigger the component's view-loading step | The component's view is its own content view, which is a panel view |
| spvc-008 | add-group | Call the component's add-group method with a given group | That group becomes the last item in the content view's stack |
| spvc-009 | help-content-default | Read the help content on a plain, non-overriding instance | Returns none |
| spvc-010 | effective-help-content | Read the effective help content on a plain, non-overriding instance whose help content is none | Returns none; on a subclass instance overriding help content to a non-empty value, returns that same value |
| spvc-011 | hosts-own-scroll-default | Read the hosts-own-scroll flag on a plain, non-overriding instance | Returns false |
| spvc-012 | search-keywords-default | Read the search keywords on a plain, non-overriding instance | Returns an empty list |
| spvc-013 | subclass-default-override-visibility | Subclass the component, override the hosts-own-scroll default to return true, then access the instance through the generic panel interface the hosting split holds | The generic reference's hosts-own-scroll reads true (the subclass override), not the shared default's false |
| spvc-014 | hosting-view-helper | Call the component's hosting helper with some content | Returns a wrapper view containing the given content |
| spvc-015 | hosting-view-sizing-options | Call the hosting helper with some content, inspect the returned wrapper's sizing behavior | The wrapper advertises the content's size as a preference, not a required min/max constraint |
| spvc-016 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

