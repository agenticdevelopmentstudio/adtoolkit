
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| money-field-view-001 | parses-an-amount-in-range | Parse 150 with range 0 to 100000 cents in US dollars | 15000 cents |
| money-field-view-002 | trims-whitespace | Parse ' 1.5 ' | 150 cents |
| money-field-view-003 | refuses-unparseable-text | Parse abc | Refused |
| money-field-view-004 | refuses-out-of-range | Parse 5000 with range 0 to 100000 cents | Refused |
| money-field-view-005 | blank-means-fallback-when-allowed | Parse whitespace with blanks allowed, then a blank without | An accepted blank, then a refusal |
| money-field-view-006 | shows-the-stored-amount | Store 12000 cents and build the row | The field shows the formatted amount |
| money-field-view-007 | placeholder-shows-the-fallback | Set a placeholder of 9000 cents and clear the stored value then refresh | The field is empty and its placeholder is the formatted fallback |
| money-field-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

