
Not applicable: no part of this domain authors a user-facing string of any kind — every thrown
error originates from the shared authenticated request client (owned by the shared auth client),
and every value these operations return either passes a backend response through unchanged or is
a non-string type. This differs from this cookbook's sibling Access recipe, whose list-features
operation does author one hardcoded English validation message; this component has no equivalent
code path.

