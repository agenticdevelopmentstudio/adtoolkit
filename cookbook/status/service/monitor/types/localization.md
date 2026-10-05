
Not applicable: this module contains no string literal used as user-facing text — every text-carrying field (`error`, `errorText`, `detail`, `commitMessage`, `branch`) is a text-type field declaration, not a value, so there is no prose for this module itself to localize. The closed literal sets (health status, deploy status, check state, and the rest) are wire-protocol tokens, not display strings — presenting one to a user is a consumer's rendering concern, outside this module.

