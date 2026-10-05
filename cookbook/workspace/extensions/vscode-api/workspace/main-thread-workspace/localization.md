
This bridge rejects and raises with hardcoded English string literals; none carries a localization key or any platform localization mechanism's entry. Every rejected message reaches the extension as a rejected JavaScript promise, so an extension author sees the literal English text regardless of locale.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `vscode.workspace.fs.readFile requires a file-scheme vscode.Uri argument.` | Rejected when `readFile`'s first argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only) | `vscode.workspace.fs.writeFile requires a file-scheme vscode.Uri argument.` | Rejected when `writeFile`'s first argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only) | `vscode.workspace.fs.writeFile requires a Uint8Array of contents.` | Rejected when `writeFile`'s second argument is missing or undecodable. |
| (none — literal only) | `vscode.workspace.fs.readDirectory requires a file-scheme vscode.Uri argument.` | Rejected when `readDirectory`'s first argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only) | `vscode.workspace.fs.stat requires a file-scheme vscode.Uri argument.` | Rejected when `stat`'s first argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only) | `vscode.workspace.fs.delete requires a file-scheme vscode.Uri argument.` | Rejected when `delete`'s first argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only) | `vscode.workspace.fs.rename requires two file-scheme vscode.Uri arguments.` | Rejected when `rename`'s first or second argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only) | `vscode.workspace.fs.createDirectory requires a file-scheme vscode.Uri argument.` | Rejected when `createDirectory`'s first argument is missing or not a `file:`-scheme `vscode.Uri`. |
| (none — literal only, from the filesystem service's own error description) | varies by case | Passed through verbatim as the rejected error's `message` whenever the filesystem service throws a `FileSystemServiceError`. |

