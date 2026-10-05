
| Parameter | Type | Source | Effect |
|-----------|------|--------|--------|
| `viewType` | `String` | Caller (the resolving bridge, from the JavaScript `createWebviewPanel` call) | Identifies the contributed view type the panel is built for; passed through unvalidated by this seam. |
| `title` | `String` | Caller | The panel's initial displayed title. |
| `options` | `WebviewPanelOptions` | Caller | Carries `enableScripts`, `enableForms`, and `declaredLocalResourceRoots`; see the related `WebviewPanelOptions` recipe. |
| `localResourceRoots` | `[URL]` | Caller, already resolved | The absolute set of directories the built panel's webview may load local resources from. |
| `preserveFocus` | `Bool` | Caller | Honored by `reveal(preserveFocus:)` as part of the same presenting call that creates the panel. |
| `extensionIdentifier` | `String` | Caller | Identifies the requesting extension; carried on the request for attribution by callers, but not read or acted on by this component itself. |
| `place` | placement step (function) | App, supplied to the production presenting implementation | Decides where (or whether) the built panel goes in the pane tree; this step lives in the app's production presenting implementation, not in the role this recipe describes. |

