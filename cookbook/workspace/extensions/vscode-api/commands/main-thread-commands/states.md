
Not applicable — this is the extension host's `vscode.commands` adaptor, not a visual component. Its only lifecycle-shaped behavior is the registered-versus-disposed status of each command id it owns, which is captured under Behavioral Requirements (`disposable-is-idempotent`, `dispose-unregisters-every-owned-command`) rather than as a visual-state table.

