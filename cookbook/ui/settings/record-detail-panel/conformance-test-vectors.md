
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| record-detail-panel-001 | title-from-record | A pane created with a record titled `Draft` | The sidebar title is `Draft` |
| record-detail-panel-002 | commit-ignores-no-change | Commit a record equal to the held one | The save callback is not called |
| record-detail-panel-003 | commit-reports-a-real-edit | Commit a record titled `Final` over one titled `Draft` | The save callback receives the `Final` record once; the held record is `Final` |
| record-detail-panel-004 | commit-reports-a-real-edit | The same commit | The sidebar title is `Final` |
| record-detail-panel-005 | adopt-stores-without-saving | Adopt a record titled `Renamed elsewhere` | The save callback is not called; the sidebar title is `Renamed elsewhere` |
| record-detail-panel-006 | focus-name-selects-the-name-field | A pane whose view is not loaded; focus the name | Nothing happens and nothing fails |
| record-detail-panel-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

