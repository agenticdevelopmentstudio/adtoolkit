
**Decision**: (Swift implementation) a descriptor's id is `"<configuration UUID>/<model>"`, and the split when resolving a configuration uses the FIRST `"/"` only.
**Rationale**: a UUID never contains `"/"`, so the split point is unambiguous, and splitting on the first occurrence rather than the last preserves a model name that itself contains `"/"` — several gateways use such names — stated directly in the source's own documentation.
**Approved**: pending

**Decision**: streaming a response collapses the plugin loader's four distinct failure cases (not found, load failed, no principal class, principal class not a plugin) into one plugin-unavailable error, discarding which specific case occurred.
**Rationale**: the provider's own error type frames its two cases as "what a request can fail on before a plugin is ever reached" — from the extension's point of view, every one of the loader's four failure modes means the same thing: the named plugin cannot serve the request right now. The specific cause is intentionally discarded.
**Approved**: pending

**Decision**: resolving a configuration re-reads the saved provider-configuration list fresh on every streamed-response call rather than resolving once when the descriptor was built.
**Rationale**: per the source's own documentation, "an extension may hold a descriptor for as long as it likes, and what the user has configured now is what a request can actually reach."
**Approved**: pending

**Decision**: every chat context streaming a response builds omits an explicit maximum-tokens value, so every request uses the chat context's own default of `4096` regardless of the resolved descriptor's own maximum input tokens (which can be a real, larger context window reported by the model catalog).
**Rationale**: not stated in the source. The context window recorded on the descriptor is informational — communicated to `vscode.lm` callers as the model's ceiling — but nothing in streaming a response reads it back when building the request, so the request's actual token budget is a fixed default rather than a computation derived from the same catalog lookup building a descriptor performs.
**Approved**: pending

