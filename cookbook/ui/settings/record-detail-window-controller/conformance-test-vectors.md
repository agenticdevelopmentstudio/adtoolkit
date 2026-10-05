
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| record-detail-window-controller-001 | sidebar-follows-records | Set three records | Three rows in the owner's order |
| record-detail-window-controller-002 | first-selection-is-never-blank | Set records with nothing selected | The first record is selected |
| record-detail-window-controller-003 | pane-built-once-per-record | Push the same record twice with changed values | The pane is built once and updated twice |
| record-detail-window-controller-004 | selection-survives-reload | Select the second record, then set the records again | The second record is still selected |
| record-detail-window-controller-005 | deleted-selection-takes-neighbour | Delete the selected middle record | The record now in its position is selected |
| record-detail-window-controller-006 | empty-list-selects-nothing | Set no records | No record is selected and the empty message is shown |
| record-detail-window-controller-007 | add-reports-out | Activate add | The add callback runs once |
| record-detail-window-controller-008 | remove-vetoable | A can-remove check answering false for the selected record | The remove control is disabled and a remove is refused |
| record-detail-window-controller-009 | selection-reported-once | Select another record | The select callback runs once, and not again on an unchanged reload |
| record-detail-window-controller-010 | remove-disabled-when-nothing-selected | No selection | The remove control is disabled |
| record-detail-window-controller-011 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

