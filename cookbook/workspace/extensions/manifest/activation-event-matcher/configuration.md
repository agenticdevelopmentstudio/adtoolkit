
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| manifest | extension manifest | none (required) | Supplies `activationEvents`, `engines.vscode`, and `contributes.commands` to the matcher's construction; there is no default manifest. |
| trigger | activation trigger | none (required) | The event the matcher is asked to check; one of: startup finished, document opened (with a language id), command invoked (with a command id), webview panel restored (with a view type), view shown (with a view id), workspace scanned (with a scan). |
| relativePaths | list of strings | none (required, when building a workspace scan) | Workspace-relative paths, `/`-separated with no leading slash, that a caller's directory walk produced; supplied once per scan when building a workspace scan, or via the single-matcher convenience factory. |

There are no environment variables, settings keys, or injected dependencies:
the activation event matcher and its supporting concepts take every input
as a plain argument and read no ambient state.

