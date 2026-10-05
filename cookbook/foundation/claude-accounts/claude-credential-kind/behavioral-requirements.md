
- **two-kinds**: The kind set MUST contain exactly two cases: an OAuth login, whose raw value is `oauth`, and a long-lived token, whose raw value is `long-lived`.
- **raw-value-stable**: The raw value of each case MUST be the string above; it is the wire and storage form, so it MUST NOT change between releases.
- **title-per-kind**: Each kind MUST provide a display title for a type column, a details pane and a quota card header: `OAuth` for the OAuth login and `Long-lived` for the long-lived token.
- **key-spelling**: The item key for a credential MUST be the kind raw value, a colon, then the account name (for example `oauth:alice@example.com`). This is the only spelling of the key; no other layer may build it by hand.
- **key-from-raw-value**: Building a key from a raw kind string that is absent or empty MUST return the bare account name unchanged (the legacy key form). A raw kind string this build does not recognize but that is non-empty MUST still produce a distinct `<raw>:<account>` key.
- **parse-inverse**: Parsing an item key MUST split it at the first colon and return the kind and the account name when the text before the colon is a known raw value; otherwise (no colon, or an unknown prefix, including a legacy bare account name) it MUST return nothing.
- **account-names-keep-colons-after-first**: Parsing MUST keep everything after the first colon as the account name, so a name that itself contains a colon is returned intact.
- **codable-and-enumerable**: The kind MUST be encodable and decodable by its raw value and MUST expose every case, so a settings table can list the kinds.

