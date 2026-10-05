
- **Empty endpoint list**: The options function on an empty list MUST return exactly the four known-platform rows, with no no-platform row (pf-002).
- **All endpoints unwired**: Input where every platform is absent MUST return the four known-platform rows followed by the no-platform row.
- **Empty-string platform**: A platform of `""` is not absent and not in the known-platforms list, so it MUST produce an unknown-platform row with key `""` and label `""`. The logic does not reject or relabel it; the endpoints configuration view sets platform from a fixed selection control, which bounds how such a value could arise.
- **Value equal to the sentinel**: An endpoint whose platform is the literal string equal to the no-platform sentinel MUST be treated as unwired: it produces the no-platform row and no unknown-platform row, because the sentinel check does not distinguish it from an absent platform.
- **Case variants**: `"Vercel"` or `"RAILWAY"` MUST produce separate unknown-platform rows, since matching is case-sensitive (pf-010).
- **Unknown platform under the default selection**: An endpoint with an unknown platform gets a filter row but its key is not in the full set returned by the all-keys function. With the default or "all" selection, a caller filtering by set membership MUST hide it until the operator selects that row (pf-014).
- **Missing platform field**: A platform value that is entirely absent from the record (rather than explicitly `null`) MUST be treated the same as `null` and mapped to the no-platform sentinel.
- **Large input**: Work is linear in the number of endpoints plus a scan of the known-platforms list per distinct value; there is no size limit and no truncation.
- **Concurrent access**: Not applicable. Both functions are synchronous and stateless, and run to completion without yielding, so calls cannot interleave.
- **Error states and offline**: Not applicable. The logic performs no I/O, so there is no dependency to fail and no connectivity to lose.

