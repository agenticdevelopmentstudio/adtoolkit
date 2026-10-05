
**Decision**: One `Row` shape and one adapter serve every pane.
**Rationale**: The header comment: every pane gets "identical row capabilities (clickable commits, consistent links) and a new field is added in one place".
**Approved**: pending

**Decision**: The builders make no judgments; the server's state, verb and tone are rendered verbatim.
**Rationale**: "The server has already decided what is a problem, what happened, and when — these builders only spell the row." A removed client-side `displayStatus` step that demoted aged rows to "last seen building" was unreachable and could only disagree with the server's own expiry (`rowToStatusRowProps` doc comment and the C3 regression tests).
**Approved**: pending

**Decision**: The only client freshness clock judges raw `DeploymentDTO`s, scaled to five times the probe interval with a 10-minute floor, and fails closed.
**Rationale**: The panels that render DTOs directly are "the last place the client still holds a phase the server has not already ruled on"; scaling mirrors `snapshotStaleMs` so a slower poller does not false-demote, and an unreadable date must not assert live progress.
**Approved**: pending

**Decision**: A commit sha is shown only when it links to GitHub.
**Rationale**: "a bare, non-clickable hash is noise"; the subject still shows on its own.
**Approved**: pending

**Decision**: Activity rows take their platform from `ActivityRow.source`, falling back to `kind`.
**Rationale**: The server stamps the raw provider spelling (`cloudflare-pages`, not the canonical `cloudflare` in the target), so no parsing is needed, and the fallback keeps the clipboard and source columns non-empty.
**Approved**: pending

**Decision**: Clipboard text is one tab-separated line per row with a fixed seven columns and friendly labels.
**Rationale**: Copied panes paste as aligned spreadsheet columns and "copied text matches the screen"; the unescaped-field gap is the open question on text-field-escaping.
**Approved**: pending

**Decision**: `problemToRow` sets `downSince` to `since` for every problem.
**Rationale**: The source does this unconditionally; `row-detail.ts` reads `downSince ?? at`, and both hold the same value on problem rows, so the display is unaffected even though the field's doc comment describes it as endpoint-specific.
**Approved**: pending

**Decision**: Row text serialization does not escape or strip tab and newline characters inside fields; the same-column-count promise holds only when the server supplies tab-free values.
**Rationale**: It stands today because the server-supplied fields are not expected to contain control characters. Closing it needs an owner decision on whether fields are sanitized, quoted (tab/comma-separated-value style) or guaranteed tab-free by the server, plus a test for a field containing a tab.
**Approved**: pending

