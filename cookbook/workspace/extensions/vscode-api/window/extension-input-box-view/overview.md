
This component presents one `vscode.window.showInputBox` request: an
optional title, an optional prompt, a single text (or secure) field, and a
validation message below it. It reads its content from an
`ExtensionInputBoxModel`/`ExtensionInputBoxRequest`, revalidates on every
edit (and once for a pre-filled value), and reports the user's decision
through the `onAccept`, `onCancel`, and `onValueChanged` callbacks its owner
assigns.

