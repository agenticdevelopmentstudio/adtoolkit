
- **Data collected**: none. The matcher reads only the `activationEvents`,
  `engines.vscode`, and `contributes.commands` fields of a caller-supplied
  extension manifest, and the relative paths of a caller-supplied
  workspace scan; none of this is device- or user-identifying data, and the
  component collects nothing beyond what its caller already handed it.
- **Storage**: none. Every value is held only in the in-memory matcher or
  workspace-scan instance for the duration the caller keeps it; nothing is
  written to disk by this component.
- **Transmission**: none. This component performs no networking.
- **Retention**: for the lifetime of the matcher or workspace-scan value
  the caller holds; releasing the value releases the data with it.

