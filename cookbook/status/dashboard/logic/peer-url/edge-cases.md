
- **Empty or whitespace-only input**: The normalize operation MUST return `""`, and the validity-check operation MUST return `false`. The peer editor treats an empty normalized value as "not yet typed" and shows no invalid message.
- **Half-typed input** (`https:/`, `b.exa`): The normalize operation MUST fall back to trim and strip without throwing, and the validity-check operation MUST return `false` until the text parses as an absolute http(s) URL.
- **Valid but un-canonical input**: The validity-check operation MUST judge the typed string, not the normalized one. The peer editor validates the typed draft value as typed, and validation trims internally.
- **Non-http scheme that parses** (`javascript:alert(1)`, `mailto:a@b`): The normalize operation MUST still return a string built from the parsed parts. For an opaque URL with no host this puts `//` after the scheme (`javascript:alert(1)` becomes `javascript://alert(1)`). The validity-check operation rejects these inputs, so the result is never stored.
- **Credentials in the URL**: The normalize operation MUST drop the userinfo (normalize-drop-userinfo). A peer URL that needs embedded credentials cannot round-trip through the canonical form.
- **Only trailing slashes** (`"///"`): the input does not parse, so the fallback MUST return `""`.
- **Divergence from the backend**: if one copy of the rules changes without the other, the board's dirty check and inline message disagree with the server. The server's answer MUST win (backend-authority). The only guard against drift is the shared test cases.
- **Concurrent access**: not applicable. Both operations are synchronous and pure, with no possibility of interleaving.
- **Error states and offline**: not applicable. The module does no I/O, so no dependency can fail and connectivity does not matter.

