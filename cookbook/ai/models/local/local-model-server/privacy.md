
Not applicable: the model server helper carries no user data, token, or
credential. It transmits nothing itself — it only derives a URL string from
a caller-supplied base URL and parses model-name/size pairs out of data the
caller already fetched — and it persists nothing to disk; every function
returns its result to the caller with no side channel.

