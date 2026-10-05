
- **Data collected**: the derived `x-forwarded-for` client-IP key
  (`rate-limit.ts`), held only for the purpose of counting requests against
  it; the raw `Authorization` header value, passed through `bearer`
  opaquely and never inspected beyond its prefix (`auth.ts`).
- **Storage**: `rate-limit.ts`'s buckets live only in a per-instance,
  in-memory `Map`; nothing here writes to a database or file system.
  `auth.ts` writes nothing to persistent storage — the `tier`/`user`/`token`
  it sets are Hono request-scoped context variables, discarded when the
  request finishes.
- **Transmission**: neither file makes an outbound network call; both act
  only on the inbound request already received by this process.
- **Retention**: a rate-limit bucket is retained for at most one
  `windowMs` past its last hit (swept on schedule or on the `MAX_BUCKETS`
  hard cap), and unconditionally for at most the current process's
  lifetime — a restart discards every bucket (see Edge Cases). `auth.ts`
  retains nothing past the request it ran on.

