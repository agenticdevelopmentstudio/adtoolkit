
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-rounding-001 | mode-up | 1s, 15 min, `up` | 900 |
| billing-rounding-002 | mode-up | 901s, 15 min, `up` | 1800 |
| billing-rounding-003 | mode-nearest | 420s, 15 min, `nearest` | 0 |
| billing-rounding-004 | mode-nearest | 450s, 15 min, `nearest` | 900 |
| billing-rounding-005 | non-positive-increment-passthrough | 437s, 0 min, `up` | 437 |
| billing-rounding-006 | non-positive-increment-passthrough | 437s, -5 min, `up` | 437 |
| billing-rounding-007 | non-positive-raw-zero | -5s, 15 min, `up` | 0 |
| billing-rounding-008 | unknown-mode-up | 1s, 15 min, `sideways` | 900 |
| billing-rounding-009 | once-per-entry | five 300s segments rounded each at 15 min `up`, summed | 4500 (the wrong way) |
| billing-rounding-010 | once-per-entry | the same five segments totalled (1500s) then rounded | 1800 |

