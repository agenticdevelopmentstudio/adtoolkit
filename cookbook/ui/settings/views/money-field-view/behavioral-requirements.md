
- **parses-an-amount-in-range**: Text that the formatter parses to an amount inside the allowed range MUST be accepted and written as cents.
- **trims-whitespace**: Surrounding whitespace MUST be ignored when parsing.
- **refuses-unparseable-text**: Text the formatter cannot parse MUST be refused by not writing it.
- **refuses-out-of-range**: An amount outside the allowed range MUST be refused by not writing it.
- **blank-means-fallback-when-allowed**: An empty or whitespace-only field MUST write no amount when blanks are allowed, and MUST be refused otherwise.
- **refused-text-reverts**: After a refusal the row MUST show the stored amount again.
- **shows-the-stored-amount**: The field MUST show the stored amount through the formatter, or be empty when there is none.
- **formatter-is-asked-each-time**: The formatter MUST be asked afresh for every read and parse, so a changed currency re-renders without rebuilding the row.
- **placeholder-shows-the-fallback**: When a placeholder amount is set, an empty field MUST show it formatted as the placeholder; when unset, no placeholder.
- **refresh-spares-editing**: Refreshing MUST re-read the stored amount and the placeholder without disturbing a field being typed in.
- **revert-discards-editing**: Reverting MUST re-read the stored amount and the placeholder, discarding an edit in progress.
- **exposes-explanation**: The row MUST expose the caller's explanation so its group can draw it under the row.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

