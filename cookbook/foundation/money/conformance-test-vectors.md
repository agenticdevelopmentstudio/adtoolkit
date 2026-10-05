
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-001 | amount-from-seconds | 3600 seconds at a rate of 12,500. | 12,500 (test: testAmountCentsIsExactForWholeHours). |
| money-002 | amount-from-seconds | 900 seconds at a rate of 12,500. | 3,125 (test: testAmountCentsForAQuarterHour). |
| money-003 | amount-from-seconds | 1800 seconds at a rate of 1, then 1799 seconds at a rate of 1. | 1, then 0: half-up at the boundary (test: testAmountCentsRoundsHalfUp). |
| money-004 | amount-sign-preserved | 3600 seconds at a rate of -12,500; 1800 seconds at a rate of -1. | -12,500 and -1 (test: testAmountCentsPreservesNegativeRateSign). |
| money-005 | amount-zero-guards | 0 seconds, then -60 seconds, at 12,500; and 86,400 seconds at rate 0. | Each returns 0. |
| money-006 | sum-of-list | Sum an empty list in `EUR`. | Zero hundredths in `EUR` (test: testSumOfNothingIsZero). |
| money-007 | add-subtract, ordering | 100 minus 300 in `USD`; 99 compared with 100. | -200; 99 is less than 100. |
| money-008 | same-currency-test | Compare `USD` with `USD` and `USD` with `EUR`. | True, then false (test: testMixedCurrenciesAreNotTheSameCurrency). |
| money-009 | mixed-currency-is-programmer-error | Add 1 `USD` to 1 `EUR`. | Fails as a programmer error. |

