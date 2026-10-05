
Not applicable: the component returns only numbers (or `null`) and one of three fixed health status string literals (`"healthy"`, `"degraded"`, `"down"`) — internal status codes, not natural-language, end-user-facing text; it defines no localizable string of its own. Any user-facing label derived from these values is the caller's responsibility, outside this component.

