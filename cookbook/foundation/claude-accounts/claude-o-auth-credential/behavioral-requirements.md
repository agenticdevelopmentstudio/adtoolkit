
- **credential-fields**: The credential MUST carry an access token, a refresh token, an optional access-token expiry, an optional refresh-token expiry, a list of scopes, an optional subscription type and an optional rate-limit tier.
- **required-tokens**: The access token and the refresh token MUST be required at construction; every other field MUST be optional with defaults of no expiry, an empty scope list and no subscription or tier.
- **expiry-unit-milliseconds**: The two expiry fields MUST be Unix epoch milliseconds, exactly as Claude Code writes them, and MUST NOT be converted when stored.
- **expiry-seconds-derived**: The credential MUST offer the access expiry and the refresh expiry in epoch seconds, each being the stored milliseconds divided by 1000, and nothing when the stored expiry is absent.
- **value-equality**: Two credentials MUST be equal exactly when all seven fields are equal, so a stored credential can be compared to the live one.
- **codable-wire-form**: The credential MUST encode and decode with field names equal to its property names, because it crosses process boundaries and is read back from the stored item.
- **single-definition**: There MUST be one definition of this credential shape shared by the custody layer and the evaluating layer; neither may declare its own copy.

