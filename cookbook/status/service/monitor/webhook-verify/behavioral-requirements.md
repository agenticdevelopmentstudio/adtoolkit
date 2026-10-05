
### Constant-Time String Comparison (`safeEqual`)

- **length-mismatch-short-circuits**: `safeEqual` MUST return `false` without invoking `timingSafeEqual` when the UTF-8 byte length of `a` differs from the UTF-8 byte length of `b`, per its own doc comment ("never throws on length mismatch") and its `if (ab.length !== bb.length) return false;` guard — `node:crypto`'s `timingSafeEqual` otherwise throws a `RangeError` on buffers of unequal length.
- **equal-length-constant-time-compare**: When `a` and `b` encode to equal-length UTF-8 byte buffers, `safeEqual` MUST compare them using `node:crypto`'s `timingSafeEqual` and MUST return exactly the boolean that call produces.
- **utf8-byte-comparison**: `safeEqual` MUST encode both `a` and `b` as UTF-8 (`Buffer.from(a, "utf8")` / `Buffer.from(b, "utf8")`) before comparing, so the comparison is case-sensitive and normalization-sensitive: two strings differing only in letter case MUST be treated as unequal.

### Vercel HMAC-SHA1 Signature Verification (`verifyVercelSignature`)

- **missing-signature-rejected**: `verifyVercelSignature` MUST return `false` without computing any digest when `signature` is `null`, `undefined`, or the empty string (the `!signature` guard).
- **missing-secret-rejected**: `verifyVercelSignature` MUST return `false` without computing any digest when `secret` is the empty string (the `!secret` guard).
- **hmac-sha1-hex-digest**: When both `signature` and `secret` are truthy, `verifyVercelSignature` MUST compute the expected value as the HMAC-SHA1 digest of `rawBody`, keyed by `secret`, hex-encoded (`createHmac("sha1", secret).update(rawBody).digest("hex")`).
- **signature-compared-via-safe-equal**: `verifyVercelSignature` MUST return the result of comparing its computed expected digest against `signature` using `safeEqual`, never a plain `===` comparison.
- **raw-body-precondition**: per the function's own doc comment, the caller MUST supply `rawBody` exactly as received on the wire, never re-serialized; the function itself performs no parsing, decoding, or re-encoding of `rawBody` before hashing it, so a caller that re-serializes the body before this call changes the computed digest and breaks verification. This is a caller precondition the function's contract states directly, not input this function validates itself.

### Shared-Secret Verification (`verifySharedSecret`)

- **missing-provided-rejected**: `verifySharedSecret` MUST return `false` without comparison when `provided` is `null`, `undefined`, or the empty string (the `!provided` guard).
- **missing-configured-secret-fails-closed**: `verifySharedSecret` MUST return `false` when `secret` is the empty string (the `!secret` guard), regardless of the value of `provided` — an unset or misconfigured secret MUST NOT be treated as a match for any input.
- **provided-compared-via-safe-equal**: When both `provided` and `secret` are truthy, `verifySharedSecret` MUST return the result of comparing `provided` against `secret` using `safeEqual`.

### Cross-Cutting Contract

- **pure-synchronous-no-side-effects**: Both `verifyVercelSignature` and `verifySharedSecret` MUST be synchronous, MUST return a plain `boolean` (never a `Promise`), and MUST perform no I/O, no logging, and no mutation of any shared or module-level state.
- **no-throw-contract**: Each exported function MUST NOT throw for any combination of its documented parameter types (`string`, `string | null | undefined`); every failure path returns `false` rather than raising an exception.
- **independent-calls-no-shared-state**: The module declares no module-level mutable state; concurrent or repeated calls to either exported function MUST NOT interact with, block, or influence one another's outcome, since each call reads only its own parameters.

