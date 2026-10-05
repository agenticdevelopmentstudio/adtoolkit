
This adaptor is not itself a rendered surface, but every rejection and validation message it produces is a hardcoded English literal handed to the extension (and, in several presenter-facing test assertions, to a person debugging the extension), so it is a genuine localization surface, not one this recipe can mark "Not applicable." None of these strings route through any localization mechanism (no `String(localized:)`, no string catalog entry); they are `String(format:)`/interpolation-built English sentences. Representative examples, each traced to source:

| String (representative) | Where |
|---|---|
| `"<memberPath> requires a message argument."` | `show*Message` zero-argument rejection |
| `"<memberPath>'s argument 0 could not be converted to a string."` | `show*Message` message-coercion failure |
| `"<memberPath>'s argument <index> is neither a string nor an object with a string 'title'."` | `show*Message` item-shape rejection |
| `"vscode.window.showQuickPick requires an items argument."` | `showQuickPick` zero-argument rejection |
| `"vscode.window.showQuickPick's argument 0 is neither an array nor a promise of one."` | `showQuickPick` items-shape rejection |
| `"vscode.window.showQuickPick's argument 0 is an array of more than <max> items, or reports a length this host cannot read."` | `showQuickPick` array-length rejection |
| `"vscode.window.showQuickPick's items[<index>] is neither a string nor an object with a string 'label'."` | `showQuickPick` per-item rejection |
| `"vscode.window.showQuickPick's argument 1 is neither an options object nor undefined."` | `showQuickPick` options-shape rejection |
| `"vscode.window.showInputBox's argument 0 is neither an options object nor undefined."` | `showInputBox` options-shape rejection |
| `"...options.valueSelection is neither a two-element array nor undefined/null."` and its four sibling `valueSelection` messages (element count, element types, negative start, end-before-start, end-past-value-length, offset-inside-character) | `showInputBox` `valueSelection` validation |
| `"vscode.window.createStatusBarItem is unavailable: this extension's host has been torn down."` | `createStatusBarItem` raised after teardown |

Any UI surface presenting one of these strings to an end user, rather than to the extension that triggered them, would need its own localization pass; this adaptor itself has none.

