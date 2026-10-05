
- **Empty query string**: Passing `""` MUST pass `""` to the media-query facility unchanged; the returned value is whatever match result the environment reports for it (an empty media query is commonly treated as matching everything).
- **Malformed query**: A syntactically invalid query MUST be passed through unchanged; the environment commonly reports it as never matching, so Media Query returns `false` and no change notification is expected to fire.
- **Missing media-query facility**: In an environment without it, evaluation MUST fail with an error; callers or tests are responsible for supplying a stand-in.
- **Query changes every evaluation**: A caller that builds a new query string with different content each time MUST cause a teardown and resubscribe each time; a caller passing an identical string MUST NOT.
- **Stops being used before its subscription is established**: If the caller stops using it before that point, no subscription is created and no cleanup runs.
- **Change notification after the caller stops using it**: Because cleanup removes the listener, no update MUST occur from a notification that fires afterward.
- **Rapid consecutive change notifications**: Each notification MUST set the returned value to that notification's match result; the final value is the last delivered notification's value.
- **Concurrent uses**: Multiple callers evaluating the same query each MUST get an independent subscription and value; there is no shared cache.
- **Cancellation, timeout, network**: Not applicable — Media Query makes no asynchronous request and has nothing to cancel or time out beyond listener removal.

