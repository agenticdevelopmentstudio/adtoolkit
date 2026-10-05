
Vector 001 is traced to the assertions in the module's own test suite ("includes dns as a first-class source with a label"). Vector 002 is traced to the row-building logic's test suite (the `cloudflare-pages` source-filter regression). The rest are traced to the module's declarations. Three additional checks — that the vocabulary is closed to unlisted strings, that removing a label from the map is rejected, and that the guard narrows a plain string to the vocabulary type in a typed caller — are compile-time checks specific to the reference implementation's type system; they are recorded in Platform Notes rather than here, since they have no runtime-observable input or output.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| issue-sources-001 | order-members, label-non-empty, label-values | Whether `"dns"` is a member of the source order list; the source label map's `dns` entry; every entry in the source label map | `true`; `"DNS"`; every value non-empty |
| issue-sources-002 | source-spelling, guard-true | The issue-source guard operation on `"cloudflare-pages"`; whether `"cloudflare-pages"` is a member of the source order list | `true`; `true` |
| issue-sources-003 | order-canonical, order-members | Read the source order list | `["dns", "http", "glitchtip", "vercel", "cloudflare-pages", "railway", "crunchy"]`, length 7 |
| issue-sources-004 | label-values, label-map-total | Read every entry of the source label map | Exactly seven pairs: dns/"DNS", http/"HTTP", glitchtip/"GlitchTip", vercel/"Vercel", cloudflare-pages/"Cloudflare", railway/"Railway", crunchy/"Crunchy Bridge" |
| issue-sources-005 | guard-true, guard-order-source | The issue-source guard operation on each member of the source order list | `true` for all seven |
| issue-sources-006 | guard-false, source-spelling | The issue-source guard operation on `"cloudflare"` | `false` |
| issue-sources-007 | guard-false, guard-no-normalization | The issue-source guard operation on `"DNS"`; on `" http"`; on `"http "` | `false` for all three |
| issue-sources-008 | guard-false, guard-no-throw | The issue-source guard operation on `""`; on `"deploy"` | `false`, `false`; no exception |
| issue-sources-010 | label-unguarded-index | Looking up the source label map with `"netlify"` | No result |
| issue-sources-013 | stuck-threshold-value | Read the stuck-deploy threshold | `1800000` |
| issue-sources-014 | mirror-union, mirror-labels, mirror-order, stuck-threshold-mirror | Compare the client's exports with the server's issue-source vocabulary, source label map and stuck-deploy threshold | Equal in order; label maps equal; thresholds equal |
| issue-sources-015 | stuck-not-client-derived | Search the client's source tree for readers of the stuck-deploy threshold outside this module | None found |

