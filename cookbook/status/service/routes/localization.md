
None of these routes look up a translation table; every user-facing message
is a hardcoded English string baked into the `HTTPException`/response body,
for example: `'Invalid JSON'`, `'Invalid role'`, `'Cannot demote the last
admin'`, `'Cannot delete the last admin'`, `'An account with this email
already exists'` (auth.ts), `'user_code is required'` (device.ts),
`DUPLICATE_PEER_MESSAGE` (config.ts), `'Admin required'` / `'token not
found'` (tokens.ts), and `badge.ts`'s shields-style label vocabulary
(`'status'` plus the remapped overall value). This is a fact about the
current source, not a gap: these are internal/operator- and integrator-
facing strings (webhook responses, admin API errors, a CI badge), not
end-user application copy, and none of the 17 files reads a locale or
translation resource.

