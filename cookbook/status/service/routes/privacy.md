
- **Credential storage**: `auth.ts` stores only a password hash
  (`hashPassword`/`verifyPassword`), never a plaintext password; `device.ts`
  stores only `sha256Hex` digests of `device_code` and `user_code`, never
  the plaintext codes, and the raw device-flow token is returned to the
  polling client exactly once, on the single `consumeApproved` call, with
  `Cache-Control: no-store` on that response; `tokens.ts` returns a minted
  API token's raw value exactly once, on creation, also with `no-store`, and
  never again from `GET /tokens`.
- **Timing-attack mitigation as a privacy control**: `auth.ts`'s login path
  runs `verifyPassword` against `DUMMY_PASSWORD_HASH` for an unknown email so
  that response timing does not disclose which emails are registered.
- **Peer credential redaction**: `config.ts`'s `redactPeer` strips a peer's
  raw token from every response (`hasToken` boolean substituted); a peer
  token is write-only through this API.
- **Deliberate exclusion of internal identifiers from a public surface**:
  `reads.ts`'s `buildSnapshot` — the DTO backing `/status/snapshot`, which
  is reachable by anonymous or peer callers — filters out any Problem whose
  `target` is an error target, because that Problem's `name`/`detail` would
  otherwise carry internal GlitchTip project identifiers and raw exception
  titles. This filter is explicitly documented in source as a decision made
  deliberately for disclosure reasons, not an incidental gap, and as
  reversible if the product decision changes.
- **Rate limiting as an abuse/enumeration control**: `auth.ts`'s and
  `device.ts`'s rate limits on `/auth/login`, `/auth/signup`, and the device
  endpoints double as a control against credential-stuffing and account
  enumeration, not only load protection.
- **Scope of what peers can see**: `telemetry.ts` is explicitly excluded from
  the `PEER_TOKEN` credential — a federated peer instance can read this
  instance's health snapshot but not its error/analytics telemetry, keeping
  that data scoped to authenticated dashboard users.

