
- **accepts-any-thrown-value**: the error-message operation MUST accept a thrown value of any type and MUST return a text value; it MUST NOT reject any input by type.
- **error-message-passthrough**: When the thrown value is an error object (including any specialized error subtype), the operation MUST return its message text unchanged.
- **error-name-omitted**: When the thrown value is an error object, the returned string MUST NOT include the error's type name (for example "TypeError: ") or its stack trace; only the message text is returned.
- **non-error-string-conversion**: When the thrown value is not an error object, the operation MUST return the result of the platform's standard text conversion of that value.
- **string-identity**: When the thrown value is a string, the operation MUST return that same string.
- **nullish-conversion**: When the thrown value is one of the two absent-value tokens `null` or `undefined`, the operation MUST return the literal text `"null"` or `"undefined"` respectively, matching which token was thrown.
- **plain-object-conversion**: When the thrown value is a plain object that is not an error object, the operation MUST return that object's own text-conversion result (which is `"[object Object]"` for an object using the platform's default conversion), even if the object carries a `message` field.
- **instanceof-discrimination**: the operation MUST decide between the two branches by a type check on whether the value is an error object, not by checking for the presence of a `message` field; an error value constructed in a different execution context that this check cannot recognize takes the string-conversion branch instead.
- **no-truncation**: the operation MUST NOT trim, truncate, escape or localize the text it returns.
- **purity**: the operation MUST NOT mutate its input, log, throw on its own, or perform any I/O; the only way it can throw is if the standard text conversion of the input itself throws (see Edge Cases).
- **synchronous**: the operation MUST be synchronous and return its result directly; it has no asynchronous path, no cancellation and no timeout.
- **no-prefixing**: the operation MUST NOT add any prefix or context to the returned text; callers compose context such as "Auto-configure failed: " themselves.

