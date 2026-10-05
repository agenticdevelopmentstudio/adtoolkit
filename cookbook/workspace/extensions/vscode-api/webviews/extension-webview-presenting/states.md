
Not applicable — this is a webview-panel presenting protocol and its panel handle, not a visual component. The one runtime state machine in scope, `isDisposed`/`onDidDispose`'s one-way transition from live to disposed, is captured under Behavioral Requirements (**panel-disposed-flag**, **panel-dispose-callback**, **panel-dispose-idempotent**) rather than as a visual-state table.

