
- **Decision**: Calling back into an extension's callback never falls back to invoking it directly when the trampoline cannot be installed.
  **Rationale**: an uncaught throw from a direct call is exactly what routing every call through the script trampoline exists to keep out of the host's own exception handling; a direct-call fallback would reopen that path for precisely the contexts where the trampoline is least trustworthy.
  **Approved**: pending

- **Decision**: Installing either trampoline helper adopts whatever object already exists under its cached global name rather than verifying its provenance.
  **Rationale**: a script object cannot prove its provenance to the script engine, and freezing the object after installation cannot retroactively make an already-adopted impostor genuine. The blast radius is bounded to the pre-empting extension's own context: reading a dispatch outcome refuses a malformed *returned* record from any caller, and an impostor that throws instead lands in that same extension's own pending-exception state, never another extension's.
  **Approved**: pending

- **Decision**: Reading a value's settlement imposes no timeout on an unsettled thenable.
  **Rationale**: upstream VS Code does not settle either, and answering after some fixed delay would invent user-visible-wrong behavior (an extension told a picker was dismissed that the user never saw). The cost — one leaked continuation and two capturing handlers per un-settling thenable — is confined to the extension whose own thenable never resolves.
  **Approved**: pending

- **Decision**: (Swift/AppKit implementation) The fulfillment/rejection handlers in settlement reading, and the rejection handler in rejection observation, capture no script value, reading their argument from the current call's arguments or minting a fresh "undefined" from the active context at call time instead.
  **Rationale**: a `JSValue` retains its `JSContext`, so a block capturing one and exported to JavaScript creates a retain cycle between the block and the context; the leak would then be the whole context rather than one continuation.
  **Approved**: pending

- **Decision**: "Returned" carrying no value is a distinct, narrow case rather than being folded into "the callback returned undefined."
  **Rationale**: a callback that genuinely returns nothing answers a value holding "undefined," not an absent result; an absent result here means the bridge itself declined to answer. Conflating the two would let a caller resolve an extension's promise with "undefined" — the same answer a successful void command produces — when the true situation was a dispatch failure.
  **Approved**: pending

- **Decision**: (Swift implementation) The confined-value box is one generic type rather than several private, purpose-built box structs.
  **Rationale**: several unrelated shared-library signatures independently require concurrency safety for values (script values and closures over them) this module cannot conform, because the script-value type is owned by the script engine, not by this module. One declaration replaces what would otherwise be several private structs under different names, each a copy of another.
  **Approved**: pending

- **Decision**: (Swift implementation) The bridge, the call-outcome value, the settlement value, and the then-lookup result carry no concurrency-safety declaration beyond the teardown-response value's explicit one.
  **Rationale**: every value in play (the script value, the script context) is inherently confined to one execution context by nature, and every producer and consumer is already confined to the bridge's own execution context; adding a declaration would either be a false promise or require boxing types that have no reason to leave that context.
  **Approved**: pending

