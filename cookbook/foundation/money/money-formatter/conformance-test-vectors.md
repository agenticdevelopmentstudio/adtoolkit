
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-formatter-001 | display-two-fraction-digits | Format 0, 3,125 and 123,456,789 hundredths in an en_US `USD` formatter. | `$0.00`, `$31.25`, `$1,234,567.89` (test: testFormatterRendersIntegerCents). |
| money-formatter-002 | editable-string | Editable string for 3,125 and 123,456,789. | `31.25` and `1234567.89` (test: testEditableStringHasNoSymbolAndNoGrouping). |
| money-formatter-003 | parse-accepts-pasted-text | Parse `150`, `150.5`, `$1,250.00`, ` 31.25 ` in en_US. | 15,000; 15,050; 125,000; 3,125 (test: testParsingAcceptsWhatPeopleActuallyType). |
| money-formatter-004 | parse-half-up | Parse `150.555` and `150.554`. | 15,056 and 15,055 (test: testParsingRoundsHalfUpRatherThanTruncating). |
| money-formatter-005 | parse-single-separator | In en_US parse `150,50` and `1,250`; in de_DE parse `150.50` and `1.250`. | 15,050 and 125,000; 15,050 and 125,000 (tests: testACommaDecimalIsHonouredInAnEnglishLocale, testADotDecimalIsHonouredInAGermanLocale). |
| money-formatter-006 | parse-ambiguous-refused | In fr_FR parse `1.250` and `1.25`. | Nothing, then 125 (test: testAnAmbiguousSeparatorIsRefused). |
| money-formatter-007 | parse-both-separators | In de_DE parse `1.250,00`; in en_US parse `1,250.00`. | 125,000 for each. |
| money-formatter-008 | parse-grouping-in-threes, parse-repeated-separator-groups | In en_US parse `1.2.5`, `15..50`, `12,34,567`, `1,250.00.5`. | Nothing for each (test: testMalformedAmountsAreRefused). |
| money-formatter-009 | parse-sign | Parse `\u22125` and `-5`. | -500 for each (test: testUnicodeMinusIsNegative). |
| money-formatter-010 | parse-no-digits-refused | Parse the empty string, `-` and `$`. | Nothing for each (test: testParsingRejectsTextWithNoDigits). |
| money-formatter-011 | parse-overflow-refused | Parse `99999999999999999999`. | Nothing (test: testAnOverflowingAmountIsRefused). |

