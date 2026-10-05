
| State | Behavior |
|-------|------------------|
| Default (matching content type) | The typed accessor returns the base's content downcast to the caller-supplied content-controller type |
| Mismatched or absent content controller | The typed accessor returns absent |
| Content wrapper constructed, view not yet loaded | The content-view property already exists (set at construction); the controller's view has not been created yet — the platform's normal lazy view-loading timing applies |
| Content wrapper's view loaded | The controller's view is the content-view property instance |
| Pressed | Not applicable — neither type is an interactive control; the component renders nothing and has no press-state code. |
| Disabled | Not applicable — neither type has an enabled/disabled state of its own. |
| Focused | Not applicable — neither class overrides key-view or first-responder handling. |
| Loading | Not applicable — the typed accessor's cast and the view-loading step's assignment are both synchronous; there is no asynchronous loading state. |

