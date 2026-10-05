
**Decision**: The mode is a free-form string rather than an enum at this boundary.
**Rationale**: The stored setting and the wire carry a string; a typed enum would reject older values. Unknown values fall back to `up`; tightening this would need a settings migration.
**Approved**: pending

