
Not applicable — this is the extension host's `vscode.window` webview adaptor, not a visual component. Its only lifecycle-shaped behavior is each panel's adopted-versus-forgotten and disposed-versus-live status, captured under Behavioral Requirements (`panel-record-is-the-sole-strong-reference`, `disposal-fires-before-forgetting`, `dispose-is-idempotent`) rather than as a visual-state table.

