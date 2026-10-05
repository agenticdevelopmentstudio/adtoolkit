
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| currency-code-001 | trim-and-uppercase | Normalize ` usd `. | `USD` (test: CurrencyCodeTests in MoneyTotalsTests.swift). |
| currency-code-002 | three-letters | Normalize `EUR`. | `EUR`. |
| currency-code-003 | three-letters | Normalize `U5D`. | Nothing: a digit is not a letter. |
| currency-code-004 | three-letters | Normalize `US` and `EURO`. | Nothing for each: wrong length. |
| currency-code-005 | three-letters | Normalize the empty string. | Nothing. |
| currency-code-006 | shape-only | Normalize `xyz`. | `XYZ`. |

