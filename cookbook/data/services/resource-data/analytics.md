
Not applicable: no part of this component emits a client-side analytics or
product-telemetry event. The failure-reporting calls in the
resource-item/resource-list read states send operational error diagnostics
to the same injected sink the Auth Client recipe's own Logging section
documents — failure telemetry, not product-analytics events.

