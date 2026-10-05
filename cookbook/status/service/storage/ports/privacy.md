
- **Sensitive fields**: `UserRecord.passwordHash` (never read back to clients), `PeerRow.token` (redacted by `redactPeer` helper; MUST NOT leave the process), `ApiTokenMeta` (never includes hash or raw value), the `raw` value returned by `mintApiToken` (shown to caller exactly once), and `DeviceGrantRow` (omits `deviceCodeHash`, `userCodeHash`, `tokenRaw`).
- **Token storage**: Session tokens and API tokens are persisted as SHA256 hashes only. The one exception is a device grant: `approve` stashes the minted token's raw value (`tokenRaw`) on the grant row until `consumeApproved` deletes it.
- **Credential redaction**: The `redactPeer` helper projects `PeerRow` to omit `token` and add `hasToken: boolean`; per its doc comment, whether a token is set is all any read surface (REST GET/POST/PATCH, MCP `list_peers`/`add_peer`) may know.

