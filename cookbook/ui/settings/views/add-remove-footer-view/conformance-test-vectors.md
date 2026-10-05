
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| add-remove-footer-view-001 | remove-starts-disabled | Create a footer | Remove is disabled and add is enabled |
| add-remove-footer-view-002 | add-reports-through-callback | Set the add callback and press add | The callback fires once |
| add-remove-footer-view-003 | remove-reports-through-callback | Enable remove, set the callback and press remove | The callback fires once |
| add-remove-footer-view-004 | remove-enablement-is-settable | Set the enablement flag on, then off | Remove follows the flag |
| add-remove-footer-view-005 | accessory-insertion-order | Add accessories A then B | Order is add, remove, A, B, then the trailing view |
| add-remove-footer-view-006 | identifiers-from-prefix | Create with prefix items | The buttons carry items.add and items.remove |
| add-remove-footer-view-007 | buttons-are-described | Read the buttons' accessibility descriptions | Add and Remove |
| add-remove-footer-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

