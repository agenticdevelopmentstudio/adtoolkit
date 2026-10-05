
- **Null / empty input**: Empty or whitespace-only text yields no readings; an empty day text yields no instant.
- **Boundary values**: The nearest-instant search spans three calendar days, so a time past midnight resolves into the next day; a clock that cannot be built on a candidate day is skipped, and a time typed inside a daylight-saving gap resolves however the platform calendar builds it.
- **Concurrent access**: The formatter map is guarded by one lock; formatters themselves are safe to use once configured.
- **Error states**: No function throws; unparseable input yields no readings or no instant.
- **Offline / disconnected state**: Not applicable: The text helper has no network access.
- **Cancellation**: Not applicable: The text helper has no concern of this kind beyond what Behavioral Requirements state.

