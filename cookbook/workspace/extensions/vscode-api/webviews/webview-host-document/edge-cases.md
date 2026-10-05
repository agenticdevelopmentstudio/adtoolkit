
- **Initial state is absent**: `getState()` MUST return `undefined`, not
  `null` (MUST; webview-host-document-011).
- **Extension markup is the empty string**: building the host document
  MUST still return a document — the bootstrap `<script>` element alone,
  with nothing appended after it, since there is no head to insert into and
  nothing to prepend before (MUST; webview-host-document-005).
- **Initial state is present but the empty string**: The generated
  bootstrap embeds `JSON.parse("")`, which is not valid JavaScript and
  throws a `SyntaxError` at page-load time inside the immediately-invoked
  function expression, silently losing `window.acquireVsCodeApi` for that
  load; see **initial-state-json-validity**.
- **A `<head` match sits at the very end of the extension's markup, or its
  whitespace-terminated scan never finds an unquoted `>`**: the
  head-location search MUST answer no match and building the host document
  MUST fall back to prepending (MUST; **unterminated-head-tag-bailout**).
- **A `<head ...>` tag carries a quoted attribute value containing `>`**:
  the head-location search MUST answer no match on encountering the opening
  quote, rather than risk splitting the tag mid-attribute (MUST;
  **quoted-attribute-ambiguity-bailout**; webview-host-document-014).
- **Extension markup contains `<header>` or `<heading>` before any real
  `<head>`**: those matches MUST be rejected and the search MUST continue,
  so the real `<head>` — if one follows — is still found (MUST;
  **head-vs-header-disambiguation**; webview-host-document-015).
- **Initial state carries a script- or comment-breakout payload
  (`</script>`, `<!--`, `-->`, mixed-case `</SCRIPT >`)**: these sequences MUST NOT appear literally in the rendered document (MUST;
  webview-host-document-009, webview-host-document-010).
- **Concurrent access**: building the host document reads no shared mutable
  state and allocates every local value fresh per call; concurrent,
  independent calls from multiple execution contexts MUST NOT require
  external synchronization (derived from **pure-synchronous-string-transform**;
  no shared state exists in this component to race over).
- **Error states**: building the host document itself never throws — no
  error path exists anywhere in this component. The one failure mode
  reachable through this component is at the JavaScript layer, when a
  present initial state is not valid JSON text (see
  **initial-state-json-validity**); a head-location-search bailout is not
  an error state, it is a defined, silent fallback to prepending, by design
  (see Design Decisions).
- **Offline/disconnected state**: Not applicable — this component performs
  no network access of any kind; it is pure, synchronous string assembly,
  so connectivity plays no role in what building the host document returns.

