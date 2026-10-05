
- **Null / empty input**: An empty scope list is valid and is the default; an empty access or refresh token is accepted without validation, since the type checks nothing about token content.
- **Boundary values**: An expiry of zero converts to zero seconds; a negative expiry converts to a negative number of seconds without clamping. Expiries are floating-point, so a fractional millisecond value divides exactly as given.
- **Concurrent access**: It is a plain value; copies are independent and safe to share across threads.
- **Error states**: Construction cannot fail. Decoding fails when a non-optional field (access token, refresh token or scopes) is missing or mistyped, with the decoder's own error; only the expiries, subscription type and rate-limit tier may be absent from the encoded form.
- **Offline / disconnected state**: Not applicable: The credential type has no network access.
- **Cancellation**: Not applicable: The credential type has no concern of this kind beyond what Behavioral Requirements state.

