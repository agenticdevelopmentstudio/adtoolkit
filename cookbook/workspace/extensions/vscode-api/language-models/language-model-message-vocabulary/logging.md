
Logged through the shared extension-host logger, under this component's own category, at the levels below.

| Event | Level | Message |
|-------|-------|---------|
| Evaluating the vocabulary's source returns nothing or a non-object | error | `Could not install the 'vscode' language-model message vocabulary in context '<name>'; every member stays the shim's not-implemented stub` |
| The resolved container is missing one of the eight expected members | error | `The 'vscode' language-model message vocabulary in context '<name>' is missing '<memberName>'; every member stays the shim's not-implemented stub` |

No other event in this file is logged: the failed cache-write `Object.defineProperty` inside `languageModelVocabularySource` is caught and silently ignored (per **cache-write-optional**), and no constructor in this file throws or logs on any input, since none of the eight members validates its arguments.

