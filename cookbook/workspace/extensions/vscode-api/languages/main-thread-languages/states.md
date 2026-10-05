
Not applicable — this is a script-engine bridge for the `vscode.languages` namespace and its backing configuration store, not a visual component. Its only lifecycle-shaped behavior is registration and disposal of individual configurations, captured under Behavioral Requirements (**set-language-configuration-returns-scoped-disposable**, **dispose-removes-only-owned-handles**) rather than as a visual-state table.

