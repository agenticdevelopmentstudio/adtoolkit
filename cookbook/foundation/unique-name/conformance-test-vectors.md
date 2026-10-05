
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| unique-name-001 | base-if-free | Base `New Project` with taken names `[]`. | `New Project` (test: testSkipsEveryTakenSuffix, with base `New Client`). |
| unique-name-002 | numbered-suffix | Base `New Project` with taken `["New Project"]`. | `New Project 2` (test: testSkipsEveryTakenSuffix, with base `New Client`). |
| unique-name-003 | skips-every-taken-suffix | Base `New Project` with taken `["New Project", "New Project 2", "New Project 3"]`. | `New Project 4` (test: testSkipsEveryTakenSuffix, with base `misc`). |
| unique-name-004 | skips-every-taken-suffix | Base `X` with taken `["X", "X 3"]`. | `X 2`: the smallest free suffix, not the next after the largest. |
| unique-name-005 | collides-folds | Check `"  alpha "` against taken `["Alpha"]`. | A collision (test: testCollisionIgnoresCaseAndSurroundingWhitespace, with `"acme "` against `["Acme"]`). |
| unique-name-006 | collides-folds | Check `"beta"` against taken `["Alpha"]`. | No collision (test: testCollisionIgnoresCaseAndSurroundingWhitespace covers a non-matching name). |
| unique-name-007 | next-compares-exactly | Base `New project` with taken `["New Project"]`. | `New project`: the exact comparison treats them as different names. |

