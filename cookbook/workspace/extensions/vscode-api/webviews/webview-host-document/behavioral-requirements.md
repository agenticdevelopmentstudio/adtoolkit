
- **bootstrap-injection-point**: Building the host document MUST return
  the extension's markup with a `<script>` element containing the bootstrap
  script inserted at the index immediately following the extension's own
  opening `<head>` tag when the head-location search locates one
  unambiguously.
- **bootstrap-prepend-fallback**: When the head-location search finds no
  unambiguous head start, building the host document MUST prepend the
  bootstrap `<script>` element to the start of the extension's markup
  unmodified, rather than inserting it anywhere else in the document.
- **head-tag-match-case-insensitive**: The head-location search MUST search
  for the literal `<head` case-insensitively, so `<HEAD>`, `<Head>`,
  and `<head>` are each recognized as a candidate head start.
- **head-vs-header-disambiguation**: The head-location search MUST treat a
  `<head` match as a genuine head start only when the character immediately
  following it is `>` or whitespace; when it is any other character (as in
  `<header` or `<heading`), the match MUST be rejected and the search MUST
  continue from just past that match.
- **head-tag-closing-detection**: When `<head` is immediately followed by
  `>`, the head-location search MUST return the index immediately after
  that `>`. When `<head` is followed by whitespace, it MUST scan forward for
  the tag's closing `>` and return the index immediately after that
  character.
- **quoted-attribute-ambiguity-bailout**: While scanning forward for a
  `<head ...>` tag's closing `>`, the head-location search MUST answer no
  match immediately on encountering a `"` or `'` character before an
  unquoted `>`, because a quoted attribute value could itself contain `>`
  and the true tag boundary cannot be determined without full HTML parsing.
- **unterminated-head-tag-bailout**: The head-location search MUST answer no
  match when a `<head` match is found but no closing `>` is ever reached —
  either because the match sits at the very end of the string or the
  whitespace-scan loop exhausts the string without finding an unquoted `>`.
- **extension-markup-passthrough**: Every character of the extension's
  markup outside the single insertion point MUST appear unchanged in the
  returned document; building the host document MUST NOT reformat,
  re-encode, or otherwise alter the extension's own markup.
- **initial-state-undefined-vs-value**: An absent initial state MUST render
  as the bare JavaScript token `undefined`; a present initial state MUST
  render as `JSON.parse` applied to a double-quoted, escaped string literal
  wrapping that text, so a caller can distinguish "never called `setState`"
  from "called `setState` with a JSON-encoded value".
- **script-element-escaping**: Escaping a value for script-element embedding
  MUST escape every Unicode scalar of its input for safe embedding inside a
  double-quoted JavaScript string literal that itself lives inside an HTML
  `<script>` element: backslash to `\\`, `"` to `\"`, newline to `\n`,
  carriage return to `\r`, tab to `\t`; `<`, `>`, `&`, U+2028, and U+2029 to
  their `\u` hex escapes; every other scalar below U+0020 to its `\u` hex
  escape; every other scalar passed through unescaped.
- **script-close-tag-neutralized**: Because escaping a value for
  script-element embedding escapes `<` and `>`, no value supplied as the
  initial state can cause the sequence formed by a less-than sign, "script",
  and a greater-than sign to appear literally in the rendered document, so
  persisted state can never terminate the injected `<script>` element early.
- **html-comment-open-neutralized**: Because escaping a value for
  script-element embedding escapes `<`, no value supplied as the initial
  state can cause an HTML comment opener to appear literally in the
  rendered document, so persisted state can never open a comment that would
  swallow the rest of the bootstrap, including the `acquireVsCodeApi`
  definition.
- **message-handler-name-constant**: The message channel name MUST be the
  fixed string `"agenticWebview"`; the bootstrap script MUST address the
  message channel by interpolating this exact constant rather than
  restating it, so the stored value and the generated JavaScript identifier
  cannot diverge.
- **message-kind-closed-set**: The message kind MUST be a closed set of
  exactly two named values, `postMessage` (wire value `"postMessage"`) and
  `setState` (wire value `"setState"`); the bootstrap script MUST send only
  these two kind strings via the send-message primitive.
- **acquire-once-guard**: The rendered `window.acquireVsCodeApi` function
  MUST return a frozen API object on its first call within a page, and MUST
  throw a JavaScript `Error` with the exact message "An instance of the VS
  Code API has already been acquired" on every subsequent call in that same
  page, mirroring the real `acquireVsCodeApi()` contract extensions are
  written against.
- **post-message-relay-is-fire-and-forget**: The returned API's
  `postMessage(message)` MUST call the send-message primitive with kind
  `'postMessage'`, which MUST post an object carrying `kind` and `body` to
  the message channel when that channel exists, and MUST do nothing else —
  no throw, no fallback delivery — when it does not.
- **get-state-returns-in-memory-value**: The returned API's `getState()`
  MUST return the script's in-memory `state` variable exactly as it was last
  set — either the value decoded from the initial state at page-load time or
  the argument of the most recent `setState` call in that page's lifetime.
- **set-state-updates-and-relays**: The returned API's `setState(newState)`
  MUST reassign the in-memory `state` variable to `newState`, MUST call the
  send-message primitive with kind `'setState'` and that value, and MUST
  return `newState`.
- **pure-synchronous-string-transform**: Building the host document MUST be
  a synchronous function of its two arguments only, performing no file,
  network, or process I/O, and MUST NOT raise or throw an error; it MUST
  return the same document text for repeated calls given identical
  arguments.
- **initial-state-json-validity**: A present initial state MUST be embedded as the argument of a JSON parse call after script-element escaping; the document builder does not check that the text is syntactically valid JSON. A present value that is not valid JSON (an empty string, or state corrupted where it was persisted) makes the generated bootstrap throw at page-load time, uncaught inside that bootstrap and never reaching the native host, so the page loads without the webview API and with no signal that this happened (see the pending design decision on initial-state validation).

