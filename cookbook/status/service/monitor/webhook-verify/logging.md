
Not applicable: this file contains no log call of any kind, `console.error` or otherwise. A failed verification is communicated only through the `boolean` `false` return value; the caller (`hooks.ts`) decides whether and how to log or respond to that outcome (it throws an `HTTPException(401, ...)`, which its own error handler shapes into a response, external to this file).

