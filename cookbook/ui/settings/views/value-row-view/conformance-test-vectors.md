
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| value-row-view-001 | shows-title-and-value | Build with title Version and value 1.2.3 | The title reads Version and the value reads 1.2.3 |
| value-row-view-002 | value-is-settable | Assign 2.0 to the value property | The shown text and the property both read 2.0 |
| value-row-view-003 | value-is-selectable | Inspect the value text | It is selectable and not editable |
| value-row-view-004 | value-is-labelled-by-title | Read the value's accessibility label | It equals the title |
| value-row-view-005 | value-uses-monospaced-digits | Inspect the value's font | Its digits are monospaced |
| value-row-view-006 | value-is-right-aligned | Inspect the value's alignment | It is right-aligned |
| value-row-view-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

