
Not applicable — this is the extension-host contract (two data types and a presenting protocol) for `vscode.window.showQuickPick`, not a visual component. The only lifecycle-shaped behavior — a `presentQuickPick` call outstanding until it resolves accepted or dismissed — is captured under Behavioral Requirements rather than as a visual-state table.

