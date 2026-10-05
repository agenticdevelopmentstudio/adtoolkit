
### Normalize operation

- **normalize-signature**: The normalize operation MUST take one text value and return a text value synchronously.
- **normalize-trim**: The operation MUST trim leading and trailing whitespace from the input before any other processing.
- **normalize-canonical-form**: When the trimmed input parses as an absolute URL, the operation MUST return the parsed protocol, then `//`, then the parsed host (hostname plus any non-default port), then the parsed pathname, joined in that order.
- **normalize-lowercase**: When the input parses, the returned scheme and host MUST be lower-case (for example `HTTPS://B.Example.COM` becomes `https://b.example.com`).
- **normalize-default-port**: When the input parses, a port equal to the scheme's default (443 for `https`, 80 for `http`) MUST be dropped from the result.
- **normalize-keep-port**: When the input parses, a non-default port MUST be kept, because it names a different monitor (`http://localhost:3000/` becomes `http://localhost:3000`).
- **normalize-drop-query-fragment**: When the input parses, the query string and fragment MUST NOT appear in the result.
- **normalize-drop-userinfo**: When the input parses, any username or password in the URL MUST NOT appear in the result, because only the host (not the userinfo) is copied into the output.
- **normalize-keep-path**: When the input parses, a non-root path MUST be kept (`https://b.example.com/status/` becomes `https://b.example.com/status`).
- **normalize-strip-trailing-slashes**: The result MUST have every trailing `/` character removed, whether one or many (`https://b.example.com///` becomes `https://b.example.com`).
- **normalize-total**: The operation MUST NOT throw for any string input. When the trimmed input does not parse as an absolute URL, it MUST return the trimmed input with trailing slashes removed and no other change (no lower-casing). The doc comment states why: the editor normalizes on every keystroke, "long before what is typed is a URL at all".
- **normalize-idempotent**: Applying the operation to its own output for an http(s) input MUST return the same string, since the canonical form has no trailing slash, default port, query or fragment left to fold.

### Validity-check operation

- **valid-signature**: The validity-check operation MUST take one text value and return a true-or-false result synchronously.
- **valid-trim**: The operation MUST trim leading and trailing whitespace before parsing, so `  https://b.example.com/ ` is valid.
- **valid-http-https**: The operation MUST return `true` when the trimmed input parses as an absolute URL whose protocol is exactly `http:` or `https:`.
- **valid-other-scheme**: The operation MUST return `false` for any other parsed scheme, including `ftp:`, `javascript:` and `file:`.
- **valid-unparseable**: The operation MUST return `false`, not throw, when the trimmed input does not parse as an absolute URL, including a bare host, a relative path and the empty string.
- **valid-no-normalize-required**: The operation MUST accept a valid URL that is not yet in canonical form (a trailing slash, upper-case host or default port does not make it invalid).

### Contract-wide

- **pure-functions**: Both operations MUST be free of side effects: no network, storage, logging, or global state, and the result depends only on the argument.
- **no-self-or-duplicate-check**: The module MUST NOT offer same-URL comparison, self-peer detection, duplicate-error detection or a duplicate-message constant. The backend maintains equivalent same-URL, self-peer and duplicate-detection helpers of its own; the web mirror copies only the normalize and validate rules, so those conflicts reach the board as backend responses.
- **backend-parity**: The two operations MUST return the same result as the backend's equivalent rules for every input. The module's doc comment requires the two implementations to be kept in step, and the module's own test suite asserts the backend's cases.
- **backend-authority**: The board MUST NOT treat a `true` result from the validity-check operation as acceptance. The backend validates and normalizes every write again, and its answer is the one that counts.
- **concurrency**: Both operations are synchronous, so calls cannot interleave and need no ordering rule.

