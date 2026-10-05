
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-alerts-001 | confirm-declines-without-window | Ask for a destructive confirmation with no window | The answer is declined and a warning is logged |
| settings-alerts-002 | destructive-button-is-not-default | Build the destructive alert and inspect its buttons | Cancel answers Return; the destructive button has no key equivalent |
| settings-alerts-003 | escape-cancels | Press Escape on the built alert | Cancel is pressed |
| settings-alerts-004 | action-title-defaults-to-delete | Build the alert without an action title | The destructive button reads Delete |
| settings-alerts-005 | injectable-confirm | Ask with an injected closure that answers yes, then no | The awaited result is yes, then no |
| settings-alerts-006 | choose-folder-declines-without-window | Choose a folder with no window | Nothing is reported |
| settings-alerts-007 | folder-panel-allows-one-directory | Build the folder panel | Directories are allowed, files are not, and multiple selection is off |
| settings-alerts-008 | report-trims-message | Report a message padded with spaces and newlines | The text shown or logged has no surrounding whitespace |
| settings-alerts-009 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

