
- **Null / empty input**: Empty or whitespace-only text yields nothing.
- **Boundary values**: Exactly three letters pass; two or four fail. A non-ASCII letter such as an accented one fails because only `A` to `Z` are accepted after upper-casing; the check runs after upper-casing, so a letter whose upper-case form expands to ASCII letters (such as `ß`, which becomes `SS`) can still yield a three-letter code.
- **Concurrent access**: It is a stateless pure function.
- **Error states**: It never fails; invalid text returns nothing.
- **Offline / disconnected state**: Not applicable: The currency code rule has no network access.
- **Cancellation**: Not applicable: The currency code rule has no concern of this kind beyond what Behavioral Requirements state.

