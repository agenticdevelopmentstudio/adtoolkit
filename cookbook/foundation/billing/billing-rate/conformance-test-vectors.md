
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-rate-001 | claim-exact-branch-first | rows r1 (`/app`, any branch, 9000) and r2 (`/app`, `rush`, 20000); root `/app`, branch `rush` | repo r2, rate 20000 |
| billing-rate-002 | claim-exact-branch-first | same rows; branch `main` | repo r1, rate 9000 |
| billing-rate-003 | rate-ladder | repo with no rate, project default 10000 | 10000 |
| billing-rate-004 | rate-ladder | repo with no rate, project with no default, global 5000 | 5000 |
| billing-rate-005 | rate-ladder | branch row `rush` with no rate, any-branch row with 9000, project default 10000 | 9000 |
| billing-rate-006 | claim-unassigned | root `/elsewhere`, no repos | no repo, no project |
| billing-rate-007 | claim-ignores-billing-flag | repo r1 with billing disabled | project p1, repo r1 |
| billing-rate-008 | rate-zero-is-a-rate | repo rate 0 | 0 |
| billing-rate-009 | claim-missing-project | repo pointing at project `gone`, global 5000 | no project, rate 5000 |

