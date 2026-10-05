
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| execution context | JavaScript execution context | (required, no default) | The JavaScript execution context a value is built in, or that a rejection's `Error` is built in via `reject`'s own context. Every caller supplies its own live extension-host context. |
| values | ordered list of JavaScript values | (required, no default) | The ordered JavaScript values that building an array/building an array-or-null value bridge into a new JavaScript array. |
| value (string builder) | string | (required, no default) | The string that building a string-or-null value bridges into a JavaScript string, including the empty string. |
| value (field reader) | optional JavaScript value | (required, no default; an absent operand is valid) | The property reading a string field reads without coercion; an absent operand represents "no operand was supplied at all." |
| reject | JavaScript value | (required, no default) | The JavaScript `reject` callback of a `Promise` that rejecting with an error/rejecting for a torn-down host invokes with a JavaScript `Error`. |
| message | string | (required, no default) | The literal text rejecting with an error writes into the built `Error`'s `message` property. |
| path | string | (required, no default) | The dotted `vscode.*` member path rejecting for a torn-down host embeds verbatim into its fixed teardown wording. |

