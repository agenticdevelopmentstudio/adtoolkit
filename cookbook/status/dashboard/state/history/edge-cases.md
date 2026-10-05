
- **null-slug**: With `slug` none, History MUST stay idle and return no data; the slug is never dereferenced because the query is disabled.
- **empty-slug**: The empty string is falsy, so History with an empty-string slug MUST behave exactly like History with no slug and MUST NOT fetch.
- **special-characters-in-slug**: A slug containing spaces, `&`, `/`, `?`, or `=` MUST be percent-encoded so it cannot inject extra query parameters.
- **unknown-slug**: A slug the backend does not recognize is sent as-is; whether the backend answers with an empty `checks` array or an error status is owned by the backend `/history` route, and History MUST surface whichever it returns (data, or `history <status>`).
- **empty-checks**: A successful response with `checks: []` MUST resolve as data; History applies no emptiness check.
- **malformed-body**: A body that is valid JSON but not shaped like `HistoryResponse` (for example missing `checks`) MUST resolve as data unchanged; History performs no shape validation, and a consumer reading `data.checks` receives nothing.
- **204-response**: A response with no body is still ok, so History MUST attempt to parse the empty body, which fails and puts the query in its error state (unlike the client's JSON-body helper, which maps a no-content response to an empty result).
- **server-error**: A non-2xx status MUST produce an error whose message is `history <status>`; retries after that follow the shared cache's policy (the library default is 3 retries with exponential backoff when the host sets none).
- **unreachable-server**: A failed request MUST surface as the query error with no extra retry, fallback data, or message rewriting from History.
- **hung-request**: With no timeout or cancellation signal from History, a request that never settles MUST leave the query in its fetching state indefinitely.
- **slug-change-mid-flight**: When `slug` changes while a request is in flight, the new slug MUST get its own cache entry and request; the earlier request resolves into its own key and does not overwrite the new slug's data.
- **concurrent-callers**: Two consumers using History with the same slug MUST share one cache entry; the shared cache deduplicates the in-flight request.

