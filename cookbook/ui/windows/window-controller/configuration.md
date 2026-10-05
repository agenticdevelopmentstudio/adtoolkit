
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Content view (content wrapper) | Caller-supplied view type | none via the view-supplying construction path; a freshly constructed default instance when built via the parameterless convenience construction path | The strongly-typed view installed as the controller's view during the view-loading step. |
| Typed accessor (window controller) | Caller-supplied content-controller type (optional) | n/a — read-only computed accessor | Typed view of the window's content; absent when the actual content is not an instance of the caller-supplied content-controller type. |

