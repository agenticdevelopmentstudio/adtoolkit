
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-editing-001 | replacing-keeps-unnamed | client `replacing(name: "New")` | only the name differs |
| billing-editing-002 | replacing-clears-nullable | project with a rate, `replacing(defaultRateCents: .some(nil))` | rate is nil |
| billing-editing-003 | replacing-clears-nullable | same project, `replacing()` | rate unchanged |
| billing-editing-004 | repriced-amount | entry 3000 raw seconds, `repriced(billedSeconds: 5400, rateCents: 12000)` | amount 18000 cents; raw seconds 3000 |
| billing-editing-005 | rate-parse | `" 150.00 "` | 15000 |
| billing-editing-006 | rate-parse | `"abc"` | nil |
| billing-editing-007 | rate-parse | a value above 100,000.00 | nil |
| billing-editing-008 | title-fallback | `"Acme"` then `"  "` | `Acme` then `Untitled` |
| billing-editing-009 | labels-disambiguate | projects Site (Acme), Site (Beta), Site (Beta, other id), Other (no client) | `Site — Acme`, `Site — Beta — p2bbbb`, `Site — Beta — p3cccc`, `Other` |

