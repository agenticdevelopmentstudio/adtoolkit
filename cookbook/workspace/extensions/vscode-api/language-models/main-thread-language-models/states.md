
Not applicable — this is a script-context bridge for the `vscode.lm` namespace, not a visual component. Its only lifecycle-shaped behavior is disposal and per-request completion, captured under Behavioral Requirements (**dispose-marks-disposed-first** through **dispose-retains-live-requests**, **check-completion-both-cursors**) rather than as a visual-state table.

