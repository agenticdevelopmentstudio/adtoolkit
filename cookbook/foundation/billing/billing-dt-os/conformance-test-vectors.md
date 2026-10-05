
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-dt-os-001 | three-statuses | status unbilled, billed, paid | next is billed, paid, nil |
| billing-dt-os-002 | three-statuses | status billed | locks the entry |
| billing-dt-os-003 | three-statuses | status unbilled | does not lock |
| billing-dt-os-004 | segment-origin | segment with empty end | running |
| billing-dt-os-005 | segment-origin | segment origin `manual` | manual |
| billing-dt-os-006 | overview-per-currency | USD and EUR entries | two currency rows; top-level buckets equal the first row |
| billing-dt-os-007 | overview-compat | overview JSON without by_currency | decodes with an empty list |
| billing-dt-os-008 | wire-sentinels | failed list read | `{"billing_read_failed":true}` |
| billing-dt-os-009 | settings-keys | prefix `app_billing_` | idle key `app_billing_idle_cutoff_minutes`; allow-list of 8 |
| billing-dt-os-010 | limits | clamp 9999 to the idle range | 480 |
| billing-dt-os-011 | limits | clamp 0 to the rounding range | 1 |
| billing-dt-os-012 | defaults | no configuration | rounding 15, mode up, currency USD |
| billing-dt-os-013 | refusal-sentences | claim of `/r` on no branch | "/r (any branch) already belongs to another project." |
| billing-dt-os-014 | entry-snapshot | encode then decode an entry as snake_case JSON | equal to the original |

