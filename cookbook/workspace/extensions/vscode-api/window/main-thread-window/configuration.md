
| Parameter | Type | Required | Description |
|---|---|---|---|
| `messagePresenter` | `ExtensionMessagePresenting` | Yes, no default | Presents `showInformationMessage`/`showWarningMessage`/`showErrorMessage` calls. |
| `quickPickPresenter` | `ExtensionQuickPickPresenting` | Yes, no default | Presents `showQuickPick` calls. |
| `inputBoxPresenter` | `ExtensionInputBoxPresenting` | Yes, no default | Presents `showInputBox` calls. |
| `statusBarPresenter` | `ExtensionStatusBarPresenting` | Yes, no default | Presents `createStatusBarItem` items and their live mutations. |
| `notImplementedLedger` | `NotImplementedLedger` | Yes, no default | Receives one record per unsupported `tooltip`/`command` shape set on a status bar item. |
| `extensionIdentifier` | `String` | Yes, no default | Attributed on every ledger record this instance makes. |

