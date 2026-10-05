
**Decision**: The bootstrap is injected immediately after the extension's
opening `<head>` tag — ahead of the extension's own
`<meta http-equiv="Content-Security-Policy">`, if it declares one — rather
than at any later point in the document.
**Rationale**: A meta CSP only governs content the HTML parser reads after
it, so injecting before means the extension's own CSP constrains the
extension's own scripts exactly as intended, without being able to disable
the bridge it is delivered through; it also guarantees `acquireVsCodeApi` is
defined before the extension's own first script runs, which matters because
calling it there is the normal way a restored panel gets its state back
(doc comment).
**Approved**: pending

**Decision**: An ambiguous or unterminated `<head ...>` match makes
`headStartTagEnd(in:)` return `nil` and fall back to prepending, rather than
attempting a best-effort insertion at a guessed boundary.
**Rationale**: Certainty is the whole point — a wrong insertion point would
corrupt markup this function promised only to insert into, whereas
prepending is always correct, merely less tidy (doc comment).
**Approved**: pending

**Decision**: Persisted state is escaped for safe embedding inside a
`<script>` element rather than validated as JSON before being embedded.
**Rationale**: The doc comment on `escapedForScriptElement(_:)` explains the escaping exists to close HTML-parser-level break-outs
(`</script>`, `<!--`) that JSON encoding alone does not close, since the
HTML parser reads a script element's contents before JavaScript ever does.
The function does not additionally verify that the escaped text parses as
JSON — that gap is **initial-state-json-validity**.
**Approved**: pending

**Decision**: The initial state is embedded without checking that it is valid JSON; an invalid value breaks the page bootstrap silently.
**Rationale**: `WebviewHostDocument.html(wrapping:initialState:)` only escapes the text for the script element (`escapedForScriptElement`) and wraps it in a JSON parse call; neither step validates it. Closing it would take either a validity check that falls back to `undefined`, or confirmation from the owner of pane-state persistence that it can only ever produce valid JSON text and never an empty string.
**Approved**: pending

