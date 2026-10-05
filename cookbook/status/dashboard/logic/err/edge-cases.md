
- **Empty message**: An error object with an empty message MUST yield `""`; the operation does not substitute a fallback, so callers that display it alone show an empty error text.
- **Null and undefined**: A thrown `null` or `undefined` MUST yield "null" or "undefined" as literal text, matching which absent-value token was thrown.
- **Object with a message field**: A non-error object such as a JSON error body `{ message: "..." }` MUST yield "[object Object]"; the `message` field is not read.
- **Value from a different execution context**: An error object constructed in a different execution context that the type check does not recognize as an error MUST take the string branch and yield that context's own default text form for an error, which typically includes the type name, unlike the same-context result.
- **Unconvertible value**: An input whose text conversion itself fails MUST cause the operation to throw that conversion error; the operation does not catch it, so the exception propagates out of the caller's error-handling block.
- **Error subclass overriding message**: An error subclass whose message accessor returns a non-string value MUST have that value returned as-is; the operation does not coerce the message.
- **Concurrent access**: Not applicable — the operation is stateless and pure; concurrent calls cannot interfere with each other.
- **Offline or disconnected state**: Not applicable — the operation performs no network access; it only renders errors that network failures produce elsewhere.

