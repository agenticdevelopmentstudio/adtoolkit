
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rawBody` (parameter to `verifyVercelSignature`) | `string` | none — caller-supplied, required | The raw HTTP request body text, exactly as received, per the function's own doc comment. |
| `signature` (parameter to `verifyVercelSignature`) | `string \| null \| undefined` | none — caller-supplied | The `x-vercel-signature` header value. `null`, `undefined`, or `''` fails verification. |
| `secret` (parameter to `verifyVercelSignature`) | `string` | none — caller-supplied, required | The Vercel webhook secret to key the HMAC-SHA1 digest with. `hooks.ts` passes `config.webhooks.vercel`, throwing an `HTTPException(503, ...)` before calling this function when that value is unset. `''` fails verification. |
| `provided` (parameter to `verifySharedSecret`) | `string \| null \| undefined` | none — caller-supplied | The secret value presented by the caller (e.g. Railway's `?token=` query parameter or `x-webhook-secret` header, read by `hooks.ts`). `null`, `undefined`, or `''` fails verification. |
| `secret` (parameter to `verifySharedSecret`) | `string` | none — caller-supplied, required | The configured secret to compare `provided` against. `hooks.ts` passes `config.webhooks.railway`, throwing an `HTTPException(503, ...)` before calling this function when that value is unset. `''` fails verification (fails closed). |

