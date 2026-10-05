
**Decision**: An unknown zone buckets as UTC instead of failing.
**Rationale**: Failing would drop the row from the rollup, and falling back to the host zone would make the answer depend on the reader; UTC is stable. Surfacing an unknown zone as an error would need a result type at every call site.
**Approved**: pending

