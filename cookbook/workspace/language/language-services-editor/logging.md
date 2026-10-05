
Four of the twelve components log through the shared logging protocol, each using a subsystem that is the host app's bundle identifier and a category that is the component's own name:

- The completion delegate logs, at error level, a discarded `additionalTextEdits` conflict.
- The semantic-highlight provider logs, at error level, a ragged (non-multiple-of-five) token response and a dropped-overlap token.
- The reloader logs, at notice level, a dirty-buffer conflict between a local edit and a disk change.
- The document coordinator logs, at error level, the count and identifiers of documents termination could not flush.

The hover controller and the jump-to-definition delegate conform to that logging protocol nowhere in either file; see the `lsp-request-failure-unsignaled` requirement for what this leaves unsignaled.

