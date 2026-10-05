
Not applicable in the sense of a registered URL scheme or platform deep-link
mechanism: inbound OAuth round-trip state instead travels as ordinary URL
fragment and query parameters — parsing an inbound SSO fragment reads
`#code`/`#error` from the current URL's fragment, and reading relayed
central-login parameters reads `clientId`/`return` from the current URL's
query — handled by this recipe's own logic, not resolved through any
deep-link registration.

