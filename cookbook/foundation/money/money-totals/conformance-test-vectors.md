
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-totals-001 | add-amount, never-mixed | Add 100 hundredths `USD`, 50 `USD` and 200 `EUR`. | USD bucket 150, EUR bucket 200 (test: testKeepsEachCurrencyApart). |
| money-totals-002 | add-totals | Merge a totals holding `USD` 100 into one holding `USD` 50 and `EUR` 20. | `USD` 150, `EUR` 20 (test: testAddingAnotherTotalMergesItsBuckets). |
| money-totals-003 | description-wording, sorted-currencies | Totals of 25,000 `USD` and 4,000 `EUR`, described with the current locale en_US (the description builds each formatter with the default locale). | `€40.00 + $250.00`: the currencies in code order, `EUR` before `USD`, formatted separately (test: testTheDescriptionJoinsEachCurrencyInCodeOrder). |
| money-totals-004 | is-empty, description-wording | Create an empty totals value. | It is empty and its description is the empty string. |
| money-totals-005 | add-sequence | Construct from `[Money(100, USD), Money(250, EUR)]`. | Two buckets; amounts in code order `EUR`, `USD`. |
| money-totals-006 | value-equality | Compare two totals built from the same amounts in different order. | Equal. |

