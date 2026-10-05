
Not applicable: no part of this component calls a console/log API directly.
The only diagnostic path is the failure-reporting call inside the
resource-item/resource-list read states, which delegates to the sink the
Auth Client recipe's own Logging section documents, not duplicated here.

