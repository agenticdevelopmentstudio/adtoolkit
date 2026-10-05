
Not applicable — this is the extension host's `vscode.workspace` bridge, not a visual component. Its only lifecycle-shaped behavior is the constructed-versus-disposed status of the bridge itself, captured under Behavioral Requirements (`dispose-marks-torn-down-and-nothing-else`, `operation-checks-teardown-before-running`, `operation-checks-teardown-after-running`) rather than as a visual-state table.

