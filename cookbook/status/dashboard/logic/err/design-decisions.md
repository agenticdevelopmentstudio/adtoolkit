
**Decision**: Return only `Error.message`, not `name` or `stack`.
**Rationale**: The doc comment says "Error → message"; callers already supply context ("Match failed — "), so the error class name would be noise in a display string.
**Approved**: pending

**Decision**: Use `String(e)` for every non-Error value instead of inspecting objects for a `message` field.
**Rationale**: The doc comment specifies "else String"; this keeps the function total and trivially predictable, at the cost of rendering error-shaped plain objects as "[object Object]" (see plain-object-conversion).
**Approved**: pending

**Decision**: Keep the helper in `src/lib` as a shared module rather than inlining the expression in each component.
**Rationale**: Four components need the same narrowing of `unknown` catch values; one shared function keeps the rendering rule identical across them.
**Approved**: pending

