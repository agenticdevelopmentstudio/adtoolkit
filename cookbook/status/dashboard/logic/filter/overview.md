
This module exports one pure operation, the query-match operation, taking a haystack and a query. Its doc comment states the contract: "Case-insensitive, token-AND substring match. Every whitespace-separated token in the query must appear somewhere in the haystack. An empty query matches all."

Its one call site is the activity panel. The panel keeps a row when it passes the source filter ([Source Filter](adtoolkit://cookbook/status/dashboard/state/source-filter)) AND the query-match operation on the row's search text and the current query is true. The current query is the raw text of the panel's search box. The row's search text joins the row's name, environment, status word, detail and commit body with single spaces. The module holds no state and does no I/O.

