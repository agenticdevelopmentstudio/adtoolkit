
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-clock-001 | local-day-in-zone | `2026-09-23T04:30:00Z`, `America/Los_Angeles` | `2026-09-22` |
| billing-clock-002 | local-day-in-zone | `2026-09-23T04:30:00Z`, `Europe/Berlin` | `2026-09-23` |
| billing-clock-003 | zone-fallback-utc | `2026-09-23T04:30:00Z`, empty zone | `2026-09-23` |
| billing-clock-004 | zone-fallback-utc | `2026-09-23T04:30:00Z`, `Mars/Olympus` | `2026-09-23` |
| billing-clock-005 | unparseable-instant-empty | `not-a-date`, `UTC` | empty string |

