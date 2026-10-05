
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| increment-rounding-001 | upward | Round 1 second to a 900-second increment, upward. | 900 (test: testUpwardAlwaysTakesTheNextIncrement). |
| increment-rounding-002 | upward | Round 900 to a 900 increment, upward. | 900. |
| increment-rounding-003 | nearest-half-up | Round 450 to a 900 increment, nearest. | 900: the half goes up. |
| increment-rounding-004 | nearest-half-up | Round 449 to a 900 increment, nearest. | 0 (test: testNearestRoundsHalfUp). |
| increment-rounding-005 | zero-increment-passes | Round 1234 with an increment of 0, then of -5. | 1234 each time (test: testNoIncrementMeansNoRoundingAndNothingStaysNothing). |
| increment-rounding-006 | nonpositive-value-is-zero, value-guard-first | Round 0 and -10 with increment 900, and 0 with increment 0. | 0 in every case. |
| increment-rounding-007 | modes | Read the raw values of the two modes. | `up` and `nearest`. |

